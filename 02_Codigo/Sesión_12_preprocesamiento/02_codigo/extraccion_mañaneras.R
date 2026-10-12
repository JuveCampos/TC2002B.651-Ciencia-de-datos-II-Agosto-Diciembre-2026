# ============================================================
# Extracción de versiones estenográficas de Presidencia (gob.mx)
# Sesión 12 · Preprocesamiento de texto
# ============================================================
#
# ¿Por qué dejó de funcionar la versión anterior? (octubre de 2026)
#
# 1. El listado de artículos (archivo/articulos?page=N) NO responde HTML,
#    responde JavaScript (un fragmento de jQuery con el HTML escapado dentro
#    de una cadena). Antes rvest lo "tragaba" por accidente; las versiones
#    recientes de xml2 ya no parsean una respuesta con Content-Type
#    text/javascript y regresan un documento vacío.
#
# 2. gob.mx puso un filtro anti-bots. Si el servidor no reconoce al cliente
#    (por ejemplo, el user agent genérico que usa read_html(url)) contesta
#    con una página de "Challenge Validation" de ~2 KB en vez del artículo.
#    La petición hecha con httr2 sí pasa, así que descargamos el cuerpo con
#    httr2 y se lo pasamos a rvest como texto.
#
# 3. El bucle while usaba una variable `switch` que nunca se inicializaba
#    (y además `switch` es una función de R). Ahora el criterio de paro es
#    explícito: nos detenemos cuando una página del listado ya solo tiene
#    artículos anteriores a la fecha de corte.
#
# Además el script ahora es INCREMENTAL: lee el Excel que ya tenemos, ve
# cuál es la fecha más reciente y solo descarga lo que falta. Si el Excel
# no existe, descarga todo desde el 1 de enero de 2025.
#
# Se asume que el directorio de trabajo es la raíz del proyecto
# (ejercicio_12.Rproj), por eso las rutas empiezan con 01_datos/.

# Librerías
library(tidyverse) # Manejo de datos
library(rvest)     # Web scraping en R
library(httr2)     # Peticiones HTTP (sustituye a read_html(url))
library(readxl)    # Leer el Excel que ya tenemos

# ------------------------------------------------------------
# 0. Parámetros
# ------------------------------------------------------------

ruta_xlsx <- "01_datos/estenograficas_sheinbaum.xlsx"
ruta_rds <- "01_datos/estenograficas_sheinbaum.rds"
url_base <- "https://www.gob.mx"
url_listado <- str_c(
  url_base,
  "/presidencia/es/archivo/articulos?idiom=es&order=DESC&page="
)
pausa_segundos <- 0.5 # Cortesía con el servidor entre peticiones
max_paginas <- 200    # Freno de seguridad para el while

# Meses en español para convertir "09 de octubre de 2026" a fecha
meses <- c(
  enero = 1, febrero = 2, marzo = 3, abril = 4, mayo = 5, junio = 6,
  julio = 7, agosto = 8, septiembre = 9, octubre = 10, noviembre = 11,
  diciembre = 12
)

# ------------------------------------------------------------
# 1. Datos que ya tenemos y fecha de corte
# ------------------------------------------------------------

if (file.exists(ruta_xlsx)) {
  estenograficas_previas <- read_excel(ruta_xlsx) %>%
    mutate(across(everything(), as.character))
} else {
  estenograficas_previas <- tibble(
    titulo = character(), texto = character(), fecha = character()
  )
}

# Convertimos la fecha en texto ("24 de septiembre de 2025") a Date
fechas_previas <- estenograficas_previas %>%
  mutate(
    dia = str_extract(fecha, "^\\d{1,2}") %>% as.integer(),
    mes = str_extract(fecha, "de (\\w+) de", group = 1) %>%
      str_to_lower(),
    anio = str_extract(fecha, "\\d{4}$") %>% as.integer(),
    fecha_date = make_date(anio, meses[mes], dia)
  ) %>%
  pull(fecha_date)

