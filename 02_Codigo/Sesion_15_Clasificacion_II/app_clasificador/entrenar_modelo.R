# ============================================================
# Entrenar el clasificador de reseñas y guardarlo como RDS
# ------------------------------------------------------------
# Replica paso a paso el modelo de modelo_sencillo.R (receta de
# TF-IDF + regresión logística elastic net con glmnet) y guarda
# el flujo ajustado y sus métricas en la carpeta modelo/ para
# que app.R lo cargue sin volver a entrenar.
#
# Uso: Rscript entrenar_modelo.R   (desde app_clasificador/)
# ============================================================

# Librerías ----
library(tidyverse)
library(tidymodels)
library(textrecipes)
library(glmnet)

# Reproducibilidad ----
set.seed(2026)

# Ruta de los datos: resenas.csv vive en la carpeta de la sesión ----
ruta_datos <- if (file.exists("resenas.csv")) {
  "resenas.csv"
} else {
  file.path("..", "resenas.csv")
}
stopifnot(file.exists(ruta_datos))

# Cargar los datos ----
resenas <- read_csv(ruta_datos, show_col_types = FALSE) %>%
  mutate(sentimiento = factor(sentimiento,
                              levels = c("positiva", "negativa")))

# Lista de palabras vacías en español ----
stopwords_es <- tibble(palabras = tm::stopwords(kind = "es"))

# Partición ----
particion <- initial_split(resenas, prop = 0.7, strata = sentimiento)
entrenamiento <- training(particion)
prueba <- testing(particion)

# Receta (idéntica a modelo_sencillo.R) ----
receta <- recipe(sentimiento ~ texto, data = entrenamiento) %>%
  step_mutate(texto = str_to_lower(texto)) %>%
  step_mutate(texto = str_remove_all(texto, pattern = "\\d+")) %>%
  step_mutate(texto = str_replace_all(texto, c("á" = "a",
                                               "é" = "e",
                                               "í" = "i",
                                               "ó" = "o",
                                               "ú" = "u"))) %>%
  step_mutate(texto = str_replace_all(texto,
                                      pattern = "([[:alpha:]])\\1+",
                                      replacement = "\\1")) %>%
  step_mutate(texto = str_remove_all(texto, pattern = "[:punct:]")) %>%
  step_mutate(texto = str_squish(texto)) %>%
  step_tokenize(texto, token = "words") %>%
  step_stopwords(texto, custom_stopword_source = stopwords_es$palabras) %>%
  step_stem(texto, options = list(language = "spanish")) %>%
  step_tokenfilter(texto, min_times = 3, max_tokens = 500) %>%
  step_tfidf(texto)

# Modelo ----
modelo <- logistic_reg(penalty = 0.01, mixture = 0.5) %>%
  set_engine("glmnet") %>%
  set_mode("classification")

# Flujo de trabajo ----
flujo <- workflow() %>%
  add_recipe(receta) %>%
  add_model(modelo)

# Entrenamiento ----
ajuste <- fit(flujo, data = entrenamiento)

# Evaluación en el conjunto de prueba ----
predicciones <- augment(ajuste, new_data = prueba)

matriz_confusion <- predicciones %>%
  conf_mat(truth = sentimiento, estimate = .pred_class)

metricas <- predicciones %>%
  metrics(truth = sentimiento, estimate = .pred_class,
          .pred_positiva)

curva_roc <- predicciones %>%
  roc_curve(truth = sentimiento, .pred_positiva)

print(matriz_confusion)
print(metricas)

# Guardar todo lo que la app necesita ----
dir.create("modelo", showWarnings = FALSE)

write_rds(ajuste, "modelo/flujo_ajustado.rds")
write_rds(list(matriz_confusion = matriz_confusion,
               metricas = metricas,
               curva_roc = curva_roc,
               n_entrenamiento = nrow(entrenamiento),
               n_prueba = nrow(prueba),
               fecha = Sys.Date()),
          "modelo/metricas.rds")

# Modelo guardado en modelo/flujo_ajustado.rds
