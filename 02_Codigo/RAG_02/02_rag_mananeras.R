# =============================================================================
# 02_rag_mananeras.R
# RAG sobre las mañaneras de la presidenta con ragnar + ellmer + Ollama
# (todo local, sin API keys), usando el corpus que descargó
# 01_scraper_mananeras.R.
#
# Pipeline: lectura con metadatos -> fragmentación -> embeddings + almacén
#           DuckDB -> recuperación (semántica, léxica, híbrida, con filtro
#           por fecha) -> generación -> evaluación
#
# Requisitos:
#   install.packages(c("ragnar", "ellmer", "tidyverse"))
#   Ollama corriendo con:  ollama pull bge-m3   y   ollama pull qwen3.5:4b
#   y la variante con más contexto (una sola vez):
#     ollama create qwen3.5-4b-8k -f Modelfile.qwen3.5-4b-8k
# =============================================================================

library(ragnar)
library(ellmer)
library(tidyverse)

# -----------------------------------------------------------------------------
# Parámetros: aquí se detiene la clase a discutir cada decisión
# -----------------------------------------------------------------------------
ruta_indice <- "mananeras/indice_mananeras.csv"
ruta_almacen <- "mananeras_ago_sep.ragnar.duckdb"

# Subconjunto del corpus: agosto y septiembre de 2026 (unas 27 mañaneras).
# El corpus completo (71) tarda unos 6 minutos más en embeberse.
fecha_desde <- as.Date("2026-08-01")
fecha_hasta <- as.Date("2026-09-30")

modelo_embeddings <- "bge-m3"        # multilingüe, 1,024 dimensiones
modelo_generador <- "qwen3.5-4b-8k"  # qwen3.5:4b con contexto de 8,192 tokens
tamano_fragmento <- 1600             # caracteres por fragmento (~400 tokens)
traslape <- 0.25                     # fracción de traslape entre fragmentos
top_k <- 5                           # fragmentos que se entregan al modelo

# qwen3.5 "piensa" antes de responder y eso multiplica por 20 el tiempo de
# cada respuesta. Ollama acepta reasoning_effort = "none" por la interfaz
# compatible con OpenAI, que es la que usa ellmer
sin_razonamiento <- list(reasoning_effort = "none")

# -----------------------------------------------------------------------------
# PASO 1. Lectura con metadatos: cada archivo trae título, fecha y URL
# -----------------------------------------------------------------------------
# A diferencia de RAG_01, aquí los metadatos importan: el sistema debe poder
# citar de qué mañanera salió cada dato y filtrar por fecha.
indice <- read_csv(ruta_indice, show_col_types = FALSE) %>%
  filter(descargado, fecha_conferencia >= fecha_desde,
         fecha_conferencia <= fecha_hasta) %>%
  arrange(fecha_conferencia)
stopifnot(nrow(indice) > 0)
print(str_glue(
  "Mañaneras en el subconjunto: {nrow(indice)} ",
  "({min(indice$fecha_conferencia)} a {max(indice$fecha_conferencia)})"
))

# Las tres primeras líneas de cada archivo son metadatos; el cuerpo empieza
# en la quinta. Se separa cada cosa en su columna
documentos <- indice %>%
  mutate(
    lineas = map(archivo, read_lines),
    # purrr::map devuelve una columna-lista de vectores de líneas dentro del
    # pipeline; con lapply habría que asignar fuera del mutate
    cuerpo = map_chr(lineas, ~ paste(.x[-(1:4)], collapse = "\n")),
    caracteres = nchar(cuerpo)
  ) %>%
  select(fecha = fecha_conferencia, titulo, url, archivo, cuerpo, caracteres)

# Se inspecciona un documento: un párrafo por turno de palabra
print(substr(documentos$cuerpo[1], 1, 600))

# -----------------------------------------------------------------------------
# PASO 2. Fragmentación: partir cada mañanera en pedazos con contexto
# -----------------------------------------------------------------------------
# markdown_chunk corta por tamaño objetivo pero "ajusta" el corte al límite
# de párrafo más cercano (max_snap_dist). Como cada párrafo es un turno de
# palabra, los fragmentos rara vez parten a un orador a media frase.
fragmentar <- function(cuerpo, archivo, fecha, titulo, url) {
  MarkdownDocument(cuerpo, origin = archivo) %>%
    markdown_chunk(target_size = tamano_fragmento, target_overlap = traslape) %>%
    mutate(fecha = fecha, titulo = titulo, url = url)
}

