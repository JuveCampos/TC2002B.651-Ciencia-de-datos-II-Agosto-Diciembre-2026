# ============================================================
# Clasificador de reseñas · Sesión 15 · Ciencia de Datos II
# ------------------------------------------------------------
# App Shiny que recibe una reseña escrita por la persona usuaria
# y la clasifica como "positiva" o "negativa" con el modelo de
# modelo_sencillo.R (TF-IDF + regresión logística elastic net).
#
# Correr con: shiny::runApp("app_clasificador")
# Si no existe modelo/flujo_ajustado.rds, la app entrena el
# modelo sola con entrenar_modelo.R (tarda menos de un minuto).
# ============================================================

# Librerías ----
library(shiny)
library(tidyverse)
library(tidymodels)
library(textrecipes)
library(glmnet)
library(SnowballC)

# Cargar (o entrenar) el modelo ----
if (!file.exists("modelo/flujo_ajustado.rds")) {
  source("entrenar_modelo.R", local = new.env())
}

flujo <- read_rds("modelo/flujo_ajustado.rds")
info_modelo <- read_rds("modelo/metricas.rds")

# Objetos derivados del flujo que se reutilizan en cada predicción ----
receta_lista <- extract_recipe(flujo)
ajuste_glmnet <- extract_fit_parsnip(flujo)$fit
penalizacion <- extract_fit_parsnip(flujo)$spec$args$penalty %>%
  rlang::eval_tidy()

# Coeficientes del modelo. glmnet modela el segundo nivel del factor
# ("negativa"), así que se invierte el signo para que un aporte
# positivo empuje hacia "positiva", que es lo que se muestra en pantalla.
coeficientes <- coef(ajuste_glmnet, s = penalizacion) %>%
  as.matrix() %>%
  as_tibble(rownames = "termino") %>%
  rename(coef = 2) %>%
  mutate(coef = -coef)

intercepto <- coeficientes %>%
  filter(termino == "(Intercept)") %>%
  pull(coef)

# Lista de palabras vacías usada en la receta (misma fuente que el modelo)
stopwords_es <- tm::stopwords(kind = "es")

# Métricas para el pie de página ----
exactitud <- info_modelo$metricas %>%
  filter(.metric == "accuracy") %>%
  pull(.estimate)
auc <- info_modelo$metricas %>%
  filter(.metric == "roc_auc") %>%
  pull(.estimate)

# Reseñas de ejemplo para probar la app sin escribir ----
ejemplos <- c(
  "Pedimos el menú del día. Los tacos estaban deliciosos, la mesera fue muy amable y el lugar estaba limpísimo. Volveremos seguro.",
  "La habitación olía a humedad, el aire acondicionado no servía y en recepción nos ignoraron. Ni de chiste lo recomiendo.",
  "El plomero llegó puntual, explicó el problema con calma y cobró lo acordado. Quedó todo funcionando."
)

