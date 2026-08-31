# ============================================================================
# Aplicación Shiny: proyecciones de población municipal
# Sesión 06 - Taller de vibe coding, ejercicio 03
#
# La aplicación deja elegir un estado y, dentro de él, un municipio, y dibuja
# la serie proyectada de población de 2010 a 2030 marcando en rojo el año de
# población máxima. La gráfica es interactiva: al pasar el cursor sobre
# cualquier año se muestra la población proyectada de ese año.
#
# Insumo:  proyecciones_municipales_conapo.csv  (CONAPO, vía INEGI)
#
# Se corre desde esta carpeta con shiny::runApp() o con el botón "Run App"
# de RStudio. El proyecto ejercicio_03.Rproj fija el directorio de trabajo,
# de modo que la ruta relativa al CSV siempre resuelve.
# ============================================================================

library(shiny)
library(readr)
library(dplyr)
library(stringr)
library(plotly)
library(scales)

# ---------------------------------------------------------------------------
# 1. Datos
#
# El CSV se lee una sola vez al arrancar la aplicación, fuera de server(),
# para que la lectura no se repita en cada sesión de usuario.
#
# Tres filtros que el archivo exige y que no son evidentes:
#
#   - El CSV apila tres indicadores distintos: 42 es la población total,
#     198 la femenina y 199 la masculina. Sin filtrar por indicador, un mismo
#     municipio trae 53 filas y la gráfica encimaría tres series en una línea.
#   - Las claves terminadas en "000" (00000 nacional y 01000 a 32000 por
#     entidad) son totales de agregación, no municipios.
#   - nom_ent y nom_mun traen la cadena literal "NA", que se declara como
#     valor faltante. Con eso se van también cinco claves de Nayarit
#     (18021 a 18025) que solo aparecen en 2020, sin nombre y sin serie.
# ---------------------------------------------------------------------------

ruta_csv <- "proyecciones_municipales_conapo.csv"
stopifnot(file.exists(ruta_csv))

proyecciones <- read_csv(
    ruta_csv,
    col_select = c(no, cve_mun, nom_ent, nom_mun, year, valor),
    col_types = cols(
      no       = col_integer(),
      cve_mun  = col_character(),
      nom_ent  = col_character(),
      nom_mun  = col_character(),
      year     = col_integer(),
      valor    = col_double()
    ),
    na = "NA"
  ) %>%
  filter(
    no == 42,
    str_sub(cve_mun, 3, 5) != "000",
    !is.na(nom_ent),
    !is.na(nom_mun)
  ) %>%
  select(cve_mun, nom_ent, nom_mun, year, valor) %>%
  arrange(nom_ent, nom_mun, year)

# Catálogo para poblar los controles. El valor del control de municipio es la
# clave y no el nombre, porque hay nombres que se repiten entre estados.
catalogo <- proyecciones %>%
  distinct(cve_mun, nom_ent, nom_mun)

entidades <- sort(unique(catalogo$nom_ent))

azul <- "#1F5FA9"
rojo <- "#C0392B"
gris <- "#555555"

# ---------------------------------------------------------------------------
# 2. Interfaz
# ---------------------------------------------------------------------------

ui <- fluidPage(
  titlePanel("Proyecciones de población municipal"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput(
        inputId  = "estado",
        label    = "Estado",
        choices  = entidades,
        selected = entidades[1]
      ),
      selectInput(
        inputId = "municipio",
        label   = "Municipio",
        choices = NULL
      ),
      helpText(
        "Serie de población total proyectada por CONAPO, 2010 a 2030.",
        "El punto rojo marca el año de población máxima.",
        "Pasa el cursor sobre la línea para leer el dato de cada año."
      )
    ),
    mainPanel(
      width = 9,
      plotlyOutput("grafica_serie", height = "520px")
    )
  )
)

# ---------------------------------------------------------------------------
# 3. Lógica
# ---------------------------------------------------------------------------