# Fecha de corte: lo más reciente que ya tenemos. Si no hay nada,
# arrancamos desde el inicio de 2025.
if (length(fechas_previas) > 0) {
  fecha_corte <- max(fechas_previas, na.rm = TRUE)
} else {
  fecha_corte <- as_date("2024-12-31")
}
print(str_c("Ya tenemos ", nrow(estenograficas_previas),
            " versiones estenográficas. Fecha de corte: ", fecha_corte))

# ------------------------------------------------------------
# 2. Descargar una página con httr2 (en lugar de read_html(url))
# ------------------------------------------------------------

# Regresa el cuerpo de la respuesta como texto. Reintenta si el servidor
# falla momentáneamente.
descargar_texto <- function(url) {
  Sys.sleep(pausa_segundos)
  request(url) %>%
    req_retry(max_tries = 3, backoff = function(i) 2 * i) %>%
    req_perform() %>%
    resp_body_string()
}

# ------------------------------------------------------------
# 3. Recorrer el listado hasta llegar a la fecha de corte
# ------------------------------------------------------------

# En cada página del listado hay 9 artículos. Guardamos fecha de
# publicación, título y liga de cada uno. Nos detenemos cuando una página
# ya solo trae artículos de la fecha de corte o anteriores.
p <- 1
sigue <- TRUE
listado <- list()

while (sigue & p <= max_paginas) {

  # La respuesta es JavaScript con HTML escapado: quitamos los escapes
  # (\" -> ", \/ -> /, \n -> salto de línea) antes de parsear.
  html_listado <- descargar_texto(str_c(url_listado, p)) %>%
    str_replace_all(fixed('\\"'), '"') %>%
    str_replace_all(fixed("\\/"), "/") %>%
    str_replace_all(fixed("\\n"), "\n") %>%
    read_html()

  articulos <- html_listado %>% html_nodes("article")

  tabla_pagina <- tibble(
    fecha_publicacion = articulos %>% html_node("time") %>%
      html_attr("date") %>% as_datetime() %>% as_date(),
    titulo_listado = articulos %>% html_node("h2") %>% html_text() %>%
      str_squish(),
    liga = articulos %>% html_node("a") %>% html_attr("href") %>%
      str_c(url_base, .)
  )

  listado[[p]] <- tabla_pagina
  print(str_c("Página ", p, ": ", nrow(tabla_pagina), " artículos, del ",
              min(tabla_pagina$fecha_publicacion), " al ",
              max(tabla_pagina$fecha_publicacion)))

  # Criterio de paro: toda la página es de la fecha de corte o anterior.
  # Usamos un día de margen porque la fecha de publicación puede ser un
  # día posterior a la fecha de la conferencia.
  sigue <- any(tabla_pagina$fecha_publicacion > fecha_corte + 1) &
    nrow(tabla_pagina) > 0
  p <- p + 1
}

listado_tibble <- listado %>%
  bind_rows() %>%
  filter(fecha_publicacion > fecha_corte - 1) %>%
  distinct(liga, .keep_all = TRUE)

print(str_c("Artículos candidatos a descargar: ", nrow(listado_tibble)))

# ------------------------------------------------------------
# 4. Descargar cada artículo
# ------------------------------------------------------------

