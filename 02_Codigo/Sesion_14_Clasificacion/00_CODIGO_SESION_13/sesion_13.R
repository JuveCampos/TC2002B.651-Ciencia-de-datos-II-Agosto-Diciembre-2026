# =============================================================================
# Análisis de texto de las conferencias matutinas ("mañaneras")
# de la presidenta Claudia Sheinbaum
#
# Objetivo:
#   1) Limpiar y normalizar las versiones estenográficas.
#   2) Lematizar los textos con udpipe (modelo para español).
#   3) Comparar tokens vs. lemas como unidades de análisis.
#   4) Calcular la matriz TF-IDF y graficar los 20 lemas más distintivos
#      de cada mañanera.
#
# Insumo:  01_datos/estenograficas_sheinbaum.rds
#          (tibble con al menos las columnas `titulo` y `texto`)
# =============================================================================


# Librerías -------------------------------------------------------------------
library(tidyverse)   # Manipulación de datos (dplyr, stringr, ggplot2, etc.)
library(tm)          # Solo se usa para obtener la lista de stopwords en español
library(udpipe)      # Tokenización, lematización y etiquetado gramatical (UPOS)
library(tidytext)    # Herramientas de texto "tidy"; aquí se usa bind_tf_idf()


# =============================================================================
# 1) PREPROCESAMIENTO
# =============================================================================

# Cargar la base con las versiones estenográficas
mananeras <- readRDS("01_datos/estenograficas_sheinbaum.rds")

mananeras_limpio <- mananeras |>
  # --- Limpieza del título ---------------------------------------------------
# Quitar el prefijo "Versión Estenográfica. " (con mayúscula o minúscula en la E)
mutate(titulo = str_remove(titulo,
                           pattern = "Versión Estenográfica. |Versión estenográfica. ")) |>
  # Acortar el título largo a simplemente "Mañanera <fecha/descripción>"
  mutate(titulo = str_replace_all(titulo,
                                  pattern = "Conferencia de prensa de la presidenta Claudia Sheinbaum Pardo ",
                                  replacement = "Mañanera ")) |>
  # Conservar únicamente los documentos que efectivamente son mañaneras
  # (descarta otros eventos o discursos que vengan en la misma base)
  filter(str_detect(titulo, pattern = "^Mañanera")) |>
  
  # --- Normalización del texto -----------------------------------------------
# Pasar todo a minúsculas para que "México" y "méxico" cuenten como lo mismo
mutate(texto = str_to_lower(texto)) |>
  # Quitar todos los signos de puntuación (comas, puntos, guiones, comillas, etc.)
  mutate(texto = str_remove_all(texto, pattern = "[:punct:]")) |>
  # Eliminar dígitos (años, cifras, porcentajes, etc.)
  mutate(texto = str_remove_all(texto, pattern = "\\d+")) |>
  # Unificar nombres compuestos en un solo término para que el modelo
  # no los parta en varias palabras (ej. "comisión federal de electricidad" -> "cfe")
  mutate(texto = str_replace_all(texto, c(
    "comisión federal de electricidad"             = "cfe",
    "presidenta de méxico claudia sheinbaum pardo"  = "claudia_sheinbaum",
    "secretaría de relaciones exteriores"           = "sre", 
    "pepe merino" = "pepe_merino", 
    "tren maya" = "tren_maya", 
    "lorena cuéllar" = "lorena_cuellar", 
    "lorena alcaide" = "lorena", 
    "laura velázquez" = "laura_velazquez", 
    "rosaura ruíz" = "rosaura_ruiz", 
    "claudia curiel de icaza" = "claudia_curiel_de_icaza",
    "ingrid gómez" = "ingrid_gomez", 
    "sarahí esmeralda arellano rodríguez" = "sarahí_esmeralda_arellano_rodríguez", 
    "elvira concheiro bórquez" = "elvira_concheiro_bórquez"
  ))) |>
  # Quedarse con las 10 primeras filas (se asume que la base está ordenada
  # de la más reciente a la más antigua, i.e. son las 10 mañaneras más recientes)
  slice(1:10)


mananeras_limpio |> 
  unnest_tokens(output = "ngramas", input = "texto", token = "ngrams", n = 5) |> 
  select(titulo, ngramas) |> 
  filter(str_detect(ngramas, pattern = "elvira"))


# =============================================================================
# Descarga y carga del modelo de udpipe para español
# =============================================================================

# 1. Descargar el modelo pre-entrenado (solo es necesario la primera vez;
#    se guarda en el directorio de trabajo como un archivo .udpipe)
modelo <- udpipe_download_model(language = "spanish")

