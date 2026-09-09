
# Librerías ----
library(ellmer)
library(tidyverse)
library(httr2)
library(inegiR)

# Paso 01. Generamos el catálogo de series.

catalogo <- tibble::tribble(
   ~clave,                                                             ~nombre, ~periodicidad,
  746097L,                                   "PIB estatal (millones de pesos)",       "anual",
  738545L, "Variación anual del indicador de actividad industrial estatal (%)",     "mensual",
  441566L,              "Ingresos estatales por impuestos (millones de pesos)",       "anual"
  )

# Catálogo de entidades:

entidades <- c(
  "Aguascalientes" = "01",
  "Baja California" = "02",
  "Baja California Sur" = "03",
  "Campeche" = "04",
  "Coahuila" = "05",
  "Colima" = "06",
  "Chiapas" = "07",
  "Chihuahua" = "08",
  "Ciudad de México" = "09",
  "Durango" = "10",
  "Guanajuato" = "11",
  "Guerrero" = "12",
  "Hidalgo" = "13", "Jalisco" = "14",
  "Estado de México" = "15", "Michoacán" = "16", "Morelos" = "17", "Nayarit" = "18",
  "Nuevo León" = "19", "Oaxaca" = "20", "Puebla" = "21", "Querétaro" = "22",
  "Quintana Roo" = "23", "San Luis Potosí" = "24", "Sinaloa" = "25", "Sonora" = "26",
  "Tabasco" = "27", "Tamaulipas" = "28", "Tlaxcala" = "29", "Veracruz" = "30",
  "Yucatán" = "31", "Zacatecas" = "32",
  "Nacional" = "00"
)


usethis::edit_r_environ()

# Obtener token ----
token <- Sys.getenv("INEGI_TOKEN")
# token <- "682ad7f9-19fe-47f0-abec-e4c2ab2f2948"

# Consultar serie de INEGI
# Variación de la actividad industrial - Ejemplo

serie_seleccionada <- 738545
geografia_seleccionada <- "00"


consulta_serie <- function(serie_seleccionada = 738545,
                           geografia_seleccionada = "00"){

  serie <- inegi_series(series_id = serie_seleccionada,
               token = token,
               geography = geografia_seleccionada,
               database = "BIE-BISE") |>
    as_tibble() |>
    mutate(cve_ent = geografia_seleccionada)

  return(serie)

}

# Usando mi función :3
consulta_serie(serie_seleccionada = 441566,
               geografia_seleccionada = "17")

# Envolver la función como una tool
# ?tool

tool_consulta <- tool(
  fun = consulta_serie,
  description = "Esta función nos permite consultar las series de INEGI que cuentan con información estatal de interés. ",
  name = "consulta",
  arguments = list(serie_seleccionada =
                     type_string("Clave de la serie"),
                   geografia_seleccionada = type_string("Clave INEGI de la entidad seleccionada")
                   )
)

# Servir
mcptools::mcp_server(
  tools = list(tool_consulta),
  session_tools = FALSE
)

