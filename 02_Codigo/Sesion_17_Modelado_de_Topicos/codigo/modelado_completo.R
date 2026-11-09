
# Sesión 17. Modelado de tópicos con LDA (versión completa) ----

# Script de repaso para casa. La versión de la práctica en vivo, que ya
# usa el k elegido aquí, está en modelado_sencillo.R.

# Objetivo: descubrir de qué temas hablan los artículos de la columna
# "Apuntes de Datos" (Atiempo.tv) sin leerlos uno por uno. Usamos LDA
# (Latent Dirichlet Allocation, asignación latente de Dirichlet), un modelo
# no supervisado: nadie le dice al modelo cuáles son los temas; los encuentra
# a partir de qué palabras suelen aparecer juntas en los mismos documentos.

# El ejemplo de juguete con seis oraciones está en ejemplo_juguete.R.

# Idea central de LDA:
# - Cada documento es una mezcla de tópicos (gamma: P(tópico | documento)).
# - Cada tópico es una mezcla de palabras (beta: P(palabra | tópico)).
# - El único parámetro que decidimos nosotros es k, el número de tópicos.

# Librerías ----
library(tidyverse)   # Manejo de datos y gráficas
library(tidytext)    # Tokenización y funciones tidy() para LDA
library(topicmodels) # Estimación del modelo LDA
library(readxl)      # Lectura del Excel de la Sesión 16
library(openxlsx)    # Guardado de resultados en Excel

# Carpeta para guardar las gráficas
dir.create("graficas", showWarnings = FALSE)

# Paleta de colores, uno por tópico (alcanza hasta para 10)
paleta_topicos <- c("#1E4C7D", "#C0392B", "#1A7A3A", "#D68910",
                    "#6C3483", "#117A65", "#7B7D7D", "#2E86C1",
                    "#A04000", "#B03A78")

# Stopwords en español (artículos, preposiciones, pronombres...)
stopwords_es <- tibble(palabra = tm::stopwords(kind = "es"))

# Parte 1. Cargar los artículos ----

# El Excel se generó con el script de scraping de la Sesión 16
# (scrap_juve.R). Tiene título, enlace, fecha y texto de cada artículo.
articulos <- read_excel("articulos_atiempo.xlsx") %>%
  distinct(links, .keep_all = TRUE) %>%
  mutate(id = row_number(),
         fecha = dmy(fechas, locale = "es_ES.UTF-8"),
         anio = year(fecha)) %>%
  select(id, titulo = titulos, fecha, anio, texto)

glimpse(articulos)

# Artículos por año
articulos %>%
  count(anio)

# Parte 2. Preprocesamiento ----

# Tokenizar, quitar números, stopwords y palabras de menos de 3 letras.
# No aplicamos stemming (recortar palabras a su raíz): uniría "modelo" con
# "modelos", pero deja raíces difíciles de leer ("elecc", "candidat") y aquí
# necesitamos leer las palabras para nombrar los tópicos. Además, en modelos
# de tópicos no suele mejorar los resultados (Schofield y Mimno, 2016).
tokens <- articulos %>%
  select(id, texto) %>%
  mutate(texto = str_remove_all(texto, "\\d+")) %>%
  unnest_tokens(output = palabra, input = texto) %>%
  anti_join(stopwords_es, by = "palabra") %>%
  filter(str_length(palabra) >= 3)

# ¿En cuántos documentos aparece cada palabra?
frecuencia_documental <- tokens %>%
  distinct(id, palabra) %>%
  count(palabra, name = "num_docs") %>%
  arrange(-num_docs)

# Las palabras más comunes no distinguen temas: "méxico", "años", "datos"...
frecuencia_documental %>%
  head(20)

# Filtro por frecuencia documental. Es el paso que más mejora los tópicos:
# - Palabras en menos de 3 artículos: son ruido (erratas, nombres sueltos).
# - Palabras en más de la mitad de los artículos: son tan generales que no
#   ayudan a separar un tema de otro (funcionan como stopwords del corpus).
vocabulario <- frecuencia_documental %>%
  filter(num_docs >= 3, num_docs <= 0.5 * nrow(articulos))

