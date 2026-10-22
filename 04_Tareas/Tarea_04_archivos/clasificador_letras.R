# =============================================================================
# ¿Se puede distinguir la década de una canción a partir de su letra?
# Ensayos de clasificación sobre corpus_canciones_es.xlsx con tidymodels
#
# Objetivo binario: decada (2000s vs 2020s), definida por el año de la lista
# Hot Latin Songs en la que apareció la canción. Clase positiva: 2020s.
#
# Ensayos:
#   A. Logit con rasgos de estilo (sin vocabulario) - línea base
#   B. Lasso (glmnet) sobre TF-IDF de unigramas
#   C. Lasso (glmnet) sobre TF-IDF de unigramas + bigramas
#   D. Bosque aleatorio (ranger) sobre TF-IDF de unigramas
#   E. Naive Bayes sobre presencia/ausencia de unigramas
#
# Validación: 10 pliegues estratificados (aleatorios) y, como prueba de
# robustez, 10 pliegues agrupados por artista (ninguna canción de un artista
# del pliegue de prueba aparece en el de entrenamiento).
#
# Ensayo adicional: género de Billboard (4 clases) con lasso multinomial.
#
# Todo el flujo es secuencial: no se definen funciones auxiliares. Las
# recetas de textrecipes garantizan que el vocabulario y los pesos TF-IDF se
# calculen solo con el pliegue de entrenamiento.
# Salidas en resultados/: tablas CSV, objetos RDS y gráficas PNG.
# =============================================================================

library(tidyverse)
library(readxl)
library(tidytext)
library(stopwords)
library(tidymodels)
library(textrecipes)
library(discrim)

tidymodels_prefer()
set.seed(2026)

# -----------------------------------------------------------------------------
# 1. Carga y limpieza
# -----------------------------------------------------------------------------
ruta_corpus <- "corpus_canciones_es.xlsx"
stopifnot(file.exists(ruta_corpus))

canciones <- read_excel(ruta_corpus, sheet = "corpus") %>%
  filter(!is.na(letra)) %>%
  mutate(
    decada = factor(decada, levels = c("2020s", "2000s")),
    letra_limpia = letra %>%
      str_to_lower() %>%
      str_replace_all("\\[[^\\]]*\\]", " ") %>%   # etiquetas tipo [Coro]
      str_replace_all("[0-9]+", " ")
  ) %>%
  select(id_cancion, titulo, artista_principal, anio_lista, decada,
         genero_billboard, n_palabras, letra, letra_limpia)

print(paste("Canciones con letra:", nrow(canciones)))
print(table(canciones$decada))

# -----------------------------------------------------------------------------
# 2. Rasgos de estilo con tidytext (ensayo A): solo la forma, no el vocabulario
# -----------------------------------------------------------------------------
stop_es <- stopwords("es", source = "snowball")

# Palabras en inglés frecuentes como indicador grueso de anglicismos
anglicismos <- c("yeah", "baby", "oh", "uh", "yo", "money", "love", "party",
                 "bitch", "shit", "fuck", "okay", "ok", "wow", "yes", "like",
                 "boy", "girl", "night", "club", "flow")

rasgos_estilo <- canciones %>%
  select(id_cancion, letra_limpia) %>%
  unnest_tokens(palabra, letra_limpia) %>%
  filter(str_length(palabra) >= 2) %>%
  group_by(id_cancion) %>%
  summarise(
    n_tokens = n(),
    n_tipos = n_distinct(palabra),
    riqueza_lexica = n_tipos / n_tokens,
    prop_stopwords = mean(palabra %in% stop_es),
    prop_anglicismos = mean(palabra %in% anglicismos),
    long_media_palabra = mean(str_length(palabra)),
    .groups = "drop"
  )

# Proporción de líneas repetidas (coros): se tokeniza por línea con tidytext
rasgos_lineas <- canciones %>%
  select(id_cancion, letra) %>%
  unnest_tokens(linea, letra, token = "lines", to_lower = FALSE) %>%
  mutate(linea = str_squish(linea)) %>%
  filter(linea != "") %>%
  group_by(id_cancion) %>%
  summarise(n_lineas = n(),
            prop_lineas_repetidas = 1 - n_distinct(linea) / n_lineas,
            .groups = "drop")

