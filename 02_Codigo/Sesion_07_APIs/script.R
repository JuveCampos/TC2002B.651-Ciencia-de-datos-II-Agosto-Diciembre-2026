
# Librerias ----
library(httr)
library(jsonlite)
library(tidyverse)
library(ggimage)

# https://pokeapi.co/api/v2/pokemon/pikachu

# Paso 1: Parte constante y parte variable de la solicitud
call1 <- paste0("https://pokeapi.co/api/v2/",
       "pokemon/pikachu")

# Llamada al API:
llamada <- GET(call1)

get_data <- content(llamada, "text")
class(get_data)

get_data_json <- fromJSON(get_data, flatten = TRUE)
class(get_data_json)

get_data_json$sprites$front_default
get_data_json$sprites$front_shiny

# Grafica de todos los pokemon del 1 al 151:
caso = 1
call1 <- paste0("https://pokeapi.co/api/v2/",
                "pokemon/", caso)
llamada <- GET(call1)
get_data <- content(llamada, "text")
get_data_json <- fromJSON(get_data, flatten = TRUE)

# Datos que necesito:
peso <- get_data_json$weight
altura <- get_data_json$height
nombre <- get_data_json$name
sprite <- get_data_json$sprites$front_default

# Empezar el for

bolsa_vacia <- tibble()
for(caso in 1:151){

  call1 <- paste0("https://pokeapi.co/api/v2/",
                  "pokemon/", caso)
  llamada <- GET(call1)
  get_data <- content(llamada, "text")
  get_data_json <- fromJSON(get_data, flatten = TRUE)

  # Datos que necesito:
  peso <- get_data_json$weight
  altura <- get_data_json$height
  nombre <- get_data_json$name
  sprite <- get_data_json$sprites$front_default

  # Tabla consulta:
  tabla_consulta <- tibble(id = caso, peso, altura, nombre, sprite)

  # Pegarle la tabla consulta a la tabla general
  bolsa_vacia <- rbind(tabla_consulta, bolsa_vacia)

  # Mensajito para saber como va
  print(paste0("Listo: ", nombre))

}

# Gráfica:
bolsa_vacia %>%
  ggplot(aes(x = peso, y = altura)) +
  geom_point() +
  geom_image(aes(image = sprite),
             size = 0.1) +
  labs(title = "Distribución peso/altura de los primeros 151 pokémon") +
  theme_minimal()