fragmentos_ejemplo <- with(documentos[1, ],
                           fragmentar(cuerpo, archivo, fecha, titulo, url))
print(fragmentos_ejemplo)
print(fragmentos_ejemplo$text[5])

# Cuántos fragmentos produce cada mañanera (sin embeber todavía)
resumen_fragmentos <- documentos %>%
  mutate(n_fragmentos = pmap_int(
    list(cuerpo, archivo, fecha, titulo, url),
    ~ nrow(fragmentar(..1, ..2, ..3, ..4, ..5))
  )) %>%
  select(fecha, caracteres, n_fragmentos)
print(resumen_fragmentos, n = Inf)
print(str_glue("Total de fragmentos: {sum(resumen_fragmentos$n_fragmentos)}"))

# -----------------------------------------------------------------------------
# PASO 3. Embeddings + almacén: base vectorial en DuckDB con columnas extra
# -----------------------------------------------------------------------------
# extra_cols declara las columnas de metadatos que viajan con cada fragmento
# y que después permiten filtrar la recuperación. Si el almacén ya existe se
# reutiliza; para reconstruirlo basta borrar el archivo .duckdb
if (file.exists(ruta_almacen)) {
  almacen <- ragnar_store_connect(ruta_almacen, read_only = TRUE)
} else {
  almacen <- ragnar_store_create(
    ruta_almacen,
    embed = \(x) embed_ollama(x, model = modelo_embeddings),
    extra_cols = data.frame(
      fecha = as.Date(character()),
      titulo = character(),
      url = character()
    )
  )

  inicio <- Sys.time()
  for (i in seq_len(nrow(documentos))) {
    d <- documentos[i, ]
    print(str_glue(
      "[{i}/{nrow(documentos)}] Embebiendo mañanera del {d$fecha}"
    ))
    fragmentos <- fragmentar(d$cuerpo, d$archivo, d$fecha, d$titulo, d$url)
    ragnar_store_insert(almacen, fragmentos)
  }
  ragnar_store_build_index(almacen)
  minutos <- as.numeric(difftime(Sys.time(), inicio, units = "mins"))
  print(str_glue("Embeddings listos en {round(minutos, 1)} minutos"))
}

# En la búsqueda híbrida ragnar fusiona los fragmentos traslapados de un mismo
# documento y devuelve fecha, titulo y url como columnas-lista. Se reduce
# cada una a su primer valor (los fragmentos fusionados comparten documento)
# para poder filtrar, formatear y comparar fechas con normalidad
aplanar <- function(resultado) {
  primero <- function(v) map_chr(v, function(e) as.character(e[[1]]))
  resultado %>%
    mutate(
      fecha = as.Date(primero(fecha)),
      across(any_of(c("titulo", "url")), primero)
    )
}

# Envolturas de los tres métodos de recuperación, ya con metadatos aplanados
recuperar_vss <- function(texto, k = top_k, ...) {
  ragnar_retrieve_vss(almacen, texto, top_k = k, ...) %>% aplanar()
}
recuperar_bm25 <- function(texto, k = top_k, ...) {
  ragnar_retrieve_bm25(almacen, texto, top_k = k, ...) %>% aplanar()
}
recuperar_hibrida <- function(texto, k = top_k, ...) {
  ragnar_retrieve(almacen, texto, top_k = k, ...) %>% aplanar()
}

# -----------------------------------------------------------------------------
# PASO 4. Recuperación SIN generación: el paso pedagógico central
# -----------------------------------------------------------------------------
pregunta <- "¿Cuál fue el promedio diario de homicidios dolosos en agosto de 2026?"

