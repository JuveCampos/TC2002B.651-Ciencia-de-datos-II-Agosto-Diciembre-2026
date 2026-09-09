# =============================================================================
# 01_scraper_mananeras.R
# Descarga las versiones estenográficas de las conferencias de prensa
# matutinas ("mañaneras") de la presidenta de México desde gob.mx y las
# guarda como texto plano para un ejercicio de RAG.
#
# Fuente: https://www.gob.mx/presidencia/es/archivo/articulos
#
# Nota técnica: gob.mx protege el sitio con un reto anti-bots de Akamai
# (responde una página "Challenge Validation" a httr2/rvest). Un navegador
# real sí resuelve el reto, por eso usamos chromote (Chrome sin cabeza
# controlado desde R) para navegar y rvest para parsear el HTML resultante.
# =============================================================================

library(chromote)
library(rvest)
library(xml2)
library(dplyr)
library(stringr)
library(purrr)
library(tibble)
library(readr)

# -----------------------------------------------------------------------------
# 0. Parámetros
# -----------------------------------------------------------------------------

# Fecha mínima de conferencia a descargar. Sheinbaum tomó posesión el
# 1 de octubre de 2024; con tres meses se obtienen ~65 mañaneras, un corpus
# manejable para embeber en una Mac de 16 GB. Ampliar según se necesite.
fecha_min <- as.Date("2026-06-01")

# Carpeta de salida (relativa a RAG_02)
dir_salida <- "mananeras"
dir_txt <- file.path(dir_salida, "txt")
ruta_indice <- file.path(dir_salida, "indice_mananeras.csv")
dir.create(dir_txt, recursive = TRUE, showWarnings = FALSE)

# Pausa entre peticiones (segundos), por cortesía con el servidor
pausa <- 1.5

# URL base del archivo de artículos
url_base <- "https://www.gob.mx"
url_archivo <- paste0(
  url_base, "/presidencia/es/archivo/articulos?idiom=es&order=DESC&page="
)

# Agente de usuario de un Chrome de escritorio
agente <- paste(
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
  "(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"
)

# -----------------------------------------------------------------------------
# 1. Sesión de Chrome sin cabeza
# -----------------------------------------------------------------------------

navegador <- ChromoteSession$new()
navegador$Network$setUserAgentOverride(userAgent = agente)

# Carga una URL, espera a que Akamai libere el reto (la página provisional
# se titula "Challenge Validation") y devuelve el HTML ya parseado.
obtener_html <- function(url, intentos = 15) {
  navegador$Page$navigate(url)
  navegador$Page$loadEventFired(timeout_ = 60)
  for (i in seq_len(intentos)) {
    titulo <- navegador$Runtime$evaluate("document.title")$result$value
    if (!str_detect(titulo, "Challenge")) break
    Sys.sleep(2)
  }
  html <- navegador$Runtime$evaluate(
    "document.documentElement.outerHTML"
  )$result$value
  read_html(html)
}

# -----------------------------------------------------------------------------
# 2. Índice: recorrer el archivo página por página
# -----------------------------------------------------------------------------

# Cada página del archivo trae 9 artículos en bloques <article> con
# <time date="...">, <h2> (título) y <a class="small-link"> (enlace).
# Se recorre hacia atrás hasta que la fecha más reciente de una página
# sea anterior a fecha_min o hasta que ya no haya artículos.
meses <- c(
  "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
  "septiembre", "octubre", "noviembre", "diciembre"
)

paginas <- list()
pagina <- 1
repeat {
  print(str_glue("Leyendo página {pagina} del archivo"))
  doc <- obtener_html(paste0(url_archivo, pagina))
  articulos <- html_elements(doc, "article")
  if (length(articulos) == 0) break

  tabla <- tibble(
    titulo = articulos %>% html_element("h2") %>% html_text2(),
    fecha_publicacion = articulos %>% html_element("time") %>%
      html_attr("date") %>% as.POSIXct(tz = "America/Mexico_City"),
    url = articulos %>% html_element("a.small-link") %>% html_attr("href") %>%
      str_remove("\\?.*$") %>% paste0(url_base, .)
  )
  paginas[[pagina]] <- tabla

  if (min(as.Date(tabla$fecha_publicacion)) < fecha_min) break
  pagina <- pagina + 1
  Sys.sleep(pausa)
}

