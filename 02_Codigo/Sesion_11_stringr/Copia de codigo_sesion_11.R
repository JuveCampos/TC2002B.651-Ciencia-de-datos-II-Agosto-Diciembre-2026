# Código para manipulación de texto.
# Sesión 11: Texto.
# Sesión práctica.

# Librerías ----
library(stringr)
library(stringi)
library(dplyr)
library(tidyr)

# Datos de trabajo ----

library(sf)
munis_shp <- read_sf("https://raw.githubusercontent.com/JuveCampos/Shapes_Resiliencia_CDMX_CIDE/master/geojsons/Division%20Politica/mpios2.geojson")

# Nombres de municipios escritos mal a propósito: espacios de más, mayúsculas
# inconsistentes, prefijos sueltos y acentos que a veces están y a veces no.
municipios_sucios <- c(
  "  Mpio. de Aguascalientes ",
  "AGUASCALIENTES",
  "Cd.  Juárez",
  "cd. juarez",
  "San  Luis   Potosí",
  "SAN LUIS POTOSI",
  "Mpio. Guadalajara",
  "Guadalajara  ",
  "Oaxaca de Juárez",
  "oaxaca de juárez",
  "Mpio. de Mérida",
  "mérida",
  " Tlalnepantla de Baz",
  "TLALNEPANTLA DE BAZ",
  "Cd. Victoria",
  "Ciudad Victoria"
)

# Claves de entidad y municipio como suelen llegar en archivos de Excel:
# a veces con cero a la izquierda y a veces sin él.
claves_entidad <- c("1", "01", "9", "09", "15", "32")
claves_municipio <- c("1", "001", "39", "039", "120", "7")


# CURP ficticias (ninguna corresponde a una persona real... creo). Tres son inválidas
# a propósito: una en minúsculas, una con sexo "X" y una con fecha incompleta.
curps <- c(
  "CAFJ900515HDFMRR09",
  "LOPM851230MDFRRN02",
  "cafj900515hdfmrr09",
  "GARA020318HOCRRL07",
  "HEMS781101MJCRRN04",
  "LOPM851230XDFRRN02",
  "MARA0203HOCRRL07",
  "TOVR950724HNLRRD01"
)

# Un texto para el ejercicio de palabras
parrafo <- "El texto es el dato más abundante y el menos aprovechado."

# BLOQUE 1. Básicos: guardar, pegar, medir, cortar, contar

# Ejercicio 01, guarda el siguiente string:
# Guarda esta cita exactamente así, con las comillas dobles incluidas:
#   "No room! No room!" they cried out
# Pista: hay dos formas, con comillas simples por fuera o escapando con \"

cita <- ___

# --- E2. Pegar strings con str_c() y str_glue() -------------------------------
# Construye el texto "Clave 01: Aguascalientes" a partir de estas dos piezas.
clave <- "01"
nombre <- "Aguascalientes"

etiqueta <- ___
etiqueta

# Ahora lo mismo con str_glue(), que rellena {campos} dentro del texto
etiqueta_glue <- ___
etiqueta_glue


# str_c() es vectorizado: pega elemento por elemento
str_c("Entidad ", claves_entidad) # A ver que dió

# Y propaga los NA, a diferencia de paste()
str_c("Hola ", c("mundo", NA))
paste("Hola ", c("mundo", NA))


# Ahora un ejemplo más complejo, con descripciones de personas:
p <- tribble(
  ~Nombre, ~Edad, ~Personalidad, ~Intereses, ~Objetivos,
  "Alice", 32, "Inteligente, observadora, puede ser melancólica", "Planeta, estrellas, investigación", "Descubrir nuevos mundos.",
  "Benjamin", 45, "Analítico, curioso, se enfoca en el pasado", "Cartas, mapas, genealogía", "Determinar la verdad de la historia.",
  "Chloe", 28, "Libre, extrovertida, espontánea", "Clubs de baile, tecnología, música", "Encontrar formas de expresar su creatividad.",
  "Dave", 51, "Reflexivo, curioso, siempre investiga", "Historia de Roma, arquitectura, arte", "Aprender sobre el pasado.",
  "Elise", 30, "Creativa, introvertida, aprecia la belleza", "Arte digital, arte conceptual, diseño de paisajes", "Crear obras de arte únicas."
)

# Genera, con str_glue(), las descripciones de estas personas.

___

# --- E3. Medir con str_length()  ---------------------------------
# ¿Cuántos caracteres tiene "México 🌮"? ¿Cuántas columnas ocupa en pantalla?
pais <- "México \U1F32E"

