# Programamos el servidor
# Uso: Rscript codigo_MCP_2.R   (lo lanza el agente; no hacer source() en RStudio
# porque la última línea bloquea la sesión)

# Librerías ----
library(ellmer)
library(tidyverse)
library(httr2)

# 1. Catálogo ----
# Acá decidimos lo que puede preguntar el agente.
# `periodicidad` sí importa: le dice al modelo qué significa "el dato más reciente"
# (un año para el PIB, un mes para el IMAIEF). La unidad, cuando importa, va en el nombre.

catalogo <- tibble::tribble(
  ~clave,   ~nombre,                                                          ~periodicidad,
  "746097", "PIB estatal (millones de pesos)",                                 "anual",
  "738545", "Variación anual del indicador de actividad industrial estatal (%)", "mensual",
  "441566", "Ingresos estatales por impuestos (miles de pesos)",                "anual"
)

entidades <- c(
  "Aguascalientes" = "01", "Baja California" = "02", "Baja California Sur" = "03",
  "Campeche" = "04", "Coahuila" = "05", "Colima" = "06", "Chiapas" = "07",
  "Chihuahua" = "08", "Ciudad de México" = "09", "Durango" = "10",
  "Guanajuato" = "11", "Guerrero" = "12", "Hidalgo" = "13", "Jalisco" = "14",
  "Estado de México" = "15", "Michoacán" = "16", "Morelos" = "17", "Nayarit" = "18",
  "Nuevo León" = "19", "Oaxaca" = "20", "Puebla" = "21", "Querétaro" = "22",
  "Quintana Roo" = "23", "San Luis Potosí" = "24", "Sinaloa" = "25", "Sonora" = "26",
  "Tabasco" = "27", "Tamaulipas" = "28", "Tlaxcala" = "29", "Veracruz" = "30",
  "Yucatán" = "31", "Zacatecas" = "32",
  "Nacional" = "00"
)

# 2. Funciones normales de R ----
# El token vive en ~/.Renviron como INEGI_TOKEN. usethis::edit_r_environ() para editarlo.

token <- function() {
  t <- Sys.getenv("INEGI_TOKEN")
  if (t == "") stop("Falta INEGI_TOKEN en el ambiente (.Renviron).")
  t
}

buscar_entidad <- function(nombre) {
  idx <- match(str_to_lower(nombre), str_to_lower(names(entidades)))
  if (is.na(idx)) stop("La entidad no se reconoce: ", nombre)
  entidades[[idx]]
}

descargar_serie <- function(clave, area) {
  # Se fuerzan los argumentos antes del tryCatch para que un error de entidad
  # ("Narnia") salga con su propio mensaje y no se confunda con uno de INEGI.
  clave <- as.character(clave)
  area  <- as.character(area)

  # URL de la API de INEGI:
  # .../INDICATOR/{clave}/es/{area}/false/BIE-BISE/2.0/{token}?type=json
  # "BIE-BISE" es el valor que acepta la API para estas series; "BIE" o
  # "BISE" a secas devuelven 400.
  url <- paste0(
    "https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/",
    "INDICATOR/", clave, "/es/", area, "/false/BIE-BISE/2.0/", token(),
    "?type=json"
  )

  # IMPORTANTE: se descarga con httr2 y NO con inegiR::inegi_series().
  # inegiR llama a jsonlite::fromJSON(url), que abre la conexión url() de R
  # base. Dentro de un servidor MCP esa conexión se bloquea para siempre:
  # mientras espera la respuesta, R revisa si hay actividad en stdin, y el
  # candado de stdin ya lo tiene el lector de mcptools. Es un deadlock: la
  # tool nunca responde y el agente se queda esperando. httr2 (libcurl vía el
  # paquete curl) no toca stdin, así que no tiene ese problema.
  #
  # El tryCatch evita que un error de red (que trae el token en la URL)
  # llegue al agente.
  respuesta <- tryCatch(
    request(url) %>%
      req_timeout(30) %>%
      req_perform() %>%
      resp_body_string() %>%
      jsonlite::fromJSON(),
    error = function(e) NULL
  )

  if (is.null(respuesta) || !is.null(respuesta$ErrorInfo) ||
      is.null(respuesta$Series$OBSERVATIONS)) {
    stop("INEGI no devolvió datos para el indicador ", clave,
         " en la entidad con clave ", area, ".")
  }

  observaciones <- as_tibble(respuesta$Series$OBSERVATIONS[[1]])
  if (nrow(observaciones) == 0) {
    stop("INEGI no devolvió datos para el indicador ", clave,
         " en la entidad con clave ", area, ".")
  }

  # FREQ de INEGI: "3" = anual, "8" = mensual. TIME_PERIOD viene como "2024"
  # en anuales y "2025/06" en mensuales. Se conserva el formato que usaba
  # inegiR: `date` como texto en anuales y como Date en mensuales.
  frecuencia <- as.character(respuesta$Series$FREQ)
  observaciones %>%
    transmute(
      date = if (frecuencia == "8") {
        as.Date(paste0(TIME_PERIOD, "/01"), format = "%Y/%m/%d")
      } else {
        as.character(TIME_PERIOD)
      },
      values       = as.numeric(OBS_VALUE),
      clave_estado = area
    )
}