# Función auxiliar para imprimir resultados de forma compacta. En la búsqueda
# híbrida las métricas llegan como columnas-lista (un valor por fragmento
# fusionado); se reduce al mejor valor para poder imprimir
mostrar <- function(resultado) {
  a_numero <- function(v) if (is.list(v)) sapply(v, \(x) min(unlist(x))) else v
  # Las búsquedas semántica y léxica entregan su métrica en las columnas
  # metric_name / metric_value; se renombra para imprimirla con su nombre
  if ("metric_value" %in% names(resultado)) {
    resultado <- resultado %>%
      mutate(!!resultado$metric_name[1] := metric_value)
  }
  resultado %>%
    mutate(
      across(any_of(c("cosine_distance", "bm25")), \(v) round(a_numero(v), 3)),
      inicio = str_sub(str_squish(text), 1, 100)
    ) %>%
    select(fecha, any_of(c("cosine_distance", "bm25")), inicio) %>%
    print(width = 120)
}

# 4a. Búsqueda semántica: por cercanía de embeddings
recuperados_vss <- recuperar_vss(pregunta)
mostrar(recuperados_vss)

# 4b. Búsqueda léxica (BM25): por coincidencia de palabras. En mañaneras
# pesa mucho porque las preguntas traen nombres propios, programas y cifras
recuperados_bm25 <- recuperar_bm25(pregunta)
mostrar(recuperados_bm25)

# 4c. Búsqueda híbrida: combina ambas (opción por defecto). Ojo: tras la
# fusión de fragmentos, el orden de las filas ya no es un ranking
recuperados <- recuperar_hibrida(pregunta)
mostrar(recuperados)
print(recuperados$text[1])

# 4d. Recuperación con filtro por fecha: lo nuevo respecto a RAG_01.
# "¿Qué dijo sobre aranceles la primera semana de septiembre?" se resuelve
# mejor acotando las fechas ANTES de buscar que dejando que la similitud
# adivine el periodo. Si el filtro no deja fragmentos, ragnar falla, por
# eso se envuelve en tryCatch
recuperar_en_periodo <- function(texto, desde, hasta, k = top_k) {
  tryCatch(
    recuperar_hibrida(texto, k, filter = fecha >= desde & fecha <= hasta),
    error = function(e) tibble()
  )
}

recuperados_periodo <- recuperar_en_periodo(
  "aranceles a países sin tratado de libre comercio",
  as.Date("2026-09-01"), as.Date("2026-09-07")
)
mostrar(recuperados_periodo)

# Contraste: la misma consulta sin filtro trae fechas de todo el corpus
mostrar(recuperar_hibrida("aranceles a países sin tratado de libre comercio"))

# -----------------------------------------------------------------------------
# PASO 5a. Generación con prompt aumentado: se pegan los fragmentos al prompt
# -----------------------------------------------------------------------------
# Cada fragmento se etiqueta con la fecha de la mañanera para que el modelo
# pueda citarla
armar_contexto <- function(fragmentos) {
  fragmentos %>%
    mutate(bloque = paste0("[Mañanera del ", format(fecha, "%d/%m/%Y"),
                           "]\n", text)) %>%
    pull(bloque) %>%
    paste(collapse = "\n\n")
}

instrucciones <- paste(
  "Eres un asistente que responde preguntas sobre las conferencias de prensa",
  "matutinas de la presidenta de México.",
  "Responde SOLO con la información de los fragmentos que se te entregan",
  "y menciona la fecha de la mañanera de donde sale cada dato.",
  "Si la información no está en los fragmentos, di explícitamente que no",
  "aparece en las mañaneras consultadas. Responde en español, en máximo",
  "cinco oraciones."
)

prompt_aumentado <- paste0(
  "### Fragmentos recuperados\n", armar_contexto(recuperados),
  "\n\n### Pregunta\n", pregunta
)
print(paste("Caracteres del prompt aumentado:", nchar(prompt_aumentado)))

inicio <- Sys.time()
chat_manual <- chat_ollama(model = modelo_generador,
                           system_prompt = instrucciones,
                           api_args = sin_razonamiento)
respuesta_manual <- chat_manual$chat(prompt_aumentado, echo = "none")
print(respuesta_manual)
segundos <- as.numeric(difftime(Sys.time(), inicio, units = "secs"))
print(str_glue("Respuesta en {round(segundos)} segundos"))