# ------------------------------------------------------------
# Interfaz
# ------------------------------------------------------------
ui <- fluidPage(
  title = "Clasificador de reseñas",
  tags$head(
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(
      rel = "stylesheet",
      href = paste0(
        "https://fonts.googleapis.com/css2?",
        "family=Fraunces:opsz,wght@9..144,400;9..144,600;9..144,700",
        "&family=Newsreader:ital,wght@0,400;0,500;1,400",
        "&family=IBM+Plex+Mono:wght@400;500&display=swap"
      )
    ),
    tags$link(rel = "stylesheet", href = "estilos.css")
  ),

  div(class = "cabecera",
      p(class = "sobretitulo", "Ciencia de Datos II · Sesión 15"),
      h1("Clasificador de reseñas"),
      p(class = "bajada",
        "Escribe una reseña de un restaurante, un hotel o un servicio y el ",
        "modelo dirá si suena positiva o negativa. También muestra qué ",
        "palabras inclinaron la balanza.")
  ),

  div(class = "tablero",

      # Columna izquierda: entrada ----
      div(class = "columna columna-entrada",
          p(class = "etiqueta", "Tu reseña"),
          textAreaInput(
            inputId = "texto",
            label = NULL,
            placeholder = "Por ejemplo: la carne venía cruda y la mesera se equivocó dos veces con la orden...",
            rows = 8,
            width = "100%"
          ),
          div(class = "fila-botones",
              actionButton("clasificar", "Clasificar reseña",
                           class = "boton-principal"),
              actionButton("limpiar", "Limpiar", class = "boton-secundario")
          ),
          p(class = "etiqueta etiqueta-ejemplos", "O prueba con un ejemplo"),
          div(class = "ejemplos",
              actionLink("ejemplo_1", ejemplos[1], class = "ejemplo"),
              actionLink("ejemplo_2", ejemplos[2], class = "ejemplo"),
              actionLink("ejemplo_3", ejemplos[3], class = "ejemplo")
          )
      ),

      # Columna derecha: resultado ----
      div(class = "columna columna-resultado",
          p(class = "etiqueta", "Veredicto del modelo"),
          uiOutput("veredicto"),
          uiOutput("aportes")
      )
  ),

  div(class = "pie",
      p(
        "Regresión logística con penalización elastic net (glmnet) sobre ",
        "TF-IDF de palabras lematizadas. Entrenado con ",
        format(info_modelo$n_entrenamiento, big.mark = ","),
        " reseñas; en las ",
        format(info_modelo$n_prueba, big.mark = ","),
        " reseñas de prueba acierta el ",
        sprintf("%.1f%%", 100 * exactitud),
        paste0(" de las veces (AUC = ", sprintf("%.3f", auc), ").")
      ),
      p("Mismo modelo que modelo_sencillo.R. Tecnológico de Monterrey, 2026.")
  )
)

