# ============================================================================
# Preparación de insumos: "Alianza ganadora" a nivel municipal (México, 2021)
#
# Este script genera los insumos que usan los alumnos para replicar una
# aplicación Shiny de mapas electorales:
#   1. geo/municipios_mexico.geojson  -> polígonos municipales (INE, EPSG:4326)
#   2. geo/estados/XX.geojson         -> un archivo por estado (más ligeros)
#   3. datos/resultados_municipales_2021.csv -> resultados y alianza ganadora
#
# Fuente de datos: elección federal de diputaciones 2021 (base ya procesada
# del proyecto participacion_electoral_codigos_postales) y cartografía
# municipal del INE.
# ============================================================================

library(dplyr)
library(readr)
library(sf)
library(purrr)

# Rutas relativas a la raíz del proyecto original
ruta_proyecto <- "/Volumes/Extreme SSD/SHINYAPPS/participacion_electoral_codigos_postales"
ruta_salida   <- file.path(ruta_proyecto, "insumos_alianza_ganadora")

# ----------------------------------------------------------------------------
# 1. Base de resultados municipales
# ----------------------------------------------------------------------------

bd_mpo <- read_csv(
  file.path(ruta_proyecto, "20231110", "bd_mpo.csv"),
  show_col_types = FALSE
)

# Las variables v_* ya traen los votos agregados por fuerza política:
#   v_vxm = Va por México (PAN + PRI + PRD y sus combinaciones de coalición)
#   v_jhh = Juntos Haremos Historia (Morena + PT + PVEM y sus combinaciones)
#   v_mc  = Movimiento Ciudadano (compitió sin alianza)
# El resto (PES, RSP, FxM, independientes) se agrupa como "Otros".
resultados <- bd_mpo %>%
  mutate(
    v_otros = coalesce(v_pes, 0) + coalesce(v_rsp, 0) +
      coalesce(v_fxm, 0) + coalesce(v_ci, 0)
  ) %>%
  rowwise() %>%
  mutate(
    votos_max = max(c(v_vxm, v_jhh, v_mc, v_otros), na.rm = TRUE),
    # Se detectan empates exactos entre fuerzas punteras
    n_punteros = sum(c(v_vxm, v_jhh, v_mc, v_otros) == votos_max, na.rm = TRUE),
    alianza_ganadora = case_when(
      # Municipios sin votos registrados (casillas no instaladas o
      # votación anulada, ocurre en Chiapas y Oaxaca)
      votos_max == 0       ~ "Sin votación",
      n_punteros > 1       ~ "Empate",
      votos_max == v_vxm   ~ "Va por México",
      votos_max == v_jhh   ~ "Juntos Haremos Historia",
      votos_max == v_mc    ~ "Movimiento Ciudadano",
      TRUE                 ~ "Otros"
    ),
    # Margen de victoria en puntos porcentuales sobre votos totales
    votos_segundo = sort(c(v_vxm, v_jhh, v_mc, v_otros),
                         decreasing = TRUE)[2],
    margen_pp = 100 * (votos_max - votos_segundo) / total_votos
  ) %>%
  ungroup() %>%
  select(
    # Identificadores (la llave para unir con la geografía es cve_edo_mpo_ine)
    cve_edo, nom_edo, acronimo_estado,
    cve_mpo_ine, nom_mpo_ine, cve_edo_mpo_ine,
    latitude, longitude,
    # Contexto sociodemográfico
    pob_tot, grado_prom_esco, metro,
    # Padrón y participación
    lista_nominal = ln_mpo,
    total_votos,
    por_participacion, por_abstencion,
    participacion_h, participacion_m, participacion_j,
    # Votos por partido
    v_pan, v_pri, v_prd, v_pvem, v_pt, v_mc, v_morena,
    v_pes, v_rsp, v_fxm, v_ci,
    # Votos por alianza y resultado
    v_vxm, v_jhh, v_otros,
    alianza_ganadora, votos_alianza_ganadora = votos_max, margen_pp,
    triunfo_original = triunfo
  )

write_csv(
  resultados,
  file.path(ruta_salida, "datos", "resultados_municipales_2021.csv")
)

# Resumen de control
print(table(resultados$alianza_ganadora))

# ----------------------------------------------------------------------------
# 2. Geografía municipal (une los 32 rds del INE y simplifica)
# ----------------------------------------------------------------------------

archivos_rds <- list.files(
  file.path(ruta_proyecto, "geografias", "municipios"),
  pattern = "^[0-9]{2}\\.rds$",
  full.names = TRUE
)

# lapply + bind_rows: se leen los 32 estados y se apilan en un solo sf
mpios <- lapply(archivos_rds, readRDS) %>%
  bind_rows() %>%
  st_as_sf() %>%
  transmute(
    cve_edo = sprintf("%02d", as.integer(ENTIDAD)),
    cve_mpo_ine = sprintf("%03d", as.integer(MUNICIPIO)),
    cve_edo_mpo_ine = paste0(cve_edo, cve_mpo_ine),
    nom_mpo = NOMBRE
  )

# Simplificación (~150 m de tolerancia) para que el geojson nacional
# cargue rápido en leaflet sin perder la forma de los municipios.
# La cartografía del INE trae vértices duplicados que invalidan s2, así que
# se simplifica en una proyección métrica (Lambert de México, EPSG:6372)
# y se regresa a coordenadas geográficas
sf_use_s2(FALSE)
mpios_simple <- mpios %>%
  st_make_valid() %>%
  st_transform(6372) %>%
  st_simplify(dTolerance = 150) %>%
  st_make_valid() %>%
  st_transform(4326)

# Se une la alianza ganadora al polígono para que el geojson sea utilizable
# por sí solo (los alumnos también pueden re-unir desde el CSV)
mpios_simple <- mpios_simple %>%
  left_join(
    resultados %>%
      select(cve_edo_mpo_ine, nom_edo, alianza_ganadora, margen_pp,
             por_participacion),
    by = "cve_edo_mpo_ine"
  )

# Diagnóstico de la unión geografía-resultados
sin_datos <- sum(is.na(mpios_simple$alianza_ganadora))
print(paste("Municipios en cartografía:", nrow(mpios_simple)))
print(paste("Municipios sin resultados tras la unión:", sin_datos))

# Geojson nacional
archivo_nacional <- file.path(ruta_salida, "geo", "municipios_mexico.geojson")
if (file.exists(archivo_nacional)) file.remove(archivo_nacional)
st_write(mpios_simple, archivo_nacional, quiet = TRUE)

# Un geojson por estado (útil para apps que cargan por estado, como la
# aplicación original)
for (edo in sort(unique(mpios_simple$cve_edo))) {
  archivo_edo <- file.path(ruta_salida, "geo", "estados",
                           paste0(edo, ".geojson"))
  if (file.exists(archivo_edo)) file.remove(archivo_edo)
  mpios_simple %>%
    filter(cve_edo == edo) %>%
    st_write(archivo_edo, quiet = TRUE)
}

# Verificación final de tamaños
print(file.info(archivo_nacional)$size / 1e6)