# Se consolidan las páginas y se identifican las mañaneras. El título de la
# conferencia sigue el patrón "Versión estenográfica. Conferencia de prensa
# de la presidenta ... del 08 de septiembre de 2026"; la fecha de la
# conferencia se toma del título (la de publicación puede diferir).
indice <- bind_rows(paginas) %>%
  distinct(url, .keep_all = TRUE) %>%
  mutate(
    es_estenografica = str_detect(titulo, regex("^Versi[oó]n estenogr",
                                                ignore_case = TRUE)),
    es_mananera = es_estenografica &
      str_detect(titulo, regex("conferencia de prensa", ignore_case = TRUE)),
    fecha_txt = str_extract(
      titulo, "\\d{1,2} de [a-z]+ de \\d{4}"
    ),
    dia = as.integer(str_extract(fecha_txt, "^\\d{1,2}")),
    mes = match(str_extract(fecha_txt, "(?<=de )[a-z]+"), meses),
    anio = as.integer(str_extract(fecha_txt, "\\d{4}$")),
    fecha_conferencia = if_else(
      !is.na(dia) & !is.na(mes) & !is.na(anio),
      as.Date(str_glue(
        "{anio}-{str_pad(mes, 2, pad = '0')}-{str_pad(dia, 2, pad = '0')}"
      )),
      as.Date(fecha_publicacion)
    ),
    slug = basename(url),
    archivo = if_else(
      es_mananera,
      file.path(dir_txt, paste0(fecha_conferencia, "_", slug, ".txt")),
      NA_character_
    )
  ) %>%
  select(fecha_conferencia, titulo, es_estenografica, es_mananera, url,
         fecha_publicacion, archivo) %>%
  arrange(desc(fecha_conferencia))

print(str_glue(
  "Artículos listados: {nrow(indice)}; ",
  "versiones estenográficas: {sum(indice$es_estenografica)}; ",
  "mañaneras: {sum(indice$es_mananera)}"
))

# -----------------------------------------------------------------------------
# 3. Descarga del texto de cada mañanera
# -----------------------------------------------------------------------------

# El cuerpo del artículo está en div.article-body, con un <p> por turno de
# palabra y el nombre del orador en <strong>. Se conserva un párrafo por
# línea y una línea en blanco entre párrafos, que es lo que los chunkers de
# RAG usan como frontera natural.
extraer_texto <- function(doc) {
  cuerpo <- html_element(doc, "div.article-body")
  parrafos <- cuerpo %>% html_elements("p") %>% html_text2() %>%
    str_squish() %>% discard(~ .x == "")
  paste(parrafos, collapse = "\n\n")
}

pendientes <- indice %>%
  filter(es_mananera, fecha_conferencia >= fecha_min, !file.exists(archivo))

ya_existen <- sum(indice$es_mananera & indice$fecha_conferencia >= fecha_min) -
  nrow(pendientes)
print(str_glue("Mañaneras por descargar: {nrow(pendientes)} ",
               "(ya existen {ya_existen})"))

for (i in seq_len(nrow(pendientes))) {
  fila <- pendientes[i, ]
  print(str_glue("[{i}/{nrow(pendientes)}] {fila$titulo}"))
  doc <- tryCatch(obtener_html(fila$url), error = function(e) NULL)
  if (is.null(doc)) {
    print(str_glue("  Falló la descarga de {fila$url}"))
    next
  }
  texto <- extraer_texto(doc)
  if (nchar(texto) < 500) {
    print("  Texto demasiado corto; se omite")
    next
  }
  # Encabezado con metadatos, útil para que el RAG cite fecha y fuente
  encabezado <- c(
    paste0("Título: ", fila$titulo),
    paste0("Fecha: ", format(fila$fecha_conferencia, "%d de "),
           meses[as.integer(format(fila$fecha_conferencia, "%m"))],
           format(fila$fecha_conferencia, " de %Y")),
    paste0("Fuente: ", fila$url),
    ""
  )
  write_lines(c(encabezado, texto), fila$archivo)
  Sys.sleep(pausa)
}

navegador$close()

# -----------------------------------------------------------------------------
# 4. Índice final con tamaño de cada texto
# -----------------------------------------------------------------------------

indice <- indice %>%
  mutate(
    descargado = !is.na(archivo) & file.exists(archivo),
    caracteres = if_else(descargado, map_int(archivo, ~ {
      if (is.na(.x) || !file.exists(.x)) NA_integer_ else
        as.integer(sum(nchar(read_lines(.x))))
    }), NA_integer_)
  )
write_csv(indice, ruta_indice)

resumen <- indice %>%
  filter(descargado) %>%
  summarise(
    mananeras = n(),
    desde = min(fecha_conferencia),
    hasta = max(fecha_conferencia),
    caracteres_totales = sum(caracteres),
    caracteres_promedio = round(mean(caracteres))
  )
print(resumen)