# ------------------------------------------------------------
# Servidor
# ------------------------------------------------------------
server <- function(input, output, session) {

  # Botones de ejemplo y limpiar ----
  observeEvent(input$ejemplo_1, updateTextAreaInput(session, "texto", value = ejemplos[1]))
  observeEvent(input$ejemplo_2, updateTextAreaInput(session, "texto", value = ejemplos[2]))
  observeEvent(input$ejemplo_3, updateTextAreaInput(session, "texto", value = ejemplos[3]))
  observeEvent(input$limpiar, updateTextAreaInput(session, "texto", value = ""))

  # Predicción: solo se recalcula al pulsar el botón ----
  resultado <- eventReactive(input$clasificar, {
    texto <- str_squish(input$texto)
    if (nchar(texto) == 0) return(NULL)

    nuevo <- tibble(texto = texto)

    # Probabilidades y clase según el flujo ajustado
    probabilidades <- predict(flujo, nuevo, type = "prob")
    clase <- predict(flujo, nuevo, type = "class") %>%
      pull(.pred_class) %>%
      as.character()

    # Aporte por término: TF-IDF del texto nuevo por coeficiente.
    # La suma de aportes más el intercepto reconstruye el logit.
    matriz <- bake(receta_lista, nuevo)
    aportes_terminos <- matriz %>%
      select(starts_with("tfidf_texto_")) %>%
      pivot_longer(everything(), names_to = "termino", values_to = "tfidf") %>%
      filter(tfidf > 0) %>%
      inner_join(coeficientes, by = "termino") %>%
      mutate(raiz = str_remove(termino, "^tfidf_texto_"),
             aporte = tfidf * coef)

    # Reconstruir qué palabra original corresponde a cada raíz, aplicando
    # la misma limpieza que la receta: minúsculas, sin dígitos, sin
    # acentos, sin letras repetidas, sin puntuación, sin palabras vacías.
    palabras <- texto %>%
      str_to_lower() %>%
      str_remove_all("\\d+") %>%
      str_replace_all(c("á" = "a", "é" = "e", "í" = "i",
                        "ó" = "o", "ú" = "u")) %>%
      str_replace_all("([[:alpha:]])\\1+", "\\1") %>%
      str_remove_all("[:punct:]") %>%
      str_squish() %>%
      str_split("\\s+") %>%
      pluck(1)

    # Se quitan vacíos y palabras vacías (scales también exporta discard,
    # por eso se filtra con indexación simple en vez de purrr::discard)
    palabras <- palabras[palabras != "" & !palabras %in% stopwords_es] %>%
      unique()

    mapa_raices <- tibble(palabra = palabras) %>%
      mutate(raiz = wordStem(palabra, language = "spanish")) %>%
      group_by(raiz) %>%
      summarise(palabra = paste(palabra, collapse = ", "), .groups = "drop")

    aportes_palabras <- aportes_terminos %>%
      left_join(mapa_raices, by = "raiz") %>%
      mutate(palabra = coalesce(palabra, raiz)) %>%
      select(palabra, raiz, tfidf, coef, aporte) %>%
      arrange(desc(abs(aporte)))

    fuera_vocabulario <- mapa_raices %>%
      filter(!raiz %in% aportes_terminos$raiz) %>%
      pull(palabra)

    list(
      clase = clase,
      p_positiva = probabilidades$.pred_positiva,
      p_negativa = probabilidades$.pred_negativa,
      aportes = aportes_palabras,
      fuera = fuera_vocabulario,
      logit = intercepto + sum(aportes_palabras$aporte)
    )
  }, ignoreNULL = TRUE)

  # Veredicto grande con la probabilidad ----
  output$veredicto <- renderUI({
    if (input$clasificar == 0) {
      return(div(class = "veredicto veredicto-vacio",
                 p("Aquí aparecerá el resultado cuando clasifiques una reseña.")))
    }
    r <- resultado()
    if (is.null(r)) {
      return(div(class = "veredicto veredicto-vacio",
                 p("Escribe una reseña antes de clasificar.")))
    }

    es_positiva <- r$clase == "positiva"
    clase_css <- if (es_positiva) "positiva" else "negativa"
    p_clase <- if (es_positiva) r$p_positiva else r$p_negativa
    pct_pos <- round(100 * r$p_positiva)

    div(class = paste("veredicto", clase_css),
        p(class = "clase", str_to_upper(r$clase)),
        p(class = "probabilidad",
          sprintf("El modelo le asigna %.0f%% de probabilidad a esta clase.",
                  100 * p_clase)),
        # Barra de probabilidad: izquierda negativa, derecha positiva
        div(class = "barra",
            div(class = "barra-negativa", style = sprintf("width:%d%%", 100 - pct_pos)),
            div(class = "barra-positiva", style = sprintf("width:%d%%", pct_pos)),
            div(class = "barra-umbral")
        ),
        div(class = "barra-leyenda",
            span(sprintf("negativa %d%%", 100 - pct_pos)),
            span(sprintf("positiva %d%%", pct_pos))
        )
    )
  })

  # Tabla de palabras que inclinaron la balanza ----
  output$aportes <- renderUI({
    if (input$clasificar == 0) return(NULL)
    r <- resultado()
    if (is.null(r)) return(NULL)

    con_peso <- r$aportes %>% filter(aporte != 0)
    sin_peso <- r$aportes %>% filter(aporte == 0) %>% pull(palabra)

    filas <- if (nrow(con_peso) == 0) {
      tags$tr(tags$td(colspan = 2, class = "vacio",
                      "Ninguna palabra del texto tiene peso en el modelo; ",
                      "el veredicto sale solo del intercepto."))
    } else {
      # Las barras se escalan respecto al aporte más grande en valor absoluto
      escala <- max(abs(con_peso$aporte))
      pmap(con_peso, function(palabra, raiz, tfidf, coef, aporte) {
        hacia <- if (aporte > 0) "positiva" else "negativa"
        tags$tr(
          tags$td(class = "palabra", palabra,
                  tags$span(class = "raiz", raiz)),
          tags$td(class = "aporte",
                  div(class = paste("mini-barra", hacia),
                      style = sprintf("width:%.0f%%", 100 * abs(aporte) / escala)),
                  span(class = paste("signo", hacia),
                       sprintf("%+.2f", aporte)))
        )
      })
    }

    tagList(
      p(class = "etiqueta", "Palabras que inclinaron la balanza"),
      tags$table(class = "tabla-aportes",
                 tags$thead(tags$tr(tags$th("Palabra"),
                                    tags$th("Aporte hacia positiva (+) o negativa (−)"))),
                 tags$tbody(filas)),
      if (length(sin_peso) > 0) {
        p(class = "nota",
          "Están en el vocabulario pero el modelo les dio peso cero: ",
          paste0(paste(sin_peso, collapse = ", "), "."))
      },
      if (length(r$fuera) > 0) {
        p(class = "nota",
          "Fuera del vocabulario del modelo (no cuentan): ",
          paste0(paste(r$fuera, collapse = ", "), "."))
      }
    )
  })
}

shinyApp(ui, server)