utf8ToInt(pais) # Letras Unicode

writeLines(pais)
str_length(pais)

# ¿Y cuales son las longitudes de las curps?
___


# --- E4. Cortar por posición con str_sub() ------------------------------------
# En una CURP las posiciones 5 y 6 son el año, 7 y 8 el mes, 9 y 10 el día,
# y la posición 11 es el sexo (H o M). Extrae esas cuatro piezas de curps.

anio <- ___
mes <- ___
dia <- ___
sexo <- ___

# Armamos la tabla resultante
tibble(curp = curps, anio, mes, dia, sexo)

# Los índices negativos cuentan desde el final: el último dígito verificador
str_sub(curps, -1, -1)

# --- E5. Contar con str_count() -----------------------------------------------
# Cuenta cuántas vocales tiene cada fruta del vector fruit (viene con stringr).
# "[aeiou]" es un patrón: significa "cualquiera de estas letras". En el
# bloque 4 vamos a ver de dónde sale esa sintaxis.

___

# ¿Cual es el patrón regex para contar palabras individuales en un texto?
# Cuente cuantas palabras hay en el objeto "parrafo"
str_count(parrafo, pattern = "___")
parrafo

# --- E6. Exprimir espacios con str_squish() -----------------------------------
# Quita los espacios sobrantes al inicio, al final y entre palabras.

municipios <- ___
municipios

# str_trim() solo quita los de las orillas; compara los resultados:
str_trim("  San  Luis   Potosí  ")
str_squish("  San  Luis   Potosí  ")

# --- E7. Quitar texto con str_remove() ----------------------------------------
# Quita el prefijo "Mpio. de " y "Mpio. " de los municipios.
# Primer intento: así como está.

str_remove(municipios, "Mpio. de ")

# --- E8. Reemplazar con str_replace() -----------------------------------------
# Cambia "Cd." por "Ciudad" (sin importar mayúsculas: hay un "cd." también).
# Pista: fixed() acepta ignore_case = TRUE

patron_cd <- fixed("Cd. ", ignore_case = TRUE)
municipios <- ___
municipios

# str_replace() cambia la primera coincidencia; str_replace_all() todas
str_replace("a-b-c", "-", " ")
str_replace_all("a-b-c", "-", " ")

# --- E9. Valores únicos con str_unique() --------------------------------------
# ¿Cuántos municipios distintos hay en realidad? Ignora mayúsculas y acentos.
# Pista: ignore_case = TRUE ignora mayúsculas. Para ignorar también los
# acentos se usa strength = 1 (un argumento del comparador de ICU).

municipios_sucios # Los municipios de arriba
municipios_unicos <- ___
municipios_unicos
length(municipios_unicos)

# --- E10. Partir strings con str_split() --------------------------------------
# Parte la fecha en sus tres piezas.
fecha <- "2026-10-05"
___

# str_split() devuelve una lista. Con simplify = TRUE devuelve una matriz,
# que es lo que quieres cuando cada elemento tiene el mismo número de piezas.
fechas <- c("2026-10-05", "2025-01-20", "2024-12-31")

piezas <- ___
piezas

# La función separate también nos ayuda a romper este tipo de strings
tibble(fechas)


# --- E11. Rellenar con str_pad() ----------------------------------------------
# Para unir con un shapefile de INEGI, la clave de entidad debe tener dos
# dígitos y la de municipio tres, con ceros a la izquierda.

munis_shp

cve_ent <- ___
cve_mun <- ___

tibble(claves_entidad, cve_ent, claves_municipio, cve_mun)

# --- E12. Mayúsculas y minúsculas ---------------------------------------------
# Convierte en mayúsculas y en minúsculas los textos de los municipios
municipios_mayusculas <- ___
municipios_minusculas <- ___

# Deja todos los municipios en formato de título ("San Luis Potosí").

municipios_titulo <- ___
municipios_titulo

# Ojo con las preposiciones: str_to_title() pone "De" en mayúscula.
# str_to_sentence() solo pone en mayúscula la primera letra.
str_to_sentence("OAXACA DE JUÁREZ")
str_to_upper("Mérida")
str_to_lower("MÉRIDA")

# --- E13. Etiquetas con str_wrap() y str_trunc() ------------------------------
# Para etiquetar un mapa, parte los nombres largos en líneas de máximo 12
# caracteres. Para una tabla, recórtalos a 15 caracteres.
largo <- "Tlalnepantla de Baz"

# ¿Cual es el municipio con el nombre más largo?

# --- E14. Detectar con str_detect() y ver con str_view() ----------------------
# ¿Qué frutas contienen "berry"?

