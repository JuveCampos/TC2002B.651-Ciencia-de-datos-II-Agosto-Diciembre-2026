
# Carta natal con un modelo local (Ollama + ellmer) en Shiny ----
# Sesión 08 - APIs II · TC2002B
#
# Correr con:  shiny::runApp("ejercicio_04_ellmer")
# Requiere Ollama corriendo en local (ollama serve) y el modelo descargado
# (ollama pull qwen3.5:4b). Las imágenes opcionales van en www/img/, ver
# www/img/LEEME.md.

# Librerías ----
library(shiny)
library(tidyverse)
library(ellmer)
library(future)
library(promises)

# La consulta al modelo tarda de 20 a 90 segundos; se corre en un proceso
# aparte para que la página no se congele mientras el astrólogo escribe.
plan(multisession, workers = 2)

# Configuración del astrólogo ----
modelo_default <- "qwen3.5:4b"

system_prompt <- "Eres un astrólogo profesional que elabora cartas natales e interpretaciones
de personalidad.

## Entrada
Recibirás tres datos del usuario:
- Fecha de nacimiento (día, mes, año)
- Hora de nacimiento (con zona horaria si es posible)
- Lugar de nacimiento (ciudad y país)

Si falta alguno, pídelo antes de continuar. Excepción: si no se conoce la
hora, avisa que no podrás calcular el Ascendente ni las casas, y ofrece
continuar solo con las posiciones planetarias.

## Tarea
1. Calcula la carta natal: posición por signo de Sol, Luna, Ascendente,
   Mercurio, Venus y Marte, más la casa en la que cae cada uno.
2. Interpreta la personalidad a partir de esas posiciones, no de
   generalidades del signo solar.
3. Señala al menos una tensión o contradicción entre configuraciones
   (por ejemplo, Sol en signo de fuego con Luna en signo de agua).

## Formato de salida
**Carta natal**
Tabla con: cuerpo celeste | signo | grado | casa

**Retrato de personalidad**
3 o 4 párrafos, máximo 120 palabras cada uno, en estos ejes:
- Identidad y motor vital (Sol, Ascendente)
- Mundo emocional (Luna)
- Comunicación y vínculos (Mercurio, Venus)
- Impulso y conflicto (Marte)

**Tensiones**
2 o 3 viñetas.

## Reglas
- Español de México, segunda persona, tono directo y sin adornos.
- Nada de predicciones sobre el futuro, salud, dinero o decisiones legales.
- Describe rasgos, no destinos: 'tiendes a', no 'eres'.
- Si un dato es ambiguo (ciudad homónima, hora dudosa), dilo en lugar de
  suponer.
- No inventes posiciones planetarias. Si no puedes calcularlas con
  precisión, indícalo explícitamente."

# Modelos disponibles en Ollama (se descartan los de embeddings). Si Ollama
# no responde, la lista se queda con el modelo por defecto.
modelos_disponibles <- tryCatch(
  models_ollama() %>%
    pull(id) %>%
    str_subset("embed|bge", negate = TRUE),
  error = function(e) modelo_default
)
if (length(modelos_disponibles) == 0) modelos_disponibles <- modelo_default

# Catálogo del zodiaco ----
# inicio_md codifica mes * 100 + día del primer día de cada signo.
signos <- tibble(
  nombre = c("Aries", "Tauro", "Géminis", "Cáncer", "Leo", "Virgo",
             "Libra", "Escorpio", "Sagitario", "Capricornio", "Acuario",
             "Piscis"),
  clave = c("aries", "tauro", "geminis", "cancer", "leo", "virgo",
            "libra", "escorpio", "sagitario", "capricornio", "acuario",
            "piscis"),
  # \uFE0E fuerza la versión tipográfica del glifo; sin él, Chrome en Mac
  # dibuja los signos como emoji morados.
  glifo = paste0(c("♈", "♉", "♊", "♋", "♌", "♍",
                   "♎", "♏", "♐", "♑", "♒", "♓"), "\uFE0E"),
  elemento = c("Fuego", "Tierra", "Aire", "Agua", "Fuego", "Tierra",
               "Aire", "Agua", "Fuego", "Tierra", "Aire", "Agua"),
  regente = c("Marte", "Venus", "Mercurio", "Luna", "Sol", "Mercurio",
              "Venus", "Plutón", "Júpiter", "Saturno", "Urano", "Neptuno"),
  fechas = c("21 mar - 19 abr", "20 abr - 20 may", "21 may - 20 jun",
             "21 jun - 22 jul", "23 jul - 22 ago", "23 ago - 22 sep",
             "23 sep - 22 oct", "23 oct - 21 nov", "22 nov - 21 dic",
             "22 dic - 19 ene", "20 ene - 18 feb", "19 feb - 20 mar"),
  inicio_md = c(321, 420, 521, 621, 723, 823, 923, 1023, 1122, 1222, 120,
                219)
)

