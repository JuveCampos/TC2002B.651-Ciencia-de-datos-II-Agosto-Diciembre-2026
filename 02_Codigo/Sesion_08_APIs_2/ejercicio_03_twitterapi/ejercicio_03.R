# Utilice el API de twitterapi.io para poder extraer tweets de algún tema de interés (por ejemplo, los últimos tweets de Elon Musk).

library(usethis)
library(tidyverse)

# Para crear o editar el .Renviron: usethis::edit_r_environ()

# Librerias ----
library(httr)
library(jsonlite)
library(lubridate)
library(writexl)

# La llave se guarda en el .Renviron como TWITTERAPI_IO_KEY = "xxxx"
# Después de editarlo hay que reiniciar la sesión de R.
llave_api <- Sys.getenv("TWITTERAPI_IO_KEY")
stopifnot(nzchar(llave_api))

# Los nombres de día y mes que devuelve la API vienen en inglés
# ("Tue Sep 01 ..."), así que fijamos el locale de tiempo en C para
# poder parsear las fechas.
Sys.setlocale("LC_TIME", "C")

# Ventana de búsqueda: el informe de gobierno de ayer ----

# La API acepta since_time y until_time en segundos unix (UTC), así que
# definimos el día completo del 1 de septiembre de 2026 en hora del
# centro de México y lo convertimos a unix.
inicio <- as.POSIXct("2026-09-01 00:00:00", tz = "America/Mexico_City")
fin <- as.POSIXct("2026-09-02 00:00:00", tz = "America/Mexico_City")

inicio_unix <- as.numeric(inicio)
fin_unix <- as.numeric(fin)

# La consulta usa los mismos operadores de la búsqueda avanzada de X:
# comillas para frases exactas, OR para alternativas, lang: para idioma
# y -filter:retweets para excluir retuits (que duplican el texto).
consulta <- paste0(
  '("informe de gobierno" OR "Segundo Informe" OR #InformeDeGobierno ',
  'OR #InformePresidencial) ',
  '(Sheinbaum OR "Claudia Sheinbaum" OR @Claudiashein) ',
  'lang:es -filter:retweets ',
  'since_time:', inicio_unix, ' until_time:', fin_unix
)

print(paste0("Consulta enviada a la API: ", consulta))

# Descarga paginada ----

# Cada página devuelve un máximo de 20 tuits y un cursor para pedir la
# siguiente. Limitamos el número de páginas para no gastar créditos de
# más durante la clase.
max_paginas <- 25
cursor <- ""
pagina <- 1
bolsa_tweets <- tibble()

repeat {

  solicitud <- GET(
    url = "https://api.twitterapi.io/twitter/tweet/advanced_search",
    add_headers("X-API-Key" = llave_api),
    query = list(
      query = consulta,
      queryType = "Latest",
      cursor = cursor
    )
  )

  stop_for_status(solicitud)

  respuesta <- fromJSON(content(solicitud, "text", encoding = "UTF-8"),
                        flatten = TRUE)

  # Cuando ya no hay resultados, tweets llega como lista vacía.
  if (length(respuesta$tweets) == 0) break

  bolsa_tweets <- bind_rows(bolsa_tweets, as_tibble(respuesta$tweets))

  print(paste0("Página ", pagina, ": ", nrow(bolsa_tweets),
               " tuits acumulados."))

  # Condiciones de salida: la API avisa que ya no hay más páginas, el
  # cursor viene vacío o alcanzamos el tope que nos fijamos.
  if (!isTRUE(respuesta$has_next_page)) break
  if (is.null(respuesta$next_cursor) || respuesta$next_cursor == "") break
  if (pagina >= max_paginas) break

  cursor <- respuesta$next_cursor
  pagina <- pagina + 1

  # Pausa breve para no saturar el servicio.
  Sys.sleep(1)

}

# Limpieza y ordenamiento ----

tweets_informe <- bolsa_tweets %>%
  distinct(id, .keep_all = TRUE) %>%
  mutate(
    fecha_utc = as.POSIXct(createdAt,
                           format = "%a %b %d %H:%M:%S %z %Y",
                           tz = "UTC"),
    fecha_cdmx = with_tz(fecha_utc, "America/Mexico_City")
  ) %>%
  select(
    id,
    fecha_cdmx,
    usuario = author.userName,
    nombre = author.name,
    seguidores = author.followers,
    texto = text,
    likes = likeCount,
    retweets = retweetCount,
    respuestas = replyCount,
    vistas = viewCount,
    url
  ) %>%
  arrange(desc(fecha_cdmx))

print(paste0("Se recuperaron ", nrow(tweets_informe),
             " tuits publicados el 1 de septiembre de 2026."))

# Los diez tuits más recientes
tweets_informe %>%
  slice_head(n = 10) %>%
  select(fecha_cdmx, usuario, texto)

# Los diez tuits con más interacción
tweets_informe %>%
  arrange(desc(likes)) %>%
  slice_head(n = 10) %>%
  select(usuario, likes, retweets, texto)

# Volumen de publicación por hora ----
tweets_informe %>%
  mutate(hora = floor_date(fecha_cdmx, "hour")) %>%
  count(hora) %>%
  ggplot(aes(x = hora, y = n)) +
  geom_col(fill = "#1E4C7D") +
  labs(
    title = "Tuits sobre el informe de gobierno por hora",
    subtitle = "1 de septiembre de 2026, hora del centro de México",
    x = NULL,
    y = "Número de tuits",
    caption = "Fuente: twitterapi.io. Cálculos propios."
  ) +
  theme_minimal()

# Guardamos el resultado para no volver a consumir créditos de la API.
# La fecha se escribe como texto para que ni Excel ni readr la
# reinterpreten en UTC al abrir el archivo.
tweets_exportar <- tweets_informe %>%
  mutate(fecha_cdmx = format(fecha_cdmx, "%Y-%m-%d %H:%M:%S"))

write_csv(tweets_exportar, "tweets_informe_gobierno_20260901.csv")
write_xlsx(tweets_exportar, "tweets_informe_gobierno_20260901.xlsx")
