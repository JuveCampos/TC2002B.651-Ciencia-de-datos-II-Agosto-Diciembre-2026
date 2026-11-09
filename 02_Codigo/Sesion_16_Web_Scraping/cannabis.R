
# Librerías ----
library(rvest)
library(httr2)
library(tidyverse)


codigo_pagina_cannabis <- read_html("https://en.wikipedia.org/wiki/Legality_of_cannabis")

# Extracción de tablas: 
tabla_paises_cannabis <- codigo_pagina_cannabis |> 
  html_table() |> 
  pluck(3)


tabla_paises_cannabis |> 
  # filter(Recreational == "Illegal")
  filter(str_detect(Recreational, pattern = "Illegal|illegal"))

100*(163/203)