meses <- c("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
           "agosto", "septiembre", "octubre", "noviembre", "diciembre")

dias_semana <- c("domingo", "lunes", "martes", "miércoles", "jueves",
                 "viernes", "sábado")

# Signo solar a partir de la fecha (zodiaco tropical, fechas usuales) ----
signo_solar <- function(fecha) {
  md <- as.integer(format(fecha, "%m")) * 100 + as.integer(format(fecha, "%d"))
  cortes <- sort(signos$inicio_md)
  # findInterval devuelve 0 antes del 20 de enero y 12 desde el 22 de
  # diciembre; ambos extremos caen en Capricornio.
  orden <- c("Capricornio", "Acuario", "Piscis", "Aries", "Tauro", "Géminis",
             "Cáncer", "Leo", "Virgo", "Libra", "Escorpio", "Sagitario",
             "Capricornio")
  nombre <- orden[findInterval(md, cortes) + 1]
  signos %>% filter(nombre == !!nombre)
}

# Fase lunar aproximada de hoy (ciclo sinódico desde la luna nueva de
# referencia del 6 de enero de 2000) ----
fase_lunar <- function(fecha = Sys.Date()) {
  referencia <- as.POSIXct("2000-01-06 18:14:00", tz = "UTC")
  edad <- as.numeric(difftime(as.POSIXct(fecha, tz = "UTC"), referencia,
                              units = "days")) %% 29.530588853
  iluminacion <- (1 - cos(2 * pi * edad / 29.530588853)) / 2
  nombre <- case_when(
    edad < 1.85 ~ "Luna nueva",
    edad < 7.38 ~ "Luna creciente",
    edad < 9.23 ~ "Cuarto creciente",
    edad < 14.77 ~ "Luna gibosa creciente",
    edad < 16.61 ~ "Luna llena",
    edad < 22.15 ~ "Luna gibosa menguante",
    edad < 23.99 ~ "Cuarto menguante",
    TRUE ~ "Luna menguante"
  )
  list(nombre = nombre, iluminacion = round(100 * iluminacion))
}

# Rueda zodiacal en SVG con el signo activo resaltado ----
# Sigue la convención de las cartas: Aries a la izquierda y los signos
# avanzan en sentido contrario a las manecillas del reloj.
rueda_svg <- function(activo, tamano = 380) {
  cx <- tamano / 2
  r_ext <- tamano * 0.46
  r_int <- tamano * 0.30
  r_txt <- (r_ext + r_int) / 2

  punto <- function(r, grados) {
    theta <- grados * pi / 180
    sprintf("%.1f %.1f", cx + r * cos(theta), cx - r * sin(theta))
  }

  sectores <- lapply(seq_len(12), function(i) {
    t0 <- 180 + 30 * (i - 1)
    t1 <- t0 + 30
    es_activo <- signos$nombre[i] == activo
    sprintf(
      paste0(
        '<path class="sector%s" d="M %s A %.1f %.1f 0 0 0 %s L %s ',
        'A %.1f %.1f 0 0 1 %s Z"/>',
        '<text class="glifo%s" x="%s" y="%s" font-size="%.1f" ',
        'text-anchor="middle" dominant-baseline="central">%s</text>'
      ),
      if (es_activo) " activo" else "",
      punto(r_ext, t0), r_ext, r_ext, punto(r_ext, t1), punto(r_int, t1),
      r_int, r_int, punto(r_int, t0),
      if (es_activo) " activo" else "",
      str_split_1(punto(r_txt, t0 + 15), " ")[1],
      str_split_1(punto(r_txt, t0 + 15), " ")[2],
      tamano * 0.068,
      signos$glifo[i]
    )
  })

  centro <- signos %>% filter(nombre == activo)
  icono_png <- file.path("www", "img", "signos", paste0(centro$clave, ".png"))
  centro_svg <- if (file.exists(icono_png)) {
    sprintf(
      '<image href="img/signos/%s.png" x="%.1f" y="%.1f" width="%.1f" height="%.1f"/>',
      centro$clave, cx - r_int * 0.62, cx - r_int * 0.62, r_int * 1.24,
      r_int * 1.24
    )
  } else {
    sprintf(
      paste0('<text class="glifo-centro" x="%.1f" y="%.1f" font-size="%.1f" ',
             'text-anchor="middle" dominant-baseline="central">%s</text>'),
      cx, cx, tamano * 0.26, centro$glifo
    )
  }

  paste0(
    sprintf('<svg viewBox="0 0 %d %d" class="rueda-svg" role="img" aria-label="Rueda zodiacal con %s resaltado">',
            tamano, tamano, activo),
    sprintf('<circle class="anillo" cx="%.1f" cy="%.1f" r="%.1f"/>', cx, cx,
            r_ext + tamano * 0.025),
    paste(unlist(sectores), collapse = ""),
    sprintf('<circle class="disco" cx="%.1f" cy="%.1f" r="%.1f"/>', cx, cx,
            r_int - tamano * 0.02),
    centro_svg,
    "</svg>"
  )
}