print(str_c("Vocabulario original: ", nrow(frecuencia_documental),
            " palabras. Vocabulario final: ", nrow(vocabulario)))

# Conteo de palabras por artículo con el vocabulario filtrado
conteo <- tokens %>%
  semi_join(vocabulario, by = "palabra") %>%
  count(id, palabra)

# Parte 3. Matriz documento-término ----

dtm <- conteo %>%
  cast_dtm(document = id, term = palabra, value = n)

# 133 documentos por ~4 mil términos; casi todas las celdas valen cero
dtm

# Parte 4. ¿Cuántos tópicos? ----

# k no se puede "aprender" de los datos como un coeficiente: hay que probar
# varios valores. Usamos la perplejidad sobre artículos que el modelo no vio
# en el entrenamiento. Mide qué tan sorprendido está el modelo ante textos
# nuevos: entre más baja, mejor generaliza.
# La perplejidad es una guía, no la última palabra: el criterio final es que
# los tópicos se puedan interpretar.

# Separamos 20% de los artículos como conjunto de prueba
set.seed(17)
ids_prueba <- sample(articulos$id, size = round(0.2 * nrow(articulos)))

dtm_entrenamiento <- conteo %>%
  filter(!id %in% ids_prueba) %>%
  cast_dtm(document = id, term = palabra, value = n)

dtm_prueba <- conteo %>%
  filter(id %in% ids_prueba) %>%
  cast_dtm(document = id, term = palabra, value = n)

# Entrenamos un modelo por cada valor de k y guardamos su perplejidad.
# Se usa el mismo patrón de tabla vacía + rbind() de la Sesión 16.
valores_k <- c(2, 4, 6, 8, 10, 12, 15)

tabla_perplejidad <- tibble()

for (k in valores_k) {

  modelo_k <- LDA(dtm_entrenamiento, k = k, control = list(seed = 17))

  tabla_k <- tibble(k = k,
                    perplejidad = perplexity(modelo_k, newdata = dtm_prueba))

  tabla_perplejidad <- rbind(tabla_perplejidad, tabla_k)

  # Mensaje
  print(str_c("Listo el modelo con k = ", k))
}

tabla_perplejidad

# El k con la menor perplejidad
k_final <- tabla_perplejidad %>%
  slice_min(perplejidad) %>%
  pull(k)

grafica_perplejidad <- tabla_perplejidad %>%
  ggplot(aes(x = k, y = perplejidad)) +
  geom_line(color = "#1E4C7D") +
  geom_point(color = "#1E4C7D", size = 3) +
  geom_point(data = tabla_perplejidad %>% slice_min(perplejidad),
             color = "#C0392B", size = 5) +
  scale_x_continuous(breaks = valores_k) +
  labs(title = str_c("La perplejidad en artículos nuevos es mínima con k = ",
                     k_final),
       subtitle = "Calculada en el 20% de artículos que no se usó al entrenar",
       x = "Número de tópicos (k)", y = "Perplejidad (menor es mejor)") +
  theme_minimal()

grafica_perplejidad

ggsave("graficas/01_perplejidad.png", grafica_perplejidad,
       width = 8, height = 5, dpi = 300, bg = "white")

# Parte 5. Modelo final ----

# Entrenamos con el k elegido (10) y ahora con todos los artículos.
# La curva de perplejidad es casi plana entre 4 y 10, así que conviene
# revisar también la interpretación: con k = 10 los tópicos se pueden nombrar
# con claridad, mientras que con k = 6 el agua y las elecciones quedaban
# mezcladas en un mismo tópico.
lda_modelo <- LDA(dtm, k = k_final, control = list(seed = 17))

# Vista rápida: las 10 palabras más probables de cada tópico
terms(lda_modelo, 10)

# Parte 6. Beta: ¿de qué trata cada tópico? ----

beta <- tidy(lda_modelo, matrix = "beta")

top_palabras <- beta %>%
  group_by(topic) %>%
  slice_max(beta, n = 10) %>%
  ungroup()