canciones <- canciones %>%
  left_join(rasgos_estilo, by = "id_cancion") %>%
  left_join(rasgos_lineas, by = "id_cancion")

# -----------------------------------------------------------------------------
# 3. Esquemas de validación cruzada con rsample
# -----------------------------------------------------------------------------
pliegues_aleatorios <- vfold_cv(canciones, v = 10, strata = decada)

# Cada artista cae completo en un solo pliegue; balance por observaciones
pliegues_artista <- group_vfold_cv(canciones, group = artista_principal,
                                   v = 10, balance = "observations")

# -----------------------------------------------------------------------------
# 4. Recetas: cómo se representa la letra en cada ensayo
# -----------------------------------------------------------------------------
receta_estilo <- recipe(decada ~ n_tokens + riqueza_lexica + prop_stopwords +
                          prop_anglicismos + long_media_palabra + n_lineas +
                          prop_lineas_repetidas,
                        data = canciones) %>%
  step_normalize(all_numeric_predictors())

# step_tokenfilter: términos que aparecen al menos 5 veces en el corpus de
# entrenamiento, máximo 3,000 ordenados por frecuencia
receta_unigramas <- recipe(decada ~ letra_limpia, data = canciones) %>%
  step_tokenize(letra_limpia) %>%
  step_stopwords(letra_limpia, language = "es") %>%
  step_tokenfilter(letra_limpia, min_times = 5, max_tokens = 3000) %>%
  step_tfidf(letra_limpia)

receta_bigramas <- recipe(decada ~ letra_limpia, data = canciones) %>%
  step_tokenize(letra_limpia) %>%
  step_stopwords(letra_limpia, language = "es") %>%
  step_ngram(letra_limpia, num_tokens = 2, min_num_tokens = 1) %>%
  step_tokenfilter(letra_limpia, min_times = 5, max_tokens = 5000) %>%
  step_tfidf(letra_limpia)

# Naive Bayes: presencia/ausencia de los 1,000 términos más comunes. Cada
# término se convierte a factor para que el motor use Bernoulli y no Gauss
receta_presencia <- recipe(decada ~ letra_limpia, data = canciones) %>%
  step_tokenize(letra_limpia) %>%
  step_stopwords(letra_limpia, language = "es") %>%
  step_tokenfilter(letra_limpia, min_times = 5, max_tokens = 1000) %>%
  step_tf(letra_limpia, weight_scheme = "binary") %>%
  step_mutate_at(all_numeric_predictors(),
                 fn = ~ factor(as.numeric(.x), levels = c(0, 1)))

# -----------------------------------------------------------------------------
# 5. Modelos con parsnip
# -----------------------------------------------------------------------------
modelo_logit <- logistic_reg() %>%
  set_engine("glm")

modelo_lasso <- logistic_reg(penalty = tune(), mixture = 1) %>%
  set_engine("glmnet")

modelo_bosque <- rand_forest(trees = 500) %>%
  set_engine("ranger", seed = 2026) %>%
  set_mode("classification")

# Laplace = 1 suaviza las probabilidades de términos ausentes en una clase
modelo_bayes <- naive_Bayes(Laplace = 1) %>%
  set_engine("naivebayes", usekernel = FALSE) %>%
  set_mode("classification")

# -----------------------------------------------------------------------------
# 6. Conjunto de flujos de trabajo (workflow set): un flujo por ensayo
# -----------------------------------------------------------------------------
ensayos <- workflow_set(
  preproc = list(
    "A. Logit de estilo (sin vocabulario)" = receta_estilo,
    "B. Lasso TF-IDF unigramas" = receta_unigramas,
    "C. Lasso TF-IDF unigramas + bigramas" = receta_bigramas,
    "D. Bosque aleatorio TF-IDF" = receta_unigramas,
    "E. Naive Bayes presencia de términos" = receta_presencia
  ),
  models = list(
    "A. Logit de estilo (sin vocabulario)" = modelo_logit,
    "B. Lasso TF-IDF unigramas" = modelo_lasso,
    "C. Lasso TF-IDF unigramas + bigramas" = modelo_lasso,
    "D. Bosque aleatorio TF-IDF" = modelo_bosque,
    "E. Naive Bayes presencia de términos" = modelo_bayes
  ),
  cross = FALSE
) %>%
  mutate(wflow_id = str_remove(wflow_id, "_.*$"))

