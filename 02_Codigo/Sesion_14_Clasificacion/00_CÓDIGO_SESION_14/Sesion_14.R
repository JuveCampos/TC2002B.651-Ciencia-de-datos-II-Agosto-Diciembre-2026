
# Librerías ----
library(tidyverse)
library(tidytext)
library(tm)

# Cargamos los datos ----
comentarios <- readxl::read_xlsx("01_datos/comentarios_etiquetados.xlsx")

# Preprocesamiento ----
comentarios_limpio <- comentarios |> 
  select(id, texto, etiqueta_final) |> 
  mutate(texto = str_remove_all(texto, pattern = "\\d+")) |> 
  mutate(texto = str_remove_all(texto, pattern = "[:punct:]")) |> 
  mutate(texto = str_squish(texto)) |> 
  mutate(texto = str_to_lower(texto)) |> 
  mutate(texto = str_replace_all(texto, c("á" = "a", 
                                          "é" = "e",
                                          "í" = "i", 
                                          "ó" = "o", 
                                          "ú" = "u"))) |> 
  mutate(texto = str_replace_all(texto, c("bla bla bla" = "bla_bla_bla", 
                                          "jajajaja jajajaja jajajaja" = "jajaja"
                                          )))
  
  
# Limpieza de n gramas: 
comentarios_limpio |> 
  unnest_tokens(output = "token", input = texto, 
                token = "ngrams", n = 2) |> 
  count(token) |> 
  arrange(-n)

# Tokenizamos el texto : 
stop_words <- stopwords(kind = "es")
tabla_stopwords <- tibble(tokens = stop_words)

matriz_doc_termino <- comentarios_limpio |> 
  unnest_tokens(output = "tokens", 
                input = texto, token = "words") |> 
  anti_join(tabla_stopwords) |> 
  count(id, tokens) |> 
  cast_dtm(document = id, 
           term = tokens,
           value = n, 
           weighting = tm::weightTfIdf)

matriz_doc_termino |> as.matrix() |> as_tibble()





