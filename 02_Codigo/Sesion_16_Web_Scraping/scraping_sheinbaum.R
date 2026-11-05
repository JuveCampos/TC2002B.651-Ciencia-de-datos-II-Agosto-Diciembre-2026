
# Librerías
library(rvest)
library(tidyverse)
library(httr2)

# Objetivo: extraer las versiones estenográficas de las últimas 100
# conferencias de prensa de la presidenta desde el archivo de gob.mx.

# Datos generales ----

url_listado <- str_c(
  "https://www.gob.mx/presidencia/es/archivo/articulos",
  "?idiom=es&order=DESC&page="
)

# El servidor rechaza con un error 403 el identificador de RStudio, así que
# cada petición se presenta con este identificador.
identificador <- "Mozilla/5.0"

numero_conferencias <- 100

# El archivo tenía 121 páginas el 4 de noviembre de 2026. El bucle se detiene
# antes, en cuanto reúne las conferencias necesarias.
vector_todas_paginas <- 1:121

# Parte 1. Recorrer el listado y juntar títulos, fechas y enlaces ----

tabla_vacia_listado <- tibble()

for (k in vector_todas_paginas) {

  url_pagina <- str_c(url_listado, k)

  # Paso 1. Descargar el código de la página.
  # request(): prepara la petición con la URL, pero todavía no la envía.
  # req_user_agent(): agrega el identificador con el que R se presenta ante
  #   el servidor. Aquí se evita el error 403.
  # req_perform(): envía la petición por internet y recibe la respuesta, que
  #   trae el código de estado, los encabezados y el cuerpo. Si el servidor
  #   responde con un error, se detiene y muestra el código (por ejemplo, 403).
  # resp_body_string(): saca el cuerpo de la respuesta como una sola cadena
  #   de texto. Aquí viene JavaScript con el HTML escapado adentro.
  texto_pagina <- url_pagina %>%
    request() %>%
    req_user_agent(identificador) %>%
    req_perform() %>%
    resp_body_string()

  # Paso 2. Quitar los escapes de JavaScript para recuperar el HTML.
  # \" se vuelve ", \/ se vuelve / y \n se vuelve un espacio.
  html_pagina <- texto_pagina %>%
    str_replace_all('\\\\"', '"') %>%
    str_replace_all("\\\\/", "/") %>%
    str_replace_all("\\\\n", " ") %>%
    read_html()

  # Paso 3. Extraer los datos que me interesan.
  articulos <- html_pagina %>%
    html_elements("article")

  titulos <- articulos %>%
    html_element("h2") %>%
    html_text2()

  fechas <- articulos %>%
    html_element("time") %>%
    html_text2() %>%
    str_remove("Fecha de publicación") %>%
    str_squish()

  enlaces <- articulos %>%
    html_element("a") %>%
    html_attr("href") %>%
    url_absolute("https://www.gob.mx")

  # Paso 4. Agregar los artículos de esta página a la tabla vacía.
  tabla_pagina <- tibble(titulo = titulos, fecha = fechas, url = enlaces)

  tabla_vacia_listado <- rbind(tabla_vacia_listado, tabla_pagina)

  # Paso 5. Contar las conferencias reunidas hasta ahora.
  # El listado también trae giras y otros eventos, que aquí se descartan.
  # Algunos títulos dicen "matutina", por eso el patrón es tan general.
  tabla_conferencias <- tabla_vacia_listado %>%
    filter(str_detect(
      titulo,
      regex("conferencia de prensa", ignore_case = TRUE)
    )) %>%
    distinct(url, .keep_all = TRUE)

  # Mensaje
  print(str_c(
    "Página ", k, ": van ", nrow(tabla_conferencias), " conferencias"
  ))

  # Pausa para no saturar el servidor
  Sys.sleep(1)

  # Salir del bucle cuando ya se tienen suficientes conferencias
  if (nrow(tabla_conferencias) >= numero_conferencias) {
    break
  }
}

# El listado viene de la más reciente a la más antigua, así que las primeras
# 100 filas son las últimas 100 conferencias.
tabla_conferencias <- tabla_conferencias %>%
  slice_head(n = numero_conferencias)

# Parte 2. Entrar a cada conferencia y extraer el texto ----

vector_texto_vacio <- c()

for (i in 1:nrow(tabla_conferencias)) {

  # Se repite la misma secuencia de la Parte 1. Esta vez la respuesta ya es
  # HTML normal, así que no hace falta quitar escapes.
  html_conferencia <- tabla_conferencias$url[i] %>%
    request() %>%
    req_user_agent(identificador) %>%
    req_perform() %>%
    resp_body_string() %>%
    read_html()

  texto_conferencia <- html_conferencia %>%
    html_element(".article-body") %>%
    html_text2() %>%
    str_trim()

  vector_texto_vacio <- append(vector_texto_vacio, texto_conferencia)

  # Mensaje
  print(str_c("Ya se extrajo la conferencia ", i))

  # Pausa para no saturar el servidor
  Sys.sleep(1)
}

# Parte 3. Unir y guardar ----

tabla_final <- tabla_conferencias %>%
  mutate(texto = vector_texto_vacio)

# Validar que estén todas las conferencias y que ninguna quedó sin texto
stopifnot(
  nrow(tabla_final) == numero_conferencias,
  !any(is.na(tabla_final$texto))
)

# Se guarda en CSV porque una celda de Excel admite 32,767 caracteres como
# máximo y cada conferencia puede rebasar ese límite.
write_csv(tabla_final, "conferencias_sheinbaum.csv")
