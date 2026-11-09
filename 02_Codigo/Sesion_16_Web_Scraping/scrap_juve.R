
# Librerías ----
library(rvest)
library(httr2)
library(tidyverse)

"https://atiempo.tv/author/juvenal-campos/page/2/"

# Código de la pagina 2: 
html <- read_html("https://atiempo.tv/author/juvenal-campos/page/2/")

# Extraccion de titulos: 
titulos <- html |> 
  html_nodes(".entry-title") |> 
  html_nodes("a") |> 
  html_text()
  
# Extracción de links: 
links <- html |> 
  html_nodes(".entry-title") |> 
  html_nodes("a") |> 
  html_attr("href")
  
# Extraccion de fechas: 
fechas <- html |> 
  html_nodes(".entry-meta") |> 
  html_nodes(".entry-date") |> 
  html_nodes("time") |> 
  html_text()

# Concentrado de los datos de cada pagina: 
datos_pagina <- tibble(titulos, links, fechas)


# Hacemos la extraccion en bucle: 

tabla_vacia <- tibble()

for(i in 1:12){
  
  # Código de la pagina 2: 
  html <- read_html(str_glue("https://atiempo.tv/author/juvenal-campos/page/{i}/"))
  
  # Extraccion de titulos: 
  titulos <- html |> 
    html_nodes(".entry-title") |> 
    html_nodes("a") |> 
    html_text()
  
  # Extracción de links: 
  links <- html |> 
    html_nodes(".entry-title") |> 
    html_nodes("a") |> 
    html_attr("href")
  
  # Extraccion de fechas: 
  fechas <- html |> 
    html_nodes(".entry-meta") |> 
    html_nodes(".entry-date") |> 
    html_nodes("time") |> 
    html_text()
  
  # Concentrado de los datos de cada pagina: 
  datos_pagina <- tibble(titulos, links, fechas)
  
  # Llenado de la tabla
  tabla_vacia <- rbind(tabla_vacia, datos_pagina)
  
  print(str_glue("Ya está lista la extraccion de la página {i}"))
  
}

tabla_vacia <- tabla_vacia |> unique()



url_articulo <- "https://atiempo.tv/articulos-de-semanario/apuntes-de-datos-articulos-de-semanario/la-ia-ya-se-sabe-la-de-las-matematicas/"


html_articulo <- read_html(url_articulo)

texto_articulo <- html_articulo |> 
  html_node(".post-inner") |> 
  html_node(".entry-content") |> 
  html_nodes("p") |> 
  html_text() |> 
  str_c(collapse = "\n\n")

otra_tabla_vacia <- c()
for(link in tabla_vacia$links){
  
  html_articulo <- read_html(link)
  
  texto_articulo <- html_articulo |> 
    html_node(".post-inner") |> 
    html_node(".entry-content") |> 
    html_nodes("p") |> 
    html_text() |> 
    str_c(collapse = "\n\n")
  
  
  otra_tabla_vacia <- append(otra_tabla_vacia, texto_articulo)
  
  print(str_c("Ya está extraido el articulo: ", link))
  
}

tabla_final <- tabla_vacia |> 
  cbind(texto = otra_tabla_vacia)


# Guardar los datos ----

# Se guarda en Excel para usarlo como base en la Sesión 17 (Modelado de
# Tópicos). Ningún artículo rebasa los 32,767 caracteres que admite una celda.
library(openxlsx)

# Todos los artículos terminan con el mismo párrafo publicitario del medio
# ("ATiempo.Tv es el primer medio de comunicación nativo digital..."). Lo
# quitamos para que no contamine los análisis de texto. Se usa \\s+ en lugar
# de espacios porque el sitio separa esas palabras con espacios no
# separables, que un espacio normal del patrón no reconoce.
tabla_final <- tabla_final |> 
  mutate(texto = str_remove(texto, 
                            regex("\\s*ATiempo\\.Tv\\s+es\\s+el\\s+primer.*$", 
                                  ignore_case = TRUE, dotall = TRUE)))

write.xlsx(tabla_final, "articulos_atiempo.xlsx")