# Malla de penalizaciones para los lasso (los demás flujos no tienen
# parámetros que afinar, así que workflow_map los corre con fit_resamples)
malla_lasso <- grid_regular(penalty(range = c(-4, -1)), levels = 20)

control_ensayos <- control_grid(save_pred = TRUE, verbose = FALSE)

# -----------------------------------------------------------------------------
# 7. Correr los cinco ensayos en los dos esquemas de validación
# -----------------------------------------------------------------------------
print("Corriendo validación con pliegues aleatorios...")
resultados_aleatorios <- ensayos %>%
  workflow_map("tune_grid", resamples = pliegues_aleatorios,
               grid = malla_lasso, control = control_ensayos,
               metrics = metric_set(roc_auc), seed = 2026)

print("Corriendo validación con pliegues por artista...")
resultados_artista <- ensayos %>%
  workflow_map("tune_grid", resamples = pliegues_artista,
               grid = malla_lasso, control = control_ensayos,
               metrics = metric_set(roc_auc), seed = 2026)

# -----------------------------------------------------------------------------
# 8. Predicciones fuera de muestra. Para los lasso se conserva la penalización
#    con mejor AUC promedio (rank_results la identifica); los demás flujos
#    tienen una sola configuración.
# -----------------------------------------------------------------------------
mejores_configs <- bind_rows(
  rank_results(resultados_aleatorios, rank_metric = "roc_auc",
               select_best = TRUE) %>%
    mutate(esquema = "Pliegues aleatorios"),
  rank_results(resultados_artista, rank_metric = "roc_auc",
               select_best = TRUE) %>%
    mutate(esquema = "Pliegues por artista")
) %>%
  select(esquema, ensayo = wflow_id, .config)

predicciones <- bind_rows(
  collect_predictions(resultados_aleatorios, summarize = FALSE) %>%
    mutate(esquema = "Pliegues aleatorios"),
  collect_predictions(resultados_artista, summarize = FALSE) %>%
    mutate(esquema = "Pliegues por artista")
) %>%
  rename(ensayo = wflow_id) %>%
  inner_join(mejores_configs, by = c("esquema", "ensayo", ".config")) %>%
  mutate(id_cancion = canciones$id_cancion[.row],
         pred_clase = factor(if_else(.pred_2020s >= 0.5, "2020s", "2000s"),
                             levels = c("2020s", "2000s"))) %>%
  select(esquema, ensayo, pliegue = id, id_cancion, decada,
         prob_2020s = .pred_2020s, pred_clase)

write_csv(predicciones, "resultados/predicciones_oof.csv")

# -----------------------------------------------------------------------------
# 9. Métricas por ensayo y esquema (clase positiva = 2020s, primer nivel)
# -----------------------------------------------------------------------------
conjunto_metricas <- metric_set(accuracy, bal_accuracy, sens, spec,
                                precision, f_meas, kap)

metricas <- predicciones %>%
  group_by(esquema, ensayo) %>%
  conjunto_metricas(truth = decada, estimate = pred_clase) %>%
  bind_rows(
    predicciones %>%
      group_by(esquema, ensayo) %>%
      roc_auc(truth = decada, prob_2020s)
  ) %>%
  select(esquema, ensayo, metrica = .metric, valor = .estimate) %>%
  pivot_wider(names_from = metrica, values_from = valor) %>%
  arrange(esquema, desc(roc_auc))

print(as.data.frame(metricas))
write_csv(metricas, "resultados/metricas_ensayos.csv")

# Tasa de la clase mayoritaria como referencia
tasa_mayoritaria <- mean(canciones$decada == "2020s")
print(paste("Exactitud de predecir siempre 2020s:", round(tasa_mayoritaria, 3)))

# Curvas ROC de todos los ensayos
curvas_roc <- predicciones %>%
  group_by(esquema, ensayo) %>%
  roc_curve(truth = decada, prob_2020s)
write_csv(curvas_roc, "resultados/curvas_roc.csv")