# Leemos las palabras y, para confirmar, los títulos de los artículos donde
# cada tópico domina (Parte 7). Con eso le ponemos nombre a cada tópico.
# Este paso es humano: el modelo solo entrega números del 1 al k.
# Ojo: si cambias la semilla, k o el preprocesamiento, el orden de los
# tópicos cambia y hay que volver a nombrarlos.
nombres_topicos <- tibble(
  topic = 1:10,
  nombre = c("01. Salud y mortalidad",
             "02. Gobierno, economía y justicia",
             "03. Desarrollo y competitividad",
             "04. Redes y tecnología digital",
             "05. Inteligencia artificial",
             "06. Elecciones y política",
             "07. Eventos de coyuntura",
             "08. Agua y sequía",
             "09. Pobreza, precios y empleo",
             "10. Mujeres, trabajo y juventud")
)

grafica_beta <- top_palabras %>%
  left_join(nombres_topicos, by = "topic") %>%
  ggplot(aes(x = beta,
             y = reorder_within(term, beta, nombre),
             fill = nombre)) +
  geom_col(show.legend = FALSE) +
  scale_y_reordered() +
  scale_fill_manual(values = paleta_topicos) +
  facet_wrap(~ nombre, scales = "free_y", ncol = 5) +
  labs(title = "Las 10 palabras más probables de cada tópico",
       x = "beta: P(palabra | tópico)", y = NULL) +
  theme_minimal() +
  theme(axis.text.x = element_text(size = 6))

grafica_beta

ggsave("graficas/02_palabras_por_topico.png", grafica_beta,
       width = 15, height = 7, dpi = 300, bg = "white")

# Parte 7. Gamma: ¿de qué tópicos se compone cada artículo? ----

gamma <- tidy(lda_modelo, matrix = "gamma") %>%
  mutate(id = as.numeric(document)) %>%
  left_join(nombres_topicos, by = "topic") %>%
  left_join(articulos %>% select(id, titulo, fecha, anio), by = "id")

# Tópico dominante: el de mayor gamma en cada artículo
topico_dominante <- gamma %>%
  group_by(id) %>%
  slice_max(gamma, n = 1) %>%
  ungroup()

# Tres artículos representativos de cada tópico (los de mayor gamma).
# Esta tabla es la que permite validar los nombres de la Parte 6.
topico_dominante %>%
  group_by(nombre) %>%
  slice_max(gamma, n = 3, with_ties = FALSE) %>%
  ungroup() %>%
  select(nombre, gamma, titulo) %>%
  print(n = Inf)

# ¿Cuántos artículos domina cada tópico?
grafica_conteo <- topico_dominante %>%
  count(nombre) %>%
  ggplot(aes(x = n, y = fct_reorder(nombre, n), fill = nombre)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = n), hjust = -0.3) +
  scale_fill_manual(values = paleta_topicos) +
  labs(title = "Número de artículos según su tópico dominante",
       x = "Artículos", y = NULL) +
  theme_minimal()

grafica_conteo

ggsave("graficas/03_articulos_por_topico.png", grafica_conteo,
       width = 8, height = 5, dpi = 300, bg = "white")

# ¿Qué tan "puros" son los artículos? Si el gamma máximo es cercano a 1, el
# artículo trata de un solo tema; si es cercano a 0.5 o menos, mezcla temas.
grafica_pureza <- topico_dominante %>%
  ggplot(aes(x = gamma)) +
  geom_histogram(binwidth = 0.05, fill = "#1E4C7D", color = "white") +
  labs(title = "La mayoría de los artículos se concentra en un solo tópico",
       subtitle = "Gamma del tópico dominante en cada artículo",
       x = "gamma máximo", y = "Artículos") +
  theme_minimal()

grafica_pureza

ggsave("graficas/04_pureza_articulos.png", grafica_pureza,
       width = 8, height = 5, dpi = 300, bg = "white")

# Mapa de calor con los 15 artículos más recientes: cada fila suma 1
grafica_calor <- gamma %>%
  filter(id %in% (articulos %>% slice_max(fecha, n = 15) %>% pull(id))) %>%
  mutate(titulo = str_trunc(titulo, 55)) %>%
  ggplot(aes(x = nombre, y = fct_reorder(titulo, fecha), fill = gamma)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "#F4F6F8", high = "#1E4C7D") +
  labs(title = "Composición de tópicos de los 15 artículos más recientes",
       x = NULL, y = NULL, fill = "gamma") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 35, hjust = 1))

