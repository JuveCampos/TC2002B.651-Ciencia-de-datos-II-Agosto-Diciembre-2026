
library(tidyquant)
library(tidyverse)
library(plotly)

# Lista de acciones del SP500:
tq_index("SP500")
datos_apple <- tq_get("AAPL",
                      get = "stock.prices",
                      from = today()-365, to = today())

grafica <- datos_apple |>
  ggplot(aes(x = date, y = adjusted)) +
  geom_line() +
  labs(title = "Precio de la acción de apple en el último año ")

ggplotly(grafica)


