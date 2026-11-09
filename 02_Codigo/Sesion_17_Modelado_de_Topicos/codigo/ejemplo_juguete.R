
# Sesión 17. Ejemplo de juguete de LDA ----

# Antes de ir a los datos reales (modelado_sencillo.R), vemos la mecánica
# de LDA con seis oraciones que hablan de tres temas evidentes: deportes,
# política y tecnología.

# Idea central de LDA:
# - Cada documento es una mezcla de tópicos (gamma: P(tópico | documento)).
# - Cada tópico es una mezcla de palabras (beta: P(palabra | tópico)).
# - El único parámetro que decidimos nosotros es k, el número de tópicos.

# Librerías ----
library(tidyverse)   # Manejo de datos y gráficas
library(tidytext)    # Tokenización y funciones tidy() para LDA
library(topicmodels) # Estimación del modelo LDA

# Paleta de colores, uno por tópico
paleta_topicos <- c("#1E4C7D", "#C0392B", "#1A7A3A")

# Stopwords en español (artículos, preposiciones, pronombres...)
stopwords_es <- tibble(palabra = tm::stopwords(kind = "es"))

# Documentos ----

docs <- tibble(
  id = 1:6,
  texto = c(
    "El equipo ganó el partido y el entrenador celebró la victoria.",
    "El jugador anotó un gol en el último minuto del partido de fútbol.",
    "El presidente anunció nuevas medidas de política económica.",
    "El ministro presentó un plan económico y político para el país.",
    "La empresa tecnológica lanzó un smartphone con una cámara nueva.",
    "Millones de personas compraron el smartphone inteligente este año."
  )
)

# Paso 1. Tokenizar (una fila por palabra), quitar stopwords y contar.
# unnest_tokens() ya pasa todo a minúsculas y quita la puntuación, que en el
# código del año pasado se hacía con varias llamadas a tm_map().
conteo_docs <- docs %>%
  unnest_tokens(output = palabra, input = texto) %>%
  anti_join(stopwords_es, by = "palabra") %>%
  count(id, palabra)

conteo_docs

# Paso 2. Convertir el conteo en una matriz documento-término (DTM).
# Filas = documentos, columnas = palabras, celdas = número de apariciones.
# Es el formato que necesita LDA().
dtm_docs <- conteo_docs %>%
  cast_dtm(document = id, term = palabra, value = n)

dtm_docs

# Paso 3. Entrenar el modelo con 3 tópicos. La semilla hace que el resultado
# sea reproducible, porque LDA arranca de una asignación aleatoria.
lda_docs <- LDA(dtm_docs, k = 3, control = list(seed = 0))

# Paso 4. Beta: probabilidad de cada palabra dentro de cada tópico.
# tidy() devuelve una tabla larga en lugar de la matriz del objeto.
beta_docs <- tidy(lda_docs, matrix = "beta")

beta_docs %>%
  group_by(topic) %>%
  slice_max(beta, n = 5) %>%
  ungroup() %>%
  ggplot(aes(x = beta,
             y = reorder_within(term, beta, topic),
             fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  scale_y_reordered() +
  scale_fill_manual(values = paleta_topicos) +
  facet_wrap(~ topic, scales = "free_y", labeller = label_both) +
  labs(title = "Ejemplo de juguete: palabras más probables por tópico",
       x = "beta: P(palabra | tópico)", y = NULL) +
  theme_minimal()

# Paso 5. Gamma: proporción de cada tópico dentro de cada documento.
gamma_docs <- tidy(lda_docs, matrix = "gamma")

gamma_docs %>%
  mutate(gamma = round(gamma, 3)) %>%
  pivot_wider(names_from = topic, values_from = gamma,
              names_prefix = "topico_")

# Con seis oraciones tan cortas el modelo casi no tiene información, así que
# es normal que mezcle temas. LDA necesita muchos documentos y documentos
# largos. Por eso en modelado_sencillo.R pasamos a los 133 artículos de
# la Sesión 16.