# -----------------------------------------------------------------------------
# 10. Modelo más prometedor: el de mayor AUC bajo pliegues por artista
#     (el esquema más exigente). Matriz de confusión y gráficas.
# -----------------------------------------------------------------------------
mejor <- metricas %>%
  filter(esquema == "Pliegues por artista") %>%
  slice_max(roc_auc, n = 1) %>%
  pull(ensayo)
print(paste("Modelo más prometedor:", mejor))

matriz_confusion <- predicciones %>%
  filter(ensayo == mejor) %>%
  count(esquema, decada, pred_clase)
write_csv(matriz_confusion, "resultados/matriz_confusion_mejor.csv")

paleta <- c("A. Logit de estilo (sin vocabulario)" = "#999999",
            "B. Lasso TF-IDF unigramas" = "#1E4C7D",
            "C. Lasso TF-IDF unigramas + bigramas" = "#4C9BD6",
            "D. Bosque aleatorio TF-IDF" = "#1A7A3A",
            "E. Naive Bayes presencia de términos" = "#C0392B")

grafica_roc <- curvas_roc %>%
  ggplot(aes(x = 1 - specificity, y = sensitivity, colour = ensayo)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed",
              colour = "grey60") +
  geom_path(linewidth = 0.9) +
  facet_wrap(~ esquema) +
  scale_colour_manual(values = paleta) +
  coord_equal() +
  labs(x = "1 - Especificidad (falsos positivos)",
       y = "Sensibilidad (verdaderos positivos)",
       colour = NULL,
       title = "Curvas ROC: ¿la letra delata la década?",
       subtitle = "Clase positiva: 2020s. Predicciones fuera de muestra, 10 pliegues") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", legend.direction = "vertical")

ggsave("resultados/roc_todos_ensayos.png", grafica_roc,
       width = 10, height = 7, dpi = 300, bg = "white")

etiquetas_mejor <- metricas %>%
  filter(ensayo == mejor) %>%
  mutate(esquema_auc = paste0(esquema, "  (AUC = ",
                              sprintf("%.3f", roc_auc), ")")) %>%
  select(esquema, esquema_auc)

grafica_roc_mejor <- curvas_roc %>%
  filter(ensayo == mejor) %>%
  left_join(etiquetas_mejor, by = "esquema") %>%
  ggplot(aes(x = 1 - specificity, y = sensitivity, colour = esquema_auc)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed",
              colour = "grey60") +
  geom_path(linewidth = 1.1) +
  scale_colour_manual(values = c("#1E4C7D", "#C0392B")) +
  coord_equal() +
  labs(x = "1 - Especificidad", y = "Sensibilidad", colour = NULL,
       title = paste("Curva ROC del modelo más prometedor:", mejor)) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom", legend.direction = "vertical")

ggsave("resultados/roc_mejor_modelo.png", grafica_roc_mejor,
       width = 7, height = 7.5, dpi = 300, bg = "white")

# -----------------------------------------------------------------------------
# 11. Interpretación: términos que más separan décadas. Se ajusta el lasso de
#     unigramas sobre toda la base con la penalización elegida por artista.
# -----------------------------------------------------------------------------
penalidad_lasso <- resultados_artista %>%
  extract_workflow_set_result("B. Lasso TF-IDF unigramas") %>%
  select_best(metric = "roc_auc")
print(penalidad_lasso)

lasso_total <- workflow() %>%
  add_recipe(receta_unigramas) %>%
  add_model(modelo_lasso) %>%
  finalize_workflow(penalidad_lasso) %>%
  fit(data = canciones)

# En parsnip + glmnet, un coeficiente positivo empuja hacia el segundo nivel
# del factor (2000s); se invierte el signo para que positivo = 2020s
coeficientes <- lasso_total %>%
  extract_fit_parsnip() %>%
  tidy() %>%
  filter(term != "(Intercept)", estimate != 0) %>%
  transmute(termino = str_remove(term, "^tfidf_letra_limpia_"),
            coef = -estimate,
            decada_asociada = if_else(coef > 0, "2020s", "2000s")) %>%
  arrange(desc(abs(coef)))