# Limpieza del markdown que devuelve el modelo ----
# Los modelos chicos suelen (a) poner los títulos como una línea en
# negritas y (b) escribir tablas sin la fila separadora |---|. Se corrigen
# ambos casos para que shiny::markdown() los dibuje bien.
limpiar_markdown <- function(texto) {
  lineas <- str_split_1(texto, "\n") %>%
    str_replace("^\\s*\\*\\*([^*]+)\\*\\*\\s*:?\\s*$", "### \\1")

  es_fila <- str_count(lineas, fixed("|")) >= 2
  es_separador <- str_detect(lineas, "^\\s*\\|?\\s*:?-{2,}")
  # Un encabezado de tabla es una fila seguida de otra fila que no sea
  # separador y que no venga precedida de otra fila.
  inicio_tabla <- es_fila & lead(es_fila, default = FALSE) &
    !lead(es_separador, default = FALSE) & !lag(es_fila, default = FALSE)

  if (any(inicio_tabla)) {
    for (i in rev(which(inicio_tabla))) {
      n_col <- str_count(lineas[i], fixed("|")) +
        if (str_detect(lineas[i], "^\\s*\\|")) -1 else 1
      separador <- paste0("|", strrep("---|", n_col))
      lineas <- append(lineas, separador, after = i)
    }
  }

  paste(lineas, collapse = "\n")
}

# Cielo estrellado de respaldo (SVG) cuando no hay www/img/fondo.jpg ----
set.seed(8)
n_estrellas <- 260
estrellas <- tibble(
  x = runif(n_estrellas, 0, 1600),
  y = runif(n_estrellas, 0, 1000),
  r = sample(c(0.6, 0.9, 1.3, 1.8), n_estrellas, replace = TRUE,
             prob = c(0.5, 0.3, 0.15, 0.05)),
  alfa = runif(n_estrellas, 0.35, 1)
)
cielo_svg <- paste0(
  '<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="1000" ',
  'viewBox="0 0 1600 1000"><rect width="1600" height="1000" fill="#0a0e2a"/>',
  paste(sprintf('<circle cx="%.0f" cy="%.0f" r="%.1f" fill="#f4ecd2" opacity="%.2f"/>',
                estrellas$x, estrellas$y, estrellas$r, estrellas$alfa),
        collapse = ""),
  "</svg>"
)
fondo_css <- if (file.exists("www/img/fondo.jpg")) {
  "url('img/fondo.jpg')"
} else {
  paste0("url(\"data:image/svg+xml;utf8,",
         URLencode(cielo_svg, reserved = TRUE), "\")")
}

hay_banner <- file.exists("www/img/banner.png")

# Interfaz ----
hoy <- Sys.Date()
luna_hoy <- fase_lunar(hoy)
fecha_hoy <- sprintf("%s %d de %s de %s",
                     dias_semana[as.POSIXlt(hoy)$wday + 1],
                     as.integer(format(hoy, "%d")),
                     meses[as.integer(format(hoy, "%m"))],
                     format(hoy, "%Y"))