grafica_calor

ggsave("graficas/05_mapa_calor_recientes.png", grafica_calor,
       width = 11, height = 7, dpi = 300, bg = "white")

# Parte 8. Tópicos a lo largo del tiempo ----

# Sumamos los gamma de cada año y los convertimos en proporción. Es como
# preguntar: de lo que se escribió ese año, ¿qué parte fue de cada tema?
topicos_anio <- gamma %>%
  group_by(anio, nombre) %>%
  summarise(gamma_total = sum(gamma), .groups = "drop") %>%
  group_by(anio) %>%
  mutate(proporcion = gamma_total / sum(gamma_total)) %>%
  ungroup()

grafica_tiempo <- topicos_anio %>%
  ggplot(aes(x = factor(anio), y = proporcion, fill = nombre)) +
  geom_col() +
  scale_fill_manual(values = paleta_topicos) +
  scale_y_continuous(labels = scales::percent) +
  labs(title = "Peso de cada tópico en la columna por año",
       subtitle = "Proporción de la suma de gamma de los artículos del año",
       x = NULL, y = NULL, fill = NULL) +
  theme_minimal()

grafica_tiempo

ggsave("graficas/06_topicos_por_anio.png", grafica_tiempo,
       width = 9, height = 5, dpi = 300, bg = "white")

# Parte 9. Comparar dos tópicos ----

# El modelo separó la tecnología en dos tópicos: el 4 (redes sociales,
# ciberseguridad, computación) y el 5 (ChatGPT y compañía en el trabajo y la
# escuela). ¿Qué palabras los distinguen? Usamos el logaritmo base 2 de la
# razón de sus beta: +1 significa que la palabra es el doble de probable en
# el tópico 5, y -1 que es el doble de probable en el tópico 4.
# Solo usamos palabras con cierto peso en ambos tópicos: el método VEM deja
# en casi cero la beta de las palabras ausentes de un tópico, y dividir entre
# un número casi nulo dispara la razón a valores sin sentido.
comparacion <- beta %>%
  filter(topic %in% c(4, 5)) %>%
  mutate(topic = str_c("topico_", topic)) %>%
  pivot_wider(names_from = topic, values_from = beta) %>%
  filter(topico_4 > 0.0005, topico_5 > 0.0005) %>%
  mutate(log_razon = log2(topico_5 / topico_4))

grafica_comparacion <- comparacion %>%
  slice_max(abs(log_razon), n = 20) %>%
  mutate(lado = if_else(log_razon > 0,
                        "05. Inteligencia artificial",
                        "04. Redes y tecnología digital")) %>%
  ggplot(aes(x = log_razon, y = fct_reorder(term, log_razon), fill = lado)) +
  geom_col() +
  scale_fill_manual(values = paleta_topicos[4:5]) +
  labs(title = "Palabras que separan los dos tópicos de tecnología",
       subtitle = "log2(beta tópico 5 / beta tópico 4)",
       x = "log2 de la razón de beta", y = NULL, fill = NULL) +
  theme_minimal()

grafica_comparacion

ggsave("graficas/07_comparacion_topicos.png", grafica_comparacion,
       width = 8, height = 6, dpi = 300, bg = "white")

# Parte 10. Guardar resultados ----

# Una fila por artículo con su tópico dominante y la proporción de cada
# tópico. Sirve para filtrar artículos por tema en Excel.
resultados <- gamma %>%
  select(id, nombre, gamma) %>%
  mutate(gamma = round(gamma, 3)) %>%
  pivot_wider(names_from = nombre, values_from = gamma) %>%
  left_join(topico_dominante %>%
              select(id, titulo, fecha, topico_dominante = nombre),
            by = "id") %>%
  relocate(id, titulo, fecha, topico_dominante) %>%
  arrange(desc(fecha))

write.xlsx(resultados, "topicos_por_articulo.xlsx")