listar_indicadores <- function() {
  catalogo
}

consultar_inegi <- function(clave, entidad = "Nacional") {
  clave <- as.character(clave)
  if (!clave %in% catalogo$clave) stop("Clave fuera del catálogo. Usa listar_indicadores().")

  info   <- filter(catalogo, clave == !!clave)
  serie  <- descargar_serie(clave = clave, area = buscar_entidad(entidad))
  ultimo <- slice_max(serie, date, n = 1)

  # descargar_serie() devuelve `date` como texto ("2024") en series anuales y como Date
  # en mensuales; `date_shortcut` solo trae "Year" o "M4", que no sirve como
  # periodo. Se construye el periodo a partir de `date`.
  periodo <- if (inherits(ultimo$date, "Date")) {
    format(ultimo$date, "%Y-%m")
  } else {
    as.character(ultimo$date)
  }

  tibble(
    indicador    = info$nombre,
    periodicidad = info$periodicidad,
    entidad      = entidad,
    periodo      = periodo,
    valor        = ultimo$values,
    fuente       = "INEGI, Banco de Información Económica"
  )
}


comparar <- function(clave, entidades_lista) {
  map(entidades_lista, \(e) consultar_inegi(clave, e)) |>
    list_rbind() |>
    arrange(desc(valor))
}

# 3. Envolver las funciones como tools ----
# La descripción es lo que el modelo lee para decidir cuándo llamarlas. Escribes para el modelo.
#
# mcptools convierte el resultado de la tool a texto con paste(): un tibble se
# aplana columna por columna y el modelo pierde los nombres de las columnas.
# Por eso cada tool devuelve el tibble como CSV (encabezado + filas), que el
# modelo lee sin problema. Las funciones de la sección 2 siguen devolviendo
# tibbles para poder probarlas en R.

como_csv <- function(x) {
  x %>%
    # Se redondea para no mandar ruido de punto flotante (465888.1299999998)
    mutate(across(where(is.numeric), ~ round(.x, 4))) %>%
    readr::format_csv()
}

tool_listar <- tool(
  function() como_csv(listar_indicadores()),
  "Devuelve la lista de indicadores de INEGI disponibles, con su clave, nombre y periodicidad. Llama a esto primero para saber qué claves puedes usar y con qué frecuencia se publica cada una.",
  name = "listar_indicadores"
)

tool_consultar <- tool(
  function(clave, entidad = "Nacional") como_csv(consultar_inegi(clave, entidad)),
  "Consulta el dato más reciente de un indicador de INEGI para una entidad federativa de México o el valor nacional. El campo 'periodo' indica a qué año o mes corresponde el dato.",
  name = "consultar_inegi",
  arguments = list(
    clave   = type_string("Clave del indicador, obtenida con listar_indicadores()."),
    entidad = type_string("Nombre de la entidad federativa en español, por ejemplo 'Oaxaca', 'Ciudad de México' o 'Nacional'. Si se omite, se usa 'Nacional'.", required = FALSE)
  )
)

tool_comparar <- tool(
  function(clave, entidades_lista) como_csv(comparar(clave, entidades_lista)),
  "Compara el dato más reciente de un indicador entre varias entidades federativas de México y devuelve la tabla ordenada de mayor a menor.",
  name = "comparar",
  arguments = list(
    clave           = type_string("Clave del indicador, obtenida con listar_indicadores()."),
    entidades_lista = type_array("Lista de nombres de entidades federativas en español.", items = type_string())
  )
)

# 4. Servir ----
# Esta línea es todo lo que MCP agrega. session_tools = FALSE para que el agente
# vea solo nuestras tres tools.

mcptools::mcp_server(
  tools = list(tool_listar, tool_consultar, tool_comparar),
  session_tools = FALSE
)

# Para probar a mano en RStudio, comenta la llamada a mcp_server() de arriba y corre:
# consultar_inegi("746097", "Oaxaca")
# comparar("738545", c("Nuevo León", "Jalisco", "Chiapas"))
