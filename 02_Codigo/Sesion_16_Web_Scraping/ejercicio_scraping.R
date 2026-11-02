
# Librerías
library(rvest)
library(tidyverse)
library(openxlsx)

# Ejercicio 1. Entre al sitio “https://en.wikipedia.org/wiki/Legality_of_cannabis" y extraiga la tabla de países donde el consumo de cannabis es ilegal. ¿En qué porcentaje de países el consumo recreacional es ilegal?


# Paso 1. Extraer el código de la página de interés 

codigo_cannabis <- read_html("https://en.wikipedia.org/wiki/Legality_of_cannabis")

# Paso 2. Extraer el elemento que me interesa
tabla <- codigo_cannabis %>% 
  html_table() %>% 
  pluck(3)

# ??pluck
# Paso 3. Procesar los datos. 
tabla %>% 
  filter(str_detect(string = Recreational, 
                    pattern = "Illegal|illegal"))
  # filter(Recreational == "Illegal")

# class(tabla)
100*(163/202)


# Entre al sitio “https://atiempo.tv/author/juvenal-campos/" y extraiga todos los artículos de este autor. 

# https://atiempo.tv/author/juvenal-campos/page/1/
# https://atiempo.tv/author/juvenal-campos/page/2/
# https://atiempo.tv/author/juvenal-campos/page/3/

# caso n = 2
url_juve <- "https://atiempo.tv/author/juvenal-campos/page/2/"

# Paso 1. Cargar el código html
html_juve <- read_html(url_juve)

# Paso 2. Extraer los datos que me interesan 

".entry-title"

# Extraigo los títulos 
titulos <- html_juve %>% 
  html_nodes(".entry-title") %>% 
  html_nodes("a") %>% 
  html_text()

# Extraido las fechas 
".entry-date"

fechas <- html_juve %>% 
  html_nodes(".entry-date") %>% 
  html_nodes("time") %>% 
  html_text()

# Extraer la URL 
url <- html_juve %>% 
  html_nodes(".entry-title") %>% 
  html_nodes("a") %>% 
  html_attr("href")

introduccion <- html_juve %>% 
  html_nodes(".entry-content") %>% 
  html_nodes("p") %>%
  html_text()

# Texto 
i <- 3

vector_texto_vacio <- c()

for(i in 1:12){
  
  html_articulo_individual <- read_html(url[i])
  
  texto_articulo_individual <- html_articulo_individual %>% 
    html_nodes(".entry-content") %>% 
    html_text()
  
  vector_texto_vacio <- append(vector_texto_vacio,
                               texto_articulo_individual)
  
  # Mensaje 
  print(str_c("Ya se extrajo el artículo ", i))

}

tabla_datos <- cbind(titulos, fechas, url, introduccion,
                     textos = vector_texto_vacio)


# Bucle para las 10 páginas 



# Librerías
library(rvest)
library(tidyverse)

# Ejercicio 1. Entre al sitio “https://en.wikipedia.org/wiki/Legality_of_cannabis" y extraiga la tabla de países donde el consumo de cannabis es ilegal. ¿En qué porcentaje de países el consumo recreacional es ilegal?


# Paso 1. Extraer el código de la página de interés 

codigo_cannabis <- read_html("https://en.wikipedia.org/wiki/Legality_of_cannabis")

# Paso 2. Extraer el elemento que me interesa
tabla <- codigo_cannabis %>% 
  html_table() %>% 
  pluck(3)

# ??pluck
# Paso 3. Procesar los datos. 
tabla %>% 
  filter(str_detect(string = Recreational, 
                    pattern = "Illegal|illegal"))
# filter(Recreational == "Illegal")

# class(tabla)
100*(163/202)


# Entre al sitio “https://atiempo.tv/author/juvenal-campos/" y extraiga todos los artículos de este autor. 

# https://atiempo.tv/author/juvenal-campos/page/1/
# https://atiempo.tv/author/juvenal-campos/page/2/
# https://atiempo.tv/author/juvenal-campos/page/3/

# caso bucle
tabla_vacia_articulos <- tibble()

vector_todas_paginas <- 1:10

for(k in vector_todas_paginas){

url_juve <- str_c("https://atiempo.tv/author/juvenal-campos/page/", k, "/")

# Paso 1. Cargar el código html
html_juve <- read_html(url_juve)

# Paso 2. Extraer los datos que me interesan 

".entry-title"

# Extraigo los títulos 
titulos <- html_juve %>% 
  html_nodes(".entry-title") %>% 
  html_nodes("a") %>% 
  html_text()

# Extraido las fechas 
".entry-date"

fechas <- html_juve %>% 
  html_nodes(".entry-date") %>% 
  html_nodes("time") %>% 
  html_text()

# Extraer la URL 
url <- html_juve %>% 
  html_nodes(".entry-title") %>% 
  html_nodes("a") %>% 
  html_attr("href")

introduccion <- html_juve %>% 
  html_nodes(".entry-content") %>% 
  html_nodes("p") %>%
  html_text()

# Texto 
i <- 3

vector_texto_vacio <- c()

for(i in 1:length(introduccion)){
  
  html_articulo_individual <- read_html(url[i])
  
  texto_articulo_individual <- html_articulo_individual %>% 
    html_nodes(".entry-content") %>% 
    html_text()
  
  vector_texto_vacio <- append(vector_texto_vacio,
                               texto_articulo_individual)
  
  # Mensaje 
  print(str_c("Ya se extrajo el artículo ", i))
  
}

tabla_datos <- cbind(titulos, fechas, url, 
                     textos = vector_texto_vacio)

tabla_vacia_articulos <- rbind(tabla_vacia_articulos, tabla_datos)

# Mensaje: 
print(str_c("Lista la extracción de la página ", k))


}


tabla_vacia_articulos
write.xlsx(tabla_vacia_articulos, "articulos_juve.xlsx")


names(tabla_vacia_articulos)
tabla_filtrado <- tabla_vacia_articulos %>% 
  filter(str_detect(textos, "Claude"))