ui <- fluidPage(
  lang = "es",
  tags$head(
    tags$title("La Bóveda Celeste · Carta natal"),
    tags$meta(name = "viewport",
              content = "width=device-width, initial-scale=1"),
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(
      rel = "stylesheet",
      href = paste0("https://fonts.googleapis.com/css2?",
                    "family=Cinzel+Decorative:wght@700&",
                    "family=Cinzel:wght@500;600&",
                    "family=Cormorant+Garamond:ital,wght@0,400;0,600;1,400&",
                    "family=Noto+Sans+Symbols:wght@400;600&",
                    "display=swap")
    ),
    tags$link(rel = "stylesheet", href = "estilos.css"),
    tags$style(HTML(sprintf("body { background-image: %s; }", fondo_css)))
  ),

  # Cabecera al estilo de los portales de horóscopo
  tags$header(
    class = "cabecera",
    if (hay_banner) tags$img(src = "img/banner.png", class = "banner",
                             alt = ""),
    tags$p(class = "ceja", "Consulta astrológica en línea"),
    tags$h1(class = "titulo", "La Bóveda Celeste"),
    tags$p(class = "lema",
           "Carta natal y retrato de personalidad · consulta gratuita"),
    tags$p(class = "efemeride",
           sprintf("%s · %s, %d %% iluminada", fecha_hoy, luna_hoy$nombre,
                   luna_hoy$iluminacion))
  ),

  # Franja con los doce signos y sus fechas
  tags$nav(
    class = "franja-signos", `aria-label` = "Fechas de los signos",
    lapply(seq_len(nrow(signos)), function(i) {
      icono <- file.path("www", "img", "signos",
                         paste0(signos$clave[i], ".png"))
      tags$span(
        class = "signo-item",
        if (file.exists(icono)) {
          tags$img(src = sprintf("img/signos/%s.png", signos$clave[i]),
                   alt = "", class = "signo-icono")
        } else {
          tags$span(class = "signo-glifo", signos$glifo[i])
        },
        tags$span(class = "signo-nombre", signos$nombre[i]),
        tags$span(class = "signo-fechas", signos$fechas[i])
      )
    })
  ),

  tags$main(
    class = "tablero",

    # Columna izquierda: formulario en pergamino
    tags$section(
      class = "pergamino formulario",
      tags$h2("Tus datos de nacimiento"),
      tags$p(class = "nota",
             "Con la hora exacta se calculan el Ascendente y las casas.
             Sin ella, solo las posiciones planetarias."),
      dateInput("fecha", "Fecha de nacimiento", value = "1991-07-08",
                min = "1900-01-01", max = hoy, format = "dd/mm/yyyy",
                language = "es", startview = "year", weekstart = 1),
      tags$div(
        class = "fila-hora",
        selectInput("hora", "Hora", choices = sprintf("%02d", 0:23),
                    selected = "13"),
        selectInput("minuto", "Minutos", choices = sprintf("%02d", 0:59),
                    selected = "15")
      ),
      checkboxInput("sin_hora", "No conozco mi hora de nacimiento"),
      textInput("ciudad", "Ciudad de nacimiento", value = "Tuxtla Gutiérrez"),
      textInput("pais", "País", value = "México"),
      selectInput("modelo", "Astrólogo (modelo local en Ollama)",
                  choices = modelos_disponibles,
                  selected = if (modelo_default %in% modelos_disponibles)
                    modelo_default else modelos_disponibles[1]),
      actionButton("consultar", "Levantar mi carta natal",
                   class = "boton-oro"),
      tags$p(class = "aviso",
             "La lectura la redacta un modelo de lenguaje que corre en tu
             computadora. Tarda entre 20 y 90 segundos.")
    ),

    # Columna derecha: rueda y lectura
    tags$section(
      class = "lectura-col",
      tags$div(
        class = "rueda-caja",
        uiOutput("rueda"),
        uiOutput("titular_signo")
      ),
      tags$div(class = "pergamino lectura", uiOutput("lectura"))
    )
  ),

  tags$footer(
    class = "pie",
    tags$p("Los astros no responden por las decisiones que tomes con base
           en esta lectura. Ejercicio de la Sesión 08 (APIs II) del curso
           TC2002B: ellmer + Ollama + Shiny."),
    tags$p(class = "pie-ornamento", "✦ ✧ ✦")
  )
)

# Servidor ----
server <- function(input, output, session) {

  # Signo solar: se calcula en R, sin pedirle nada al modelo
  signo <- reactive({
    req(input$fecha)
    signo_solar(input$fecha)
  })

  output$rueda <- renderUI({
    HTML(rueda_svg(signo()$nombre))
  })

  output$titular_signo <- renderUI({
    s <- signo()
    tagList(
      tags$p(class = "ceja", "Tu signo solar"),
      tags$h2(class = "signo-titular", s$nombre),
      tags$p(class = "signo-detalle",
             sprintf("%s · regido por %s · %s", s$elemento, s$regente,
                     s$fechas))
    )
  })

  # Consulta al modelo en segundo plano
  consulta <- ExtendedTask$new(function(modelo, prompt, sistema) {
    future_promise({
      astrologo <- ellmer::chat_ollama(
        model = modelo,
        system_prompt = sistema,
        params = ellmer::params(reasoning_effort = "none")
      )
      astrologo$chat(prompt, echo = "none")
    }, seed = TRUE)
  })

  observeEvent(input$consultar, {
    ciudad <- str_squish(input$ciudad)
    pais <- str_squish(input$pais)
    if (ciudad == "" || pais == "") {
      showNotification("Escribe la ciudad y el país de nacimiento.",
                       type = "warning")
      return()
    }

    fecha <- input$fecha
    fecha_texto <- sprintf("%d de %s de %s", as.integer(format(fecha, "%d")),
                           meses[as.integer(format(fecha, "%m"))],
                           format(fecha, "%Y"))
    hora_texto <- if (isTRUE(input$sin_hora)) {
      "No conozco mi hora de nacimiento."
    } else {
      sprintf("a las %s:%s, hora local del lugar de nacimiento.",
              input$hora, input$minuto)
    }
    prompt <- sprintf("Nací el %s, en %s, %s, %s", fecha_texto, ciudad,
                      pais, hora_texto)

    updateActionButton(session, "consultar",
                       label = "Consultando...",
                       disabled = TRUE)
    consulta$invoke(input$modelo, prompt, system_prompt)
  })

  # Cuando la consulta termina (bien o mal) se reactiva el botón
  observe({
    if (consulta$status() %in% c("success", "error")) {
      updateActionButton(session, "consultar",
                         label = "Levantar mi carta natal", disabled = FALSE)
    }
  })

  output$lectura <- renderUI({
    estado <- consulta$status()

    if (estado == "initial") {
      return(tagList(
        tags$p(class = "ceja", "Tu lectura aparecerá aquí"),
        tags$p(class = "vacio",
               "Captura tu fecha, hora y lugar de nacimiento y oprime el
               botón. El astrólogo levantará la carta con Sol, Luna,
               Ascendente, Mercurio, Venus y Marte, y escribirá tu
               retrato de personalidad.")
      ))
    }

    if (estado == "running") {
      return(tagList(
        tags$p(class = "ceja", "Consultando las efemérides"),
        tags$div(class = "espera",
                 HTML(rueda_svg(signo()$nombre, tamano = 120))),
        tags$p(class = "vacio",
               "El astrólogo está calculando las posiciones y redactando
               tu retrato. La rueda deja de girar cuando termine.")
      ))
    }

    if (estado == "error") {
      mensaje <- tryCatch(consulta$result(),
                          error = function(e) conditionMessage(e))
      return(tagList(
        tags$p(class = "ceja error", "No se pudo consultar al astrólogo"),
        tags$p(class = "vacio",
               "Revisa que Ollama esté corriendo (ollama serve) y que el
               modelo elegido esté descargado (ollama pull). Detalle
               técnico:"),
        tags$pre(class = "detalle-error", mensaje)
      ))
    }

    tagList(
      tags$p(class = "ceja", "Tu carta natal"),
      tags$div(class = "cuerpo-lectura",
               markdown(limpiar_markdown(consulta$result()))),
      tags$p(class = "firma",
             sprintf("Redactada por %s · %s", input$modelo,
                     format(Sys.time(), "%d/%m/%Y %H:%M")))
    )
  })
}

shinyApp(ui, server)