# -----------------------------------------------------------------------------
# PASO 5b. Generación con herramienta: el modelo decide cuándo y qué buscar
# -----------------------------------------------------------------------------
# La búsqueda se expone como herramienta. Devuelve texto plano compacto
# (fecha + fragmento) porque con modelos locales pequeños la salida en JSON
# de ragnar_register_tool_retrieve() los hace "olvidar" la pregunta
buscar_mananeras <- tool(
  function(consulta) {
    recuperar_hibrida(consulta, k = 3) %>% armar_contexto()
  },
  name = "buscar_mananeras",
  description = paste(
    "Busca fragmentos relevantes en las versiones estenográficas de las",
    "conferencias de prensa matutinas de la presidenta de México de agosto",
    "y septiembre de 2026."
  ),
  arguments = list(
    consulta = type_string("Texto de búsqueda, en español")
  )
)

chat <- chat_ollama(
  model = modelo_generador,
  system_prompt = paste(
    "Responde en español, en máximo cinco oraciones, solo con la información",
    "que devuelva la herramienta buscar_mananeras, y cita la fecha de la",
    "mañanera de cada dato. Si la información no está, di que no aparece en",
    "las mañaneras consultadas."
  ),
  api_args = sin_razonamiento
)
chat$register_tool(buscar_mananeras)

respuesta_herramienta <- tryCatch(
  chat$chat("¿Cuántos pasajeros internacionales ha transportado el Tren Maya?",
            echo = "none"),
  error = function(e) paste("El modelo no pudo usar la herramienta:",
                            conditionMessage(e))
)
print(respuesta_herramienta)

# Pregunta de control: algo que NO está en el corpus, para ver si se abstiene
respuesta_control <- tryCatch(
  chat$chat("¿Qué dijo la presidenta sobre el resultado del Mundial de 2030?",
            echo = "none"),
  error = function(e) conditionMessage(e)
)
print(respuesta_control)

# -----------------------------------------------------------------------------
# PASO 6. Evaluación mínima: ¿la mañanera correcta aparece entre los top-k?
# -----------------------------------------------------------------------------
# Cada pregunta lleva la fecha de la mañanera donde vive la respuesta (se
# verificó a mano en los textos). Métrica: hit@k por fecha. Ojo: algunos
# datos se repiten en varias mañaneras (los informes de seguridad, por
# ejemplo), así que un "fallo" puede ser una fecha distinta con el mismo dato
conjunto_prueba <- tribble(
  ~pregunta, ~fecha_esperada,
  "¿Cuántos pasajeros internacionales ha transportado el Tren Maya?", "2026-08-13",
  "¿Cuántas tarjetas para remesas otorgó Financiera para el Bienestar?", "2026-08-14",
  "¿Cuál es la meta de viviendas en Tlaxcala?", "2026-08-19",
  "¿Cuántas viviendas se construirán en Kanasín?", "2026-08-12",
  "¿A qué empresas se adjudicó el mantenimiento de las vías del Tren Maya entre Palenque y Cancún?", "2026-09-03",
  "¿Cuántas personas resultaron lesionadas en la agresión en Zacatecas?", "2026-09-04",
  "¿Cuál fue el promedio diario de homicidios dolosos en agosto de 2026?", "2026-09-08",
  "¿Cuándo se pusieron aranceles a países sin Tratado de Libre Comercio?", "2026-09-02"
) %>%
  mutate(fecha_esperada = as.Date(fecha_esperada))

# Se compara la misma métrica con los tres métodos de recuperación
acierto_con <- function(recuperar) {
  map2_lgl(conjunto_prueba$pregunta, conjunto_prueba$fecha_esperada,
           \(p, f) f %in% pull(recuperar(p), fecha))
}

resultados_evaluacion <- conjunto_prueba %>%
  mutate(
    semantica = acierto_con(recuperar_vss),
    lexica = acierto_con(recuperar_bm25),
    hibrida = acierto_con(recuperar_hibrida)
  )

resultados_evaluacion %>%
  mutate(pregunta = str_sub(pregunta, 1, 55)) %>%
  print(width = 120)

resultados_evaluacion %>%
  summarise(across(c(semantica, lexica, hibrida), ~ 100 * mean(.x))) %>%
  rename_with(~ paste0("hit@", top_k, "_", .x)) %>%
  print()

# Se libera la memoria de la Mac al terminar
system2("ollama", c("stop", modelo_generador))
system2("ollama", c("stop", modelo_embeddings))

# -----------------------------------------------------------------------------
# EXTRA. Inspector visual del almacén (app Shiny), útil para proyectar
# -----------------------------------------------------------------------------
# ragnar_store_inspect(almacen)
