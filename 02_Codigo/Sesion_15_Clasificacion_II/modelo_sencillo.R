
# Librerías ----
library(tidyverse)
library(tidytext)
library(tidymodels)
library(textrecipes)
library(glmnet)
library(probably)

# Cargar los datos ---
resenas <- read_csv("resenas.csv") |> 
  mutate(sentimiento = factor(sentimiento, 
                              levels = c("positiva",
                                         "negativa")))

# Explorar los datos 
resenas |> 
  group_by(sentimiento) |> 
  summarise(n = n()) |> 
  ungroup() |> 
  mutate(pp = 100*(n/sum(n)))

# Preprocesamiento ----
stopwords_es <- tibble(palabras = tm::stopwords(kind = "es"))

resenas_limpio <- resenas |> 
  select(id, texto, sentimiento) |> 
  mutate(texto = str_to_lower(texto)) |> 
  mutate(texto = str_remove_all(texto, pattern = "\\d+")) |> 
  mutate(texto = str_replace_all(texto, c("á" = "a", 
                                          "é" = "e", 
                                          "í" = "i", 
                                          "ó" = "o", 
                                          "ú" = "u"))) |> 
  mutate(texto = str_replace_all(texto, 
                                 pattern = "([[:alpha:]])\\1+", 
                                 replacement = "\\1")) |> 
  mutate(texto = str_remove_all(texto, pattern = "[:punct:]")) |> 
  mutate(texto = str_squish(texto)) 

#conteo de palabras por sentimiento
resenas_limpio %>% 
  select(id, texto, sentimiento) %>% #para quedarnos solo con esas 3 cols
  unnest_tokens(output = "palabras", 
                input = texto,     
                token = "words",
                to_lower = T ) %>% 
  group_by(sentimiento, palabras) %>% 
  count() |> 
  anti_join(stopwords_es) |> 
  arrange(sentimiento, -n) |> 
  group_by(sentimiento) |> 
  mutate(ranking = rank(-n)) |> 
  filter(ranking <= 10) |> 
  ggplot(aes(x = interaction(palabras, sentimiento), y = n, fill = sentimiento)) + 
  geom_col() + 
  coord_flip()

# Particion ----
particion <- initial_split(resenas, prop = 0.7, strata = sentimiento)
entrenamiento <- training(particion)
prueba <- testing(particion)

# Armar la receta ----
receta <- recipe(sentimiento ~ texto, data = entrenamiento) |>  
  step_mutate(texto = str_to_lower(texto)) |> 
  step_mutate(texto = str_remove_all(texto, pattern = "\\d+")) |> 
  step_mutate(texto = str_replace_all(texto, c("á" = "a", 
                                          "é" = "e", 
                                          "í" = "i", 
                                          "ó" = "o", 
                                          "ú" = "u"))) |> 
  step_mutate(texto = str_replace_all(texto, 
                                 pattern = "([[:alpha:]])\\1+", 
                                 replacement = "\\1")) |> 
  step_mutate(texto = str_remove_all(texto, pattern = "[:punct:]")) |> 
  step_mutate(texto = str_squish(texto)) |> 
  step_tokenize(texto, token = "words") |> 
  step_stopwords(texto, custom_stopword_source = stopwords_es$palabras) |> 
  step_stem(texto, options = list(language = "spanish")) |> 
  step_tokenfilter(texto, min_times = 3, max_tokens = 500) |> 
  step_tfidf(texto)

# Modelo ----
modelo <- logistic_reg(penalty = 0.01, mixture = 0.5) |> 
  set_engine("glmnet") |> 
  set_mode("classification")

# Workflow ----
flujo <- workflow() |> 
  add_recipe(receta) |> 
  add_model(modelo)

# Entrenamiento ----
ajuste <- fit(flujo, data = entrenamiento)

# Predicciones ----
predicciones <- augment(ajuste, new_data = prueba)

predicciones |> 
  conf_mat(truth = sentimiento, estimate = .pred_class)


predicciones |> 
  roc_curve(truth = sentimiento, .pred_positiva) |> 
  autoplot()

# PROMPT: Dado el modelo que construimos en @modelo_sencillo.R , generame una aplicación que, si yo le paso una reseña, me la clasifique en "positiva" o "negativa". Programa la aplicación en shiny y avísame cuando esté terminada