print(head(coeficientes, 15))
write_csv(coeficientes, "resultados/terminos_discriminantes.csv")

grafica_terminos <- coeficientes %>%
  group_by(decada_asociada) %>%
  slice_max(abs(coef), n = 20) %>%
  ungroup() %>%
  mutate(termino = fct_reorder(termino, coef)) %>%
  ggplot(aes(x = coef, y = termino, fill = decada_asociada)) +
  geom_col() +
  scale_fill_manual(values = c("2000s" = "#C0392B", "2020s" = "#1E4C7D")) +
  labs(x = "Coeficiente lasso (positivo = más 2020s)", y = NULL,
       fill = "Década asociada",
       title = "Los 20 términos más discriminantes por década") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom")

ggsave("resultados/terminos_discriminantes.png", grafica_terminos,
       width = 8, height = 9, dpi = 300, bg = "white")

# -----------------------------------------------------------------------------
# 12. Ensayo adicional: ¿la letra distingue el género de Billboard?
#     Solo las canciones con género; lasso multinomial, pliegues por artista
# -----------------------------------------------------------------------------
con_genero <- canciones %>%
  filter(!is.na(genero_billboard)) %>%
  mutate(genero = factor(genero_billboard))
print(table(con_genero$genero))

pliegues_genero <- group_vfold_cv(con_genero, group = artista_principal,
                                  v = 10, balance = "observations")

receta_genero <- recipe(genero ~ letra_limpia, data = con_genero) %>%
  step_tokenize(letra_limpia) %>%
  step_stopwords(letra_limpia, language = "es") %>%
  step_tokenfilter(letra_limpia, min_times = 5, max_tokens = 2000) %>%
  step_tfidf(letra_limpia)

modelo_multinomial <- multinom_reg(penalty = tune(), mixture = 1) %>%
  set_engine("glmnet")

flujo_genero <- workflow() %>%
  add_recipe(receta_genero) %>%
  add_model(modelo_multinomial)

ajuste_genero <- flujo_genero %>%
  tune_grid(resamples = pliegues_genero, grid = malla_lasso,
            control = control_ensayos,
            metrics = metric_set(roc_auc, accuracy))

mejor_penalidad_genero <- select_best(ajuste_genero, metric = "roc_auc")

oof_genero <- collect_predictions(ajuste_genero,
                                  parameters = mejor_penalidad_genero) %>%
  mutate(id_cancion = con_genero$id_cancion[.row]) %>%
  rename(pred = .pred_class) %>%
  select(id_cancion, genero, pred, starts_with(".pred_")) %>%
  rename_with(~ str_replace_all(str_replace(.x, "^\\.pred_", "p_"), " ", "_"))

write_csv(oof_genero, "resultados/predicciones_genero.csv")

metricas_genero <- bind_rows(
  oof_genero %>% accuracy(truth = genero, estimate = pred),
  oof_genero %>% bal_accuracy(truth = genero, estimate = pred),
  oof_genero %>% f_meas(truth = genero, estimate = pred),
  oof_genero %>% roc_auc(truth = genero, p_Latin_Pop, p_Latin_Rhythm,
                         p_Regional_Mexican, p_Tropical)
) %>%
  select(metrica = .metric, valor = .estimate)
print(as.data.frame(metricas_genero))
write_csv(metricas_genero, "resultados/metricas_genero.csv")

matriz_genero <- oof_genero %>% count(genero, pred)
write_csv(matriz_genero, "resultados/matriz_confusion_genero.csv")
print(paste("Clase mayoritaria de género:",
            round(max(prop.table(table(con_genero$genero))), 3)))

# -----------------------------------------------------------------------------
# 13. Guardar objetos para el reporte
# -----------------------------------------------------------------------------
saveRDS(list(canciones = canciones %>% select(-letra, -letra_limpia),
             metricas = metricas,
             mejor = mejor,
             matriz_confusion = matriz_confusion,
             coeficientes = coeficientes,
             tasa_mayoritaria = tasa_mayoritaria,
             metricas_genero = metricas_genero,
             matriz_genero = matriz_genero,
             n_genero = nrow(con_genero)),
        "resultados/resumen_modelos.rds")
print("Listo: resultados guardados en resultados/")
