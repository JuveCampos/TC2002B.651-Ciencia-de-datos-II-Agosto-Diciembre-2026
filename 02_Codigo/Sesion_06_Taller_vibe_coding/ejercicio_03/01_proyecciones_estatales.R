# ============================================================================
# Proyecciones de población estatal, 1970-2070
# Sesión 06 - Taller de vibe coding, ejercicio 03
#
# Se grafica la serie de población de cada entidad federativa y se marca en
# rojo el año en el que alcanza su población máxima. La pregunta detrás de la
# figura es cuándo deja de crecer cada estado: la mayoría de las entidades
# llegan a su tope antes de 2070 y a partir de ahí pierden población.
#
# Insumo:  indicador_estados_1045-3.xlsx  (INEGI, indicador 1045)
#          proyecciones_municipales_conapo.csv  (solo para el catálogo de
#          nombres de entidad, porque el XLSX trae claves y no nombres)
# Salida:  figuras/01_proyecciones_estatales_facetas.png
#
# El proyecto ejercicio_03.Rproj fija el directorio de trabajo en esta
# carpeta, de modo que las rutas relativas siempre resuelven.
# ============================================================================

library(readxl)
library(readr)
library(dplyr)
library(stringr)
library(ggplot2)
library(scales)

ruta_xlsx <- "indicador_estados_1045-3.xlsx"
ruta_csv  <- "proyecciones_municipales_conapo.csv"
stopifnot(file.exists(ruta_xlsx), file.exists(ruta_csv))

dir.create("figuras", showWarnings = FALSE)

# ---------------------------------------------------------------------------
# 1. Serie estatal de población
#
# cve_ent se fuerza a texto: si se lee como número se pierde el cero a la
# izquierda y Aguascalientes ("01") se vuelve indistinguible de un 1 suelto.
# La clave "00" es el total nacional, no una entidad, y se descarta. Ojo con
# el rango: el agregado nacional arranca en 1950, pero las series estatales
# empiezan hasta 1970, así que la figura cubre 1970-2070.
# ---------------------------------------------------------------------------

poblacion_estatal <- read_excel(
    ruta_xlsx,
    col_types = c("numeric", "text", "numeric", "numeric")
  ) %>%
  filter(cve_ent != "00") %>%
  select(cve_ent, year, valor)

# ---------------------------------------------------------------------------
# 2. Catálogo de nombres de entidad
#
# El XLSX no trae nombres. Se arman a partir del CSV municipal, tomando los
# dos primeros dígitos de cve_mun. Se leen solo las dos columnas necesarias
# para no cargar en memoria las 130 mil filas completas, y se declara "NA"
# como valor faltante porque el archivo trae esa cadena literal en las filas
# de agregado nacional y estatal.
# ---------------------------------------------------------------------------

catalogo_entidades <- read_csv(
    ruta_csv,
    col_select = c(cve_mun, nom_ent),
    col_types  = cols(cve_mun = col_character(), nom_ent = col_character()),
    na = "NA"
  ) %>%
  filter(!is.na(nom_ent)) %>%
  mutate(cve_ent = str_sub(cve_mun, 1, 2)) %>%
  distinct(cve_ent, nom_ent)

stopifnot(nrow(catalogo_entidades) == 32)

poblacion_estatal <- poblacion_estatal %>%
  inner_join(catalogo_entidades, by = "cve_ent")

# ---------------------------------------------------------------------------
# 3. Año de población máxima en cada entidad
#
# slice_max con n = 1 devuelve una sola fila por estado. Se ordena por año
# para poder usar ese orden en las facetas más adelante.
# ---------------------------------------------------------------------------

maximos_estatales <- poblacion_estatal %>%
  group_by(nom_ent) %>%
  slice_max(valor, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  arrange(year)

print(maximos_estatales, n = 32)

print(paste(
  "Entidades que alcanzan su máximo antes de 2070:",
  sum(maximos_estatales$year < 2070), "de 32"
))

# ---------------------------------------------------------------------------
# 4. Figura con facetas
#
# Las facetas se ordenan por año del máximo, de la entidad que deja de crecer
# primero a la que sigue creciendo hasta el final del horizonte. La escala
# vertical es libre porque Ciudad de México y Colima difieren en un orden de
# magnitud y con escala común las series pequeñas quedarían planas.
# ---------------------------------------------------------------------------

orden_facetas <- maximos_estatales$nom_ent

poblacion_estatal <- poblacion_estatal %>%
  mutate(nom_ent = factor(nom_ent, levels = orden_facetas))

maximos_estatales <- maximos_estatales %>%
  mutate(nom_ent = factor(nom_ent, levels = orden_facetas))

navy      <- "#1E4C7D"
rojo      <- "#C0392B"
gris_text <- "#555555"

grafica_facetas <- ggplot(poblacion_estatal, aes(x = year, y = valor)) +
  geom_line(color = navy, linewidth = 0.6) +
  geom_point(data = maximos_estatales, color = rojo, size = 2.2) +
  geom_text(
    data = maximos_estatales,
    aes(label = year),
    color = rojo, size = 2.9, vjust = -0.9, hjust = 0.9
  ) +
  facet_wrap(~ nom_ent, ncol = 6, scales = "free_y") +
  scale_x_continuous(
    breaks = c(1970, 2020, 2070),
    expand = expansion(mult = 0.06)
  ) +
  scale_y_continuous(
    labels = label_number(scale = 1e-6, accuracy = 0.1),
    expand = expansion(mult = c(0.05, 0.18))
  ) +
  labs(
    title = "La mayoría de los estados alcanza su población máxima antes de 2070",
    subtitle = paste(
      "Población proyectada por entidad federativa, en millones de personas.",
      "El punto rojo marca el año del máximo."
    ),
    x = NULL,
    y = "Millones de personas",
    caption = paste(
      "Fuente: INEGI, indicador 1045 (serie estatal 1970-2070).",
      "Nombres de entidad tomados de las proyecciones municipales de CONAPO."
    )
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 15, color = navy),
    plot.subtitle = element_text(size = 10, color = gris_text,
                                 margin = margin(b = 12)),
    plot.caption = element_text(size = 8, color = gris_text, hjust = 0),
    strip.text = element_text(face = "bold", size = 9, color = navy),
    panel.grid.minor = element_blank(),
    panel.spacing = unit(0.8, "lines"),
    axis.text = element_text(size = 7.5, color = gris_text)
  )

ggsave(
  "figuras/01_proyecciones_estatales_facetas.png",
  plot = grafica_facetas,
  width = 15, height = 11, dpi = 300, bg = "white"
)