# 2. Cargar el modelo en memoria para poder usarlo con udpipe_annotate()
udmodel <- udpipe_load_model(modelo$file_model)


# =============================================================================
# 2) LEMATIZACIÓN Y ANOTACIÓN GRAMATICAL
# =============================================================================
# udpipe_annotate() recibe cada texto, lo divide en oraciones y tokens, y
# devuelve por cada token: el lema (`lemma`), la categoría gramatical universal
# (`upos`: NOUN, VERB, ADJ, ...), los rasgos morfológicos (`feats`: género,
# número, tiempo verbal, ...) y relaciones de dependencia sintáctica.

lematizacion <- udpipe_annotate(udmodel,                       # Modelo cargado
                                doc_id = mananeras_limpio$titulo, # Identificador de cada documento
                                x      = mananeras_limpio$texto) |> # Vector de textos a anotar
  as_tibble()                                                  # Convertir la salida a tibble

# Algunos tokens no reciben lema (quedan NA); en esos casos se usa el token
# original para no perder la palabra en los conteos posteriores
lematizacion <- lematizacion |>
  mutate(lemma = ifelse(is.na(lemma), yes = token, no = lemma))


# =============================================================================
# 3) COMPARACIÓN DE VOCABULARIO: TOKENS vs. LEMAS
# =============================================================================
# Pregunta: ¿cuántos términos únicos hay en cada columna y cuál conviene usar
# para identificar las palabras más relevantes por mañanera?

# Número de tokens únicos en las 10 mañaneras (resultado observado: 10,681)
unique(lematizacion$token) |> length()

# Número de lemas únicos en las 10 mañaneras (resultado observado: 7,432)
unique(lematizacion$lemma) |> length()

# Interpretación:
#   El lema reduce el vocabulario ~30% porque agrupa las variantes flexivas
#   de una misma palabra ("gobiernos", "gobierno" -> "gobierno";
#   "dijo", "decir", "dijimos" -> "decir"). Para medir relevancia por documento
#   es preferible el lema: concentra la frecuencia en una sola forma y evita
#   que un mismo concepto se diluya entre varias conjugaciones o plurales,
#   sin perder legibilidad (a diferencia del stem, que suele truncar la palabra
#   en formas poco interpretables como "gobiern" o "presid").
#
# Nota: udpipe no devuelve una columna `stem`; si se quisiera comparar con
# stems habría que calcularlos aparte (p. ej. con SnowballC::wordStem).


# =============================================================================
# EJERCICIO 02 — MATRIZ TF-IDF
# =============================================================================
# TF-IDF pondera cada término por su frecuencia dentro del documento (TF)
# y penaliza los términos que aparecen en muchos documentos (IDF). Así, los
# términos con TF-IDF alto son los que distinguen a una mañanera de las demás.

# Lista de stopwords en español (artículos, preposiciones, pronombres, etc.)
tm::stopwords(kind = "es")

# Convertirla a tibble con una columna llamada `lemma` para poder usar anti_join()
stopwors_es <- tibble(lemma = tm::stopwords(kind = "es"))

matriz_tf_idf <- lematizacion |>
  # Quedarse solo con el documento y el lema de cada token
  select(doc_id, lemma) |>
  # Contar cuántas veces aparece cada lema en cada documento (frecuencia bruta)
  group_by(doc_id, lemma) |>
  count() |>
  arrange(-n) |>
  # Eliminar stopwords (se une por la columna `lemma`)
  anti_join(stopwors_es) |>
  # Calcular tf, idf y tf_idf por término y documento
  bind_tf_idf(term = lemma, document = doc_id, n = n) |>
  # Ordenar dentro de cada documento de mayor a menor tf_idf
  arrange(doc_id, -tf_idf) |>
  # Asignar un ranking por documento (ties.method = "first" rompe empates
  # por orden de aparición para que no haya rangos repetidos)
  group_by(doc_id) |>
  mutate(ranking = rank(-tf_idf, ties.method = "first")) |>
  # Conservar los 20 lemas más distintivos de cada mañanera
  filter(ranking <= 20)

# Gráfica: un panel por mañanera con sus 20 lemas de mayor TF-IDF
matriz_tf_idf |>
  ggplot(aes(x = reorder_within(lemma, by =  tf_idf, within = doc_id), y = tf_idf)) + # Ordenar barras por tf_idf
  coord_flip() +           # Barras horizontales
  scale_x_reordered() + 
  geom_col(color = "white") +                             # Barras con borde blanco
  facet_wrap(~str_wrap(doc_id, 20), scales = "free")      # Un panel por documento;
# str_wrap corta los títulos
# largos a 20 caracteres por línea

