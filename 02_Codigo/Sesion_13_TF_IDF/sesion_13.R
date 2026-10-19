
# Librerías ---
library(tidyverse)
library(tm)
library(udpipe)
library(tidytext) # Preprocesamiento 

# 1) Preprocesamiento. 
mananeras <- readRDS("01_datos/estenograficas_sheinbaum.rds")

mananeras_limpio <- mananeras |> 
  mutate(titulo = str_remove(titulo, pattern = "Versión Estenográfica. |Versión estenográfica. ")) |> 
  mutate(titulo = str_replace_all(titulo,
                                  pattern = "Conferencia de prensa de la presidenta Claudia Sheinbaum Pardo ", replacement = "Mañanera ")) |> 
  filter(str_detect(titulo, pattern = "^Mañanera")) |> 
  mutate(texto = str_to_lower(texto)) |> 
  # Quitar todos los símbolos de puntuación: 
  mutate(texto = str_remove_all(texto, pattern = "[:punct:]")) |> 
  # Eliminar dígitos
  mutate(texto = str_remove_all(texto, pattern = "\\d+")) |> 
  # Reemplazar términos
  mutate(texto = str_replace_all(texto, c("comisión federal de electricidad" = "cfe", 
                                          "presidenta de méxico claudia sheinbaum pardo" = "claudia_sheinbaum", 
                                          "secretaría de relaciones exteriores" = "sre"
                                          ))) |> 
  slice(1:10)

# 1) Descargue el modelo de udpipe necesario para lematizar las palabras utilizadas en español

# 1. Descargar modelo
modelo <- udpipe_download_model(language = "spanish")
# 2. Cargar el modelo
udmodel <- udpipe_load_model(modelo$file_model)

# 2) A partir de este modelo, genere, a partir de las 10 mañaneras más recientes, un objeto que tenga las palabras, los tokens, los lemmas, los stems, el upos (clasificación de la palabra) y los Feats (características de la palabra). Esto lo calcula la funcion udpipe_annotate().

lematizacion <- udpipe_annotate(udmodel, # Modelo de lematizacion 
                                doc_id = mananeras_limpio$titulo, # ID de cada documento/mañanera
                                x = mananeras_limpio$texto) |> # Columna de textos
  as_tibble()


lematizacion <- lematizacion |> 
  mutate(lemma = ifelse(is.na(lemma), yes = token, no = lemma))

# 3) Cuente el total de términos únicos que hay en la columna de tokens, la columna de lemma y la columna de stem. ¿Cuál tiene menos términos? ¿Cuál usaría para saber cuales son las palabras más relevantes por mañanera? ¿Por qué? 

# Cuantos tokens unicos hay en las 10 mañaneras: 10681
unique(lematizacion$token) |> length()

# Cuantos lemmas unicos hay en las 10 mañaneras: 7432
unique(lematizacion$lemma) |> length()

# Ejercicio 02 ----
# Dado el objeto que guarda las 10 mañaneras más recientes: 
#   1) Calcule la matríz tf-idf para las 10 mañaneras más recientes

tm::stopwords(kind = "es")
stopwors_es <- tibble(lemma = tm::stopwords(kind = "es"))

matriz_tf_idf <- lematizacion |> 
  select(doc_id, lemma) |> 
  group_by(doc_id, lemma) |> 
  count() |> 
  arrange(-n) |> 
  anti_join(stopwors_es) |> 
  bind_tf_idf(term = lemma, document = doc_id, n = n) |> 
  arrange(doc_id, -tf_idf) |> 
  group_by(doc_id) |> 
  mutate(ranking = rank(-tf_idf, ties.method = "first")) |> 
  filter(ranking <= 20)
  
matriz_tf_idf  |> 
  ggplot(aes(x = reorder(lemma, tf_idf), y = tf_idf)) + 
  coord_flip() + 
  geom_col(color = "white") + 
  facet_wrap(~str_wrap(doc_id, 20), scales ="free")