tiene_berry <- ___
fruit[tiene_berry]

# str_view() marca en la consola exactamente qué parte coincidió
str_view(fruit, "berry")

# Ahora el problema: quiero las frutas que TERMINAN en "berry", no las que
# lo contienen. Con texto literal no se puede. Para eso están los patrones.

# --- Sintaxis mínima de expresiones regulares ---------------------------------
#   ^      inicio del string          $      fin del string
#   .      cualquier carácter         [abc]  uno de estos caracteres
#   [^abc] cualquiera menos estos     \\d    un dígito
#   \\w    letra, dígito o _          \\s    espacio
#   +      uno o más                  *      cero o más
#   ?      cero o uno                 {3}    exactamente tres
#   a|b    a o b                      (ab)   grupo
#
# En R la diagonal invertida se escribe doble: "\\d", no "\d".

str_view(fruit, "berry$")

# --- E16. Validar una CURP con un patrón generado por IA ----------------------
# Pídele a un LLM: "regex para validar una CURP mexicana". Una respuesta
# típica es la de abajo. Úsala con str_detect() para encontrar las inválidas.
patron_curp <- "^[A-Z]{4}\\d{6}[HM][A-Z]{2}[B-DF-HJ-NP-TV-Z]{3}[A-Z0-9]\\d$"

es_valida <- ___
tibble(curp = curps, es_valida)

# Las tres inválidas:
curps[!es_valida]

# --- E17. Extraer con str_extract() -------------------------------------------
# Saca la primera palabra de cada oración de sentences (viene con stringr).
# Pista: "inicio, y luego una o más letras"

sentences
primera <- ___
head(primera)

# ¿Y la última? Termina en punto, así que el punto va en el patrón
head(str_extract(sentences, ___))

# str_extract() saca la primera coincidencia; str_extract_all() todas
str_extract_all("Tel. 555-123-4567 y 555-987-6543", "\\d{3}-\\d{3}-\\d{4}")


# --- E18. Capturar piezas con str_match() -------------------------------------
# Repite E4 pero con un patrón: captura las cuatro letras, año, mes, día y
# sexo. Cada paréntesis es un grupo y str_match() devuelve una columna por
# grupo. La diferencia con str_sub(): si la CURP está mal, obtienes NA en
# lugar de basura.


piezas_curp <- ___
colnames(piezas_curp) <- c("curp_inicio", "letras", "anio", "mes", "dia",
                           "sexo")
piezas_curp


# The Importance of Being Earnest, de Oscar Wilde, en texto plano de Project
# Gutenberg. Objetivo: contar cuántos parlamentos tiene cada personaje.

obra <- readLines("importance-of-being-earnest.txt", encoding = "UTF-8")
# class(obra)
length(obra)

# Paso 1: quitar el encabezado y el pie de Project Gutenberg.
inicio <- ___
fin <- ___
obra <- obra[(inicio + 1):(fin - 1)]


# Paso 2: quedarnos solo con la obra, que empieza en "FIRST ACT"
primer_acto <- ___
obra <- obra[primer_acto:length(obra)]

# Paso 3: quitar líneas vacías
obra <- obra[obra != ""]
head(obra, 15)

# Paso 4: un diálogo empieza con el nombre del personaje y un punto:
# "Algernon.  Did you hear what I was playing, Lane?"
# Patrón: inicio, mayúscula, letras minúsculas, punto.

patron_personaje <- ___
str_view(obra, patron_personaje, match = TRUE)

# Paso 5: ¿qué se nos cuela? Mira lo que coincide y no es personaje
head(str_subset(obra, patron_personaje), 30)

# Paso 6: restringir a los personajes reales con alternación
personajes <- c("Algernon", "Jack", "Lane", "Cecily", "Gwendolen",
                "Chasuble", "Merriman", "Lady Bracknell", "Miss Prism")
patron_personaje <- ___
patron_personaje

# Paso 7: extraer el nombre y contar
nombres <- ___
nombres <- str_remove(nombres, fixed("."))
dialogos <- sort(table(nombres), decreasing = TRUE)
dialogos

# catcidents: 40 narrativas de accidentes relacionados con gatos (en inglés,
# con mayúsculas al azar). Cada una empieza con edad, unidad y sexo:
# "79yOf", "21 YOF", "32YOM". Objetivo: una tabla con edad y sexo.
# Obtenga cuantos accidentes hubo,
# cual es la edad promedio de los accidentados y
# el sexo de los accidentados.
# También cuantos accidentes involucraron a un perro.


catcidents <- readRDS("catcidents.rds")
head(catcidents, 4)


