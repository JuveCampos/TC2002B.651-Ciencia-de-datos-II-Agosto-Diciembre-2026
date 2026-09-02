
respuesta <- GET("https://api.open-meteo.com/v1/forecast?latitude=19.35&longitude=-99.25&hourly=temperature_2m")

respuesta <- GET("https://api.open-meteo.com/v1/forecast",
                 query = list("latitude"= 19.28,
                              "longitude"= -99.13,
                              "hourly"= "temperature_2m",
                              "timezone"= "America/Denver"))

json <- content(respuesta, "text")
datos <- fromJSON(json, flatten = TRUE)

# Extraemos del JSON de respuesta el tiempo, la temperatura y generamos una nueva tabla
time <- datos$hourly$time
temp <- datos$hourly$temperature_2m
temperatura_tec_csf <- tibble(time, temp) %>%
  mutate(time = as_datetime(time, format = "%Y-%m-%dT%H:%M"))

# Corrección de hora ----
# temperatura_tec_csf <- tibble(time, temp) %>%
#   mutate(time = as_datetime(time, format = "%Y-%m-%dT%H:%M", tz = "UTC"),
#          time = with_tz(time, tzone = "America/Mexico_City"))


# La segunda función nos ayuda a pasar de texto a fecha/hora
# %Y-%m-%dT%H:%M significa Año-mes-diaThora:minuto

temperatura_tec_csf

# Hacemos la gráfica.
# Esta gráfica va a variar dependiendo el día que corramos este código
plt <- temperatura_tec_csf %>%
  ggplot(aes(x = time, y = temp, group = 1)) +
  geom_line() +
  scale_x_datetime(date_breaks = "day", date_labels = "%d-%B %H:00") +
  theme(axis.text = element_text(angle = 90))

plotly::ggplotly(plt)

