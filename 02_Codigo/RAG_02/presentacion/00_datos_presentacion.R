# Genera los insumos numéricos de la presentación a partir del almacén y
# del corpus ya construidos por 02_rag_mananeras.R. No inventa nada.
suppressMessages({library(ragnar); library(ellmer); library(tidyverse); library(jsonlite); library(DBI)})
setwd("..")
dir_out <- "presentacion/datos"
top_k <- 5
almacen <- ragnar_store_connect("mananeras_ago_sep.ragnar.duckdb", read_only = TRUE)

# Reutiliza las funciones del script principal (aplanar, recuperar_*)
src <- readLines("02_rag_mananeras.R")
eval(parse(text = src[grep("^aplanar <- function", src):(grep("^# 4a[.]", src) - 1)]))

# 1. Respuesta SIN RAG (diapositiva 5)
pregunta <- "¿Cuál fue el promedio diario de homicidios dolosos en México en agosto de 2026, según lo que informó la presidenta Claudia Sheinbaum en su conferencia de prensa?"
chat_sin <- chat_ollama(model = "qwen3.5-4b-8k", system_prompt = "Responde en español, en máximo tres oraciones.", api_args = list(reasoning_effort = "none"))
sin_rag <- as.character(chat_sin$chat(pregunta, echo = "none"))
print(sin_rag)
system2("ollama", c("stop", "qwen3.5-4b-8k"))

# 2. Conteo de fragmentos por tamaño (diapositiva 10)
indice <- read_csv("mananeras/indice_mananeras.csv", show_col_types = FALSE) %>%
  filter(descargado, fecha_conferencia >= as.Date("2026-08-01"))
cuerpos <- map_chr(indice$archivo, ~ paste(read_lines(.x)[-(1:4)], collapse = "\n"))
conteo <- map_dfr(c(800, 1600, 3200), function(tam) {
  n <- map_int(cuerpos, ~ nrow(markdown_chunk(MarkdownDocument(.x, origin = "x"), target_size = tam, target_overlap = 0.25)))
  tibble(tamano = tam, fragmentos = sum(n), por_mananera = round(mean(n), 1))
})
print(conteo)

# 3. Recuperación por método (diapositiva 14) y filtro por fecha (15)
p_hom <- "¿Cuál fue el promedio diario de homicidios dolosos en agosto de 2026?"
compactar <- function(r) r %>% mutate(inicio = str_sub(str_squish(text), 1, 90)) %>%
  select(fecha, any_of(c("metric_value", "cosine_distance", "bm25")), inicio) %>%
  mutate(across(where(is.list), ~ map_dbl(.x, function(v) min(unlist(v)))))
metodos <- list(semantica = compactar(recuperar_vss(p_hom)), lexica = compactar(recuperar_bm25(p_hom)), hibrida = compactar(recuperar_hibrida(p_hom)))
p_ara <- "aranceles a países sin tratado de libre comercio"
filtro <- list(
  sin_filtro = compactar(recuperar_hibrida(p_ara)),
  con_filtro = compactar(recuperar_hibrida(p_ara, filter = fecha >= as.Date("2026-09-01") & fecha <= as.Date("2026-09-07")))
)

# 4. Evaluación (diapositiva 20)
conjunto <- tribble(~pregunta, ~fecha_esperada,
  "¿Cuántos pasajeros internacionales ha transportado el Tren Maya?", "2026-08-13",
  "¿Cuántas tarjetas para remesas otorgó Financiera para el Bienestar?", "2026-08-14",
  "¿Cuál es la meta de viviendas en Tlaxcala?", "2026-08-19",
  "¿Cuántas viviendas se construirán en Kanasín?", "2026-08-12",
  "¿A qué empresas se adjudicó el mantenimiento de las vías del Tren Maya entre Palenque y Cancún?", "2026-09-03",
  "¿Cuántas personas resultaron lesionadas en la agresión en Zacatecas?", "2026-09-04",
  "¿Cuál fue el promedio diario de homicidios dolosos en agosto de 2026?", "2026-09-08",
  "¿Cuándo se pusieron aranceles a países sin Tratado de Libre Comercio?", "2026-09-02") %>%
  mutate(fecha_esperada = as.Date(fecha_esperada))
acierto_con <- function(f) map2_lgl(conjunto$pregunta, conjunto$fecha_esperada, \(p, d) d %in% pull(f(p), fecha))
evaluacion <- conjunto %>% mutate(semantica = acierto_con(recuperar_vss), lexica = acierto_con(recuperar_bm25), hibrida = acierto_con(recuperar_hibrida))
print(evaluacion)

# 5. Embeddings del almacén para proyección 2D (diapositiva 12)
con <- almacen@con
emb_df <- dbGetQuery(con, "SELECT fecha, text, embedding FROM chunks")
e <- emb_df$embedding
M <- if (is.matrix(e)) e else if (is.list(e)) do.call(rbind, lapply(e, as.numeric)) else matrix(as.numeric(e), nrow = nrow(emb_df), byrow = TRUE)
print(dim(M))
pca <- prcomp(M, center = TRUE, scale. = FALSE)
temas <- c(seguridad = "homicidio|delito|seguridad|detenid|Guardia Nacional|extorsi",
           vivienda = "vivienda|Infonavit|Conavi|Fovissste",
           comercio = "arancel|Tratado|T-MEC|exportaci|importaci",
           salud = "IMSS|salud|hospital|medicamento",
           tren = "Tren Maya|Tren|pasajero")
tema <- map_chr(emb_df$text, function(t) { hits <- map_lgl(temas, ~ str_detect(t, regex(.x, ignore_case = TRUE))); if (any(hits)) names(temas)[which(hits)[1]] else "otros" })
proy <- tibble(pc1 = pca$x[, 1], pc2 = pca$x[, 2], tema = tema, fecha = as.character(emb_df$fecha))
write_csv(proy, file.path(dir_out, "proyeccion_2d.csv"))
print(table(tema)); print(round(100 * summary(pca)$importance[2, 1:2], 1))
system2("ollama", c("stop", "bge-m3"))

write_json(list(sin_rag = sin_rag, pregunta_sin_rag = pregunta, conteo = conteo, metodos = metodos, filtro = filtro, evaluacion = evaluacion),
           file.path(dir_out, "datos_presentacion.json"), auto_unbox = TRUE, pretty = TRUE)