# Acá como pueden ver tenemos un bucle (lapply) que entra a cada liga.
# De cada artículo sacamos el título (h1), el texto (los párrafos del
# cuerpo) y la fecha que aparece en la cabecera del artículo.
cosecha <- lapply(seq_along(listado_tibble$liga), function(l) {

  liga <- listado_tibble$liga[l]

  subpagina <- descargar_texto(liga) %>% read_html()

  titulo <- subpagina %>%
    html_nodes("h1") %>%
    html_text() %>%
    str_squish() %>%
    str_c(collapse = "\n")

  # Tomamos solo los párrafos del cuerpo del artículo (.article-body) para
  # no arrastrar el pie de página del portal. Si el sitio cambia la clase,
  # caemos a todos los <p> como hacía la versión anterior.
  nodos_cuerpo <- subpagina %>% html_nodes(".article-body p")
  if (length(nodos_cuerpo) == 0) {
    nodos_cuerpo <- subpagina %>% html_nodes("p")
  }
  texto <- nodos_cuerpo %>%
    html_text() %>%
    str_c(collapse = "\n")

  fecha <- subpagina %>%
    html_nodes("div section") %>%
    html_text() %>%
    str_squish() %>%
    str_remove_all(pattern = "Presidencia de la República") %>%
    str_remove_all(pattern = "\\s?\\|\\s?") %>%
    str_squish() %>%
    first()

  print(str_c("Listo artículo ", l, " de ", nrow(listado_tibble), ": ",
              titulo))

  tibble(titulo, texto, fecha, liga)
})

# Con los datos del bucle anterior (que son una lista) hicimos una tabla
estenograficas_nuevas <- cosecha %>%
  bind_rows()

# ------------------------------------------------------------
# 5. Limpieza del texto (misma receta que antes)
# ------------------------------------------------------------

estenograficas_nuevas <- estenograficas_nuevas %>%
  mutate(texto = str_remove_all(texto, "Leer más $")) %>%
  mutate(texto = str_remove_all(
    texto,
    "Es el portal único de trámites, información y participación ciudadana."
  )) %>%
  mutate(texto = str_remove_all(
    texto,
    pattern = "Presidencia de la República\\s*\\|\\s*\\d+ de \\w+ de \\d+"
  )) %>%
  mutate(texto = str_remove_all(texto, pattern = "\\s\\|\\s")) %>%
  mutate(texto = str_replace_all(texto, pattern = "\n", replacement = " ")) %>%
  mutate(texto = str_squish(texto)) %>%
  mutate(texto = str_remove_all(
    texto,
    str_c(
      " ?—000— Puedes seleccionar más de uno. ",
      "Puedes seleccionar más de una opción. ",
      "Gracias por tu opinión. La legalidad, veracidad y la calidad ",
      "de la información es estricta responsabilidad de la dependencia, ",
      "entidad o empresa productiva del Estado que la proporcionó en virtud ",
      "de sus atribuciones y/o facultades normativas."
    )
  )) %>%
  # Quitamos la marca de cierre "—000—" al final del texto
  mutate(texto = str_remove_all(texto, "\\s*—000—\\s*$")) %>%
  mutate(texto = str_squish(texto))

# ------------------------------------------------------------
# 6. Unir con lo que ya teníamos y guardar
# ------------------------------------------------------------

# Solo agregamos las filas nuevas que no estuvieran ya (por título y fecha,
# porque los datos viejos no tienen liga). Lo que ya teníamos no se toca.
# Las filas nuevas van primero, igual que en el listado (más reciente arriba).
estenograficas_nuevas <- estenograficas_nuevas %>%
  filter(nchar(texto) > 0) %>%
  anti_join(estenograficas_previas, by = c("titulo", "fecha"))

estenograficas_tibble <- bind_rows(
  estenograficas_nuevas,
  estenograficas_previas
)

print(str_c("Se agregaron ",
            nrow(estenograficas_tibble) - nrow(estenograficas_previas),
            " versiones estenográficas. Total: ",
            nrow(estenograficas_tibble)))

# Guardamos las versiones estenográficas en un excel.
# openxlsx avisa que muchos textos rebasan los 32,767 caracteres por celda
# que admite Excel. El archivo guarda el texto completo (readxl lo lee bien),
# pero Excel lo mostrará recortado; para análisis conviene usar el RDS.
openxlsx::write.xlsx(estenograficas_tibble, ruta_xlsx)

# Las guardamos en un RDS
saveRDS(estenograficas_tibble, ruta_rds)
