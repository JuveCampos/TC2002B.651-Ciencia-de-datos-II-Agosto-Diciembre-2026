

# library(tm)
# library(SnowballC)
library(tidytext)
library(tidyverse)

# Cargar las mañaneras ----
mananeras <- readRDS("01_datos/estenograficas_sheinbaum.rds")

# Genere un objeto con el contenido de la mañanera más reciente, 
# y guardelo en el objeto mananera_reciente
mananera_reciente <- mananeras |> slice(2)

# Para el objeto mananera_reciente, realice las siguientes actividades: 
# Elimine todos los acentos
# Elimine todos los números

mananera_reciente_2 <- mananera_reciente |> 
  mutate(texto = str_replace_all(texto, c("á" = "a", 
                                   "é" = "e", 
                                   "í" = "i", 
                                   "ó" = "o", 
                                   "ú" = "u", 
                                   "Á" = "A", 
                                   "É" = "E", 
                                   "Í" = "I", 
                                   "Ó" = "O", 
                                   "Ú" = "U")
                                 )) |> 
  mutate(texto = str_remove_all(texto, pattern = "\\d+"))

# 3. Descomponga el texto en tokens de frases. 
mañanera_frases <- mananera_reciente_2 |> 
  unnest_tokens(output = "frases", 
                input = texto, 
                token = "sentences", to_lower = F)

# 4. Descomponga el texto en tokens de ngramas (3,4 y 5). 
mañanera_n3 <- mananera_reciente_2 |> 
  unnest_tokens(output = "n_grama_3", 
                input = texto, 
                token = "ngrams",
                n = 3,
                to_lower = F)

mañanera_n4 <- mananera_reciente_2 |> 
  unnest_tokens(output = "n_grama_4", 
                input = texto, 
                token = "ngrams",
                n = 4,
                to_lower = FALSE)

# 4. Descomponga el texto en tokens de palabras. 
# Realice un wordcloud con estas palabras.
# Guarde este resultado en un objeto llamado “palabras”

mañanera_palabras <- mananera_reciente_2 |> 
  unnest_tokens(output = "palabras", 
                input = texto, 
                token = "words",
                to_lower = TRUE)

# Cargamos las funciones del código wordcloud_juve.r
source("02_codigo/wordcloud_juve.r")

create_wordcloud(data = mañanera_palabras$palabras,
                 stop_words = c("presidenta", "mexico", "claudia", "sheinbaum", "pardo"))

