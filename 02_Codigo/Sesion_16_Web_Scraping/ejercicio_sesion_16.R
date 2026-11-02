
# Librerías ----
library(tidyverse)
library(curl)
library(readxl)

# Ligas de ejemplo de INEGI
# Las tomamos con click derecho + copiar enlace
# https://www.inegi.org.mx/contenidos/programas/ccpv/2010/tabulados/Basico/07_14B_MUNICIPAL_01.xls
# https://www.inegi.org.mx/contenidos/programas/ccpv/2010/tabulados/Basico/07_14B_MUNICIPAL_02.xls
# https://www.inegi.org.mx/contenidos/programas/ccpv/2010/tabulados/Basico/07_14B_MUNICIPAL_20.xls
# https://www.inegi.org.mx/contenidos/programas/ccpv/2010/tabulados/Basico/07_14B_MUNICIPAL_32.xls

# Caso n = aguascalientes 
curl_download(url = "https://www.inegi.org.mx/contenidos/programas/ccpv/2010/tabulados/Basico/07_14B_MUNICIPAL_01.xls", 
              destfile = "descarga_inegi/tabulado_educacion_01.xls")


# Caso n = i 
i = "17"
curl_download(url = str_c("https://www.inegi.org.mx/contenidos/programas/ccpv/2010/tabulados/Basico/07_14B_MUNICIPAL_", i, ".xls"), 
              destfile = str_c("descarga_inegi/tabulado_educacion_", i, ".xls"))

# Implementar el bucle 
# claves_estados <- c("01", "02", "03")

claves_estados <- c("01", "02", "03", "04", "05", "06", "07", "08", "09", 10:32)
claves_estados <- c(str_c("0", 1:9), 10:32)

# Bucle 
for(i in claves_estados){
  
  curl_download(url = str_c("https://www.inegi.org.mx/contenidos/programas/ccpv/2010/tabulados/Basico/07_14B_MUNICIPAL_", i, ".xls"), 
                destfile = str_c("descarga_inegi/tabulado_educacion_", i, ".xls"))
  
  print(str_c("Ya se descargó el archivo del estado ", i, " :3"))
  
}

# Construcción de el indicador de grado promedio de escolaridad 

# Caso n = "Aguascalientes" 

edo = 17

datos_educ <- read_excel(str_c("descarga_inegi/tabulado_educacion_",
                               edo,
                               ".xls"), skip = 5) %>% 
  filter(!is.na(Municipio)) %>% 
  filter(Sexo == "Total") %>% 
  filter(`Grupos quinquenales de edad` == "Total") %>% 
  select(1, 2, 16) %>% 
  mutate(Año = 2010)

# Generamos una tabla vacía 
tabla_vacia <- tibble()

# edo = "09"
for(edo in claves_estados){
  
  datos_educ <- read_excel(str_c("descarga_inegi/tabulado_educacion_",
                                 edo,
                                 ".xls"), skip = 5) %>% 
    filter(!is.na(Sexo)) %>% 
    filter(Sexo == "Total") %>% 
    filter(`Grupos quinquenales de edad` == "Total") %>% 
    select(1, 2, 16) %>% 
    mutate(Año = 2010)
  
  # Solución 01: Gestionando el caso especial de el edo 09
  if(edo == "09"){
    names(datos_educ)[2] <- "Municipio"
  }
  
  # Pegado vertical de las tablas 
  tabla_vacia <- rbind(datos_educ, tabla_vacia)
  
  # Mensaje
  print(str_c("Ya se procesaron los datos de ", edo))
    
}

# Separar valores 

tabla_vacia %>% 
  mutate(clave_estado = str_extract(string = `Entidad federativa` , 
                                    pattern = "^\\d+"), 
         clave_municipio = str_extract(string = Municipio , 
                                       pattern = "^\\d+"), 
         ) %>% 
  mutate(cve_mun = str_c(clave_estado, clave_municipio)) %>% 
  mutate(`Entidad federativa` = str_remove(string = `Entidad federativa`, pattern = "^\\d+\\s")) %>% 
  mutate(Municipio = str_remove(string = Municipio, pattern = "^\\d+\\s"))





