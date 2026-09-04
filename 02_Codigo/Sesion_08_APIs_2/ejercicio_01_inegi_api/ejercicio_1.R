
# Utilice el API del INEGI para determinar que
# entidad de la república tiene la mayor aportación
# al PIB nacional.

# Librerias ----
library(inegiR)
library(tidyverse)
library(usethis)
library(httr)
library(jsonlite)

# Token del INEGI ----
# El token se obtiene gratis en:
# https://www.inegi.org.mx/app/desarrolladores/generatoken/Usuarios/token_Verify
# NUNCA se escribe en el script. Se guarda en el archivo .Renviron como
#   INEGI_TOKEN = "xxxx"
# Para abrir el .Renviron: usethis::edit_r_environ()
# Después de editarlo hay que reiniciar la sesión de R.
token_inegi <- Sys.getenv("INEGI_TOKEN")
stopifnot("Falta INEGI_TOKEN en el .Renviron" = nzchar(token_inegi))

# Forma 1: llamada directa con httr ----
# La URL tiene la forma:
# .../INDICATOR/{serie}/es/{geografia}/false/BIE-BISE/2.0/{token}?type=json
url_inegi <- paste0(
  "https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/",
  "INDICATOR/746097/es/00/false/BIE-BISE/2.0/", token_inegi, "?type=json"
)

solicitud <- GET(url_inegi)
solicitud
solicitud_json <- content(solicitud, "text")
lista_datos <- fromJSON(solicitud_json, flatten = TRUE)
lista_datos$Series$OBSERVATIONS

# Forma 2: con el cliente de INEGI (paquete inegiR) ----
inegi_series(series_id = 746097,
             token = token_inegi,
             geography = "00",
             as_tt = F,
             database = "BIE-BISE")

claves_estados <- str_pad(string = 0:32, width = 2, side = "left", pad = "0")

bolsa_vacia <- tibble()

for(clave in claves_estados){

  pib_estatal <- inegi_series(series_id = 746097,
               token = token_inegi,
               geography = clave,
               as_tt = F,
               database = "BIE-BISE") |>
    mutate(cve_ent = clave)

  bolsa_vacia <- rbind(bolsa_vacia, pib_estatal)
  print(paste0("Ya está en la bolsa el PIB del estado ", clave))

}

datos_pib <- bolsa_vacia

datos_pib |>
  as_tibble() |>
  filter(date == max(date)) |>
  mutate(aportacion_pib = 100*(values/first(values))) |>
  arrange(-aportacion_pib)