server <- function(input, output, session) {

  # Al cambiar el estado se repuebla el control de municipios. Se usa
  # observeEvent y no un renderUI para que el control no se vuelva a dibujar
  # completo, solo cambien sus opciones.
  observeEvent(input$estado, {
    municipios_estado <- catalogo %>%
      filter(nom_ent == input$estado) %>%
      arrange(nom_mun)

    opciones <- setNames(municipios_estado$cve_mun, municipios_estado$nom_mun)

    updateSelectInput(
      session,
      inputId  = "municipio",
      choices  = opciones,
      selected = opciones[1]
    )
  })

  # Serie del municipio seleccionado. req() detiene el cálculo en el primer
  # instante, cuando el control de municipio todavía está vacío.
  serie_municipio <- reactive({
    req(input$municipio)
    proyecciones %>%
      filter(cve_mun == input$municipio)
  })

  maximo_municipio <- reactive({
    serie_municipio() %>%
      slice_max(valor, n = 1, with_ties = FALSE)
  })

  # La gráfica se arma con plotly y no con ggplot para tener control directo
  # del texto que aparece al pasar el cursor. Son dos capas: la serie completa,
  # que es la que responde al cursor año por año, y el máximo, que solo pinta
  # el punto rojo y no compite por el cursor (hoverinfo = "skip").
  output$grafica_serie <- renderPlotly({
    serie <- serie_municipio()
    req(nrow(serie) > 0)
    maximo <- maximo_municipio()

    titulo <- paste0(
      "<b>", maximo$nom_mun, ", ", maximo$nom_ent, "</b>",
      "<br><span style='font-size:13px;color:", gris, "'>",
      "Población máxima en ", maximo$year, ": ",
      comma(round(maximo$valor)), " personas.</span>"
    )

    plot_ly() %>%
      add_trace(
        data = serie,
        x = ~year, y = ~valor,
        type = "scatter", mode = "lines+markers",
        name = "Población",
        line   = list(color = azul, width = 3),
        marker = list(color = azul, size = 7),
        hovertemplate = paste0(
          "<b>%{y:,.0f}</b> personas<extra></extra>"
        )
      ) %>%
      add_trace(
        data = maximo,
        x = ~year, y = ~valor,
        type = "scatter", mode = "markers",
        name = "Máximo",
        marker = list(color = rojo, size = 13,
                      line = list(color = "white", width = 2)),
        hoverinfo = "skip",
        showlegend = FALSE
      ) %>%
      add_annotations(
        x = maximo$year, y = maximo$valor,
        text = paste0("<b>Máximo ", maximo$year, "</b>"),
        showarrow = FALSE, yshift = 26,
        font = list(color = rojo, size = 13)
      ) %>%
      layout(
        title = list(text = titulo, x = 0, xanchor = "left",
                     font = list(color = azul, size = 19)),
        # hovermode "x unified" hace que el cursor no tenga que caer justo
        # sobre el punto: basta con estar en la vertical del año.
        hovermode = "x unified",
        hoverlabel = list(bgcolor = "white", bordercolor = azul,
                          font = list(size = 14)),
        xaxis = list(
          title = "", dtick = 5, tick0 = 2010,
          showgrid = FALSE, showspikes = TRUE, spikemode = "across",
          spikethickness = 1, spikedash = "dot", spikecolor = gris,
          hoverformat = "d"
        ),
        yaxis = list(
          title = "Personas", tickformat = ",d",
          gridcolor = "#E8E8E8", zeroline = FALSE
        ),
        margin = list(t = 80, b = 70, l = 70, r = 30),
        annotations = list(list(
          x = 0, y = -0.16, xref = "paper", yref = "paper",
          text = "Fuente: CONAPO, proyecciones de población municipal.",
          showarrow = FALSE, xanchor = "left",
          font = list(size = 11, color = gris)
        )),
        plot_bgcolor = "white", paper_bgcolor = "white"
      ) %>%
      config(
        locale = "es",
        displaylogo = FALSE,
        modeBarButtonsToRemove = list("lasso2d", "select2d", "autoScale2d")
      )
  })
}

shinyApp(ui = ui, server = server)
