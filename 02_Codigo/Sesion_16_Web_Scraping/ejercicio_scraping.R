
# Librerías
library(rvest)
library(tidyverse)
library(openxlsx)

# Ejercicio 1 ----

# Entre al sitio "https://en.wikipedia.org/wiki/Legality_of_cannabis" y
# extraiga la tabla de países donde el consumo de cannabis es ilegal.
# ¿En qué porcentaje de países el consumo recreacional es ilegal?

# Paso 1. Extraer el código de la página de interés
url_cannabis <- "https://en.wikipedia.org/wiki/Legality_of_cannabis"

codigo_cannabis <- read_html(url_cannabis)

# Paso 2. Extraer el elemento que me interesa
tabla <- codigo_cannabis %>%
  html_table() %>%
  pluck(3)

# Paso 3. Procesar los datos
tabla_ilegal <- tabla %>%
  filter(str_detect(string = Recreational,
                    pattern = "Illegal|illegal"))

# Paso 4. Calcular el porcentaje
porcentaje_ilegal <- 100 * nrow(tabla_ilegal) / nrow(tabla)

print(str_c("Es ilegal en el ", round(porcentaje_ilegal, 1),
            "% de los países"))

# Ejercicio 2 ----

# Entre al sitio "https://atiempo.tv/author/juvenal-campos/" y extraiga todos
# los artículos de este autor.

# Las páginas siguen este patrón:
# https://atiempo.tv/author/juvenal-campos/page/1/
# https://atiempo.tv/author/juvenal-campos/page/2/
# https://atiempo.tv/author/juvenal-campos/page/3/

url_autor <- "https://atiempo.tv/author/juvenal-campos/page/"

# Parte 1. Averiguar cuántas páginas hay ----

# La paginación aparece al pie de cada página: 1 2 3 … 12 Next.
# Me quedo con los elementos que son números y tomo el más grande. Así el
# código sigue funcionando cuando se publiquen más artículos.
total_paginas <- str_c(url_autor, 1, "/") %>%
  read_html() %>%
  html_nodes(".page-numbers") %>%
  html_text() %>%
  str_subset("^[0-9]+$") %>%
  as.numeric() %>%
  max()

print(str_c("El autor tiene ", total_paginas, " páginas de artículos"))

vector_todas_paginas <- 1:total_paginas

# Parte 2. Recorrer las páginas y juntar títulos, fechas y enlaces ----

tabla_vacia_articulos <- tibble()

for (k in vector_todas_paginas) {

  url_juve <- str_c(url_autor, k, "/")

  # Paso 1. Cargar el código html
  html_juve <- read_html(url_juve)

  # Paso 2. Extraer los datos que me interesan

  # Extraigo los títulos (selector ".entry-title")
  titulos <- html_juve %>%
    html_nodes(".entry-title") %>%
    html_nodes("a") %>%
    html_text()

  # Extraigo las fechas (selector ".entry-date")
  fechas <- html_juve %>%
    html_nodes(".entry-date") %>%
    html_nodes("time") %>%
    html_text()

  # Extraigo la URL de cada artículo
  url <- html_juve %>%
    html_nodes(".entry-title") %>%
    html_nodes("a") %>%
    html_attr("href")

  # Extraigo la introducción (selector ".entry-content")
  introduccion <- html_juve %>%
    html_nodes(".entry-content") %>%
    html_node("p") %>%
    html_text()

  # Paso 3. Agregar los artículos de esta página a la tabla vacía
  tabla_pagina <- tibble(titulos, fechas, url, introduccion)

  tabla_vacia_articulos <- rbind(tabla_vacia_articulos, tabla_pagina)

  # Mensaje
  print(str_c("Lista la extracción de la página ", k))

  # Pausa para no saturar el servidor
  Sys.sleep(1)
}

# Parte 3. Entrar a cada artículo y extraer el texto ----

vector_texto_vacio <- c()

for (i in 1:nrow(tabla_vacia_articulos)) {

  html_articulo_individual <- read_html(tabla_vacia_articulos$url[i])

  # html_node(), en singular, devuelve un resultado por artículo. Así el
  # vector de textos queda alineado con las filas de la tabla.
  texto_articulo_individual <- html_articulo_individual %>%
    html_node(".entry-content") %>%
    html_text() %>%
    str_trim()

  vector_texto_vacio <- append(vector_texto_vacio,
                               texto_articulo_individual)

  # Mensaje
  print(str_c("Ya se extrajo el artículo ", i))

  # Pausa para no saturar el servidor
  Sys.sleep(1)
}

# Parte 4. Unir y guardar ----

tabla_final <- tabla_vacia_articulos %>%
  mutate(textos = vector_texto_vacio)

# Validar que ningún artículo quedó sin texto ni repetido
stopifnot(
  !any(is.na(tabla_final$textos)),
  !any(duplicated(tabla_final$url))
)

print(str_c("Se extrajeron ", nrow(tabla_final), " artículos"))

write.xlsx(tabla_final, "articulos_juve.xlsx")

# Parte 5. Buscar una palabra en los textos ----

names(tabla_final)

tabla_filtrado <- tabla_final %>%
  filter(str_detect(textos, "Claude"))

print(str_c(nrow(tabla_filtrado), " artículos mencionan a Claude"))
