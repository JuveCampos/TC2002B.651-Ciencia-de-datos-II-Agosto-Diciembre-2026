# Insumos: Alianza ganadora a nivel municipal (México, 2021)

Esta carpeta contiene los insumos necesarios para construir una aplicación
Shiny que muestre, en un mapa interactivo, qué alianza política ganó en cada
municipio de México en la elección federal de diputaciones de 2021.

## Contexto de la elección

En la elección federal de 2021 compitieron dos grandes alianzas y un partido
que fue solo:

- **Va por México (VxM)**: coalición formada por PAN, PRI y PRD.
- **Juntos Haremos Historia (JHH)**: coalición formada por Morena, PT y PVEM.
- **Movimiento Ciudadano (MC)**: compitió sin aliarse.
- **Otros**: PES, RSP, Fuerza por México y candidaturas independientes.

La variable central del ejercicio es `alianza_ganadora`: indica cuál de estas
cuatro fuerzas obtuvo más votos en cada municipio. El resultado nacional fue:

| Alianza ganadora | Municipios |
|---|---|
| Juntos Haremos Historia | 1,496 |
| Va por México | 888 |
| Movimiento Ciudadano | 41 |
| Otros | 32 |
| Sin votación | 8 |
| Empate | 3 |

## Contenido de la carpeta

```
insumos_alianza_ganadora/
├── 00_preparar_insumos.R      # Script que generó todos los insumos (reproducible)
├── README.md                  # Este documento
├── datos/
│   └── resultados_municipales_2021.csv   # Base de resultados (2,468 municipios)
└── geo/
    ├── municipios_mexico.geojson         # Polígonos municipales nacionales (~13 MB)
    └── estados/
        ├── 01.geojson ... 32.geojson     # Un archivo por estado (más ligeros)
```

Los polígonos provienen de la cartografía municipal del INE, están en
coordenadas geográficas (EPSG:4326, lo que Leaflet espera) y ya vienen
simplificados para que el mapa cargue rápido. El geojson ya incluye las
columnas `alianza_ganadora`, `margen_pp` y `por_participacion` para poder
pintar el mapa directamente, pero se recomienda practicar la unión
(`left_join`) con el CSV usando la llave `cve_edo_mpo_ine`.

## Diccionario de datos (resultados_municipales_2021.csv)

### Identificadores

| Variable | Descripción |
|---|---|
| `cve_edo` | Clave de entidad (2 dígitos, "01" a "32") |
| `nom_edo` | Nombre de la entidad |
| `acronimo_estado` | Abreviatura de la entidad (p. ej. "Ags.") |
| `cve_mpo_ine` | Clave municipal del INE (3 dígitos) |
| `nom_mpo_ine` | Nombre del municipio |
| `cve_edo_mpo_ine` | **Llave de unión con el geojson** (5 dígitos: estado + municipio) |
| `latitude`, `longitude` | Centroide aproximado del municipio |

### Contexto sociodemográfico

| Variable | Descripción |
|---|---|
| `pob_tot` | Población total (Censo 2020) |
| `grado_prom_esco` | Grado promedio de escolaridad |
| `metro` | Indica si el municipio pertenece a una zona metropolitana (SI/NO) |

### Padrón y participación

| Variable | Descripción |
|---|---|
| `lista_nominal` | Personas en la lista nominal |
| `total_votos` | Total de votos emitidos |
| `por_participacion` | Porcentaje de participación |
| `por_abstencion` | Porcentaje de abstención |
| `participacion_h`, `participacion_m`, `participacion_j` | Participación de hombres, mujeres y jóvenes |

### Votos

| Variable | Descripción |
|---|---|
| `v_pan` ... `v_ci` | Votos por partido (con la distribución de votos de coalición ya aplicada) |
| `v_vxm` | Votos de Va por México (PAN + PRI + PRD) |
| `v_jhh` | Votos de Juntos Haremos Historia (Morena + PT + PVEM) |
| `v_otros` | Votos de PES + RSP + Fuerza por México + independientes |

### Resultado

| Variable | Descripción |
|---|---|
| `alianza_ganadora` | Fuerza con más votos: "Va por México", "Juntos Haremos Historia", "Movimiento Ciudadano", "Otros", "Empate" o "Sin votación" |
| `votos_alianza_ganadora` | Votos de la fuerza ganadora |
| `margen_pp` | Margen de victoria sobre el segundo lugar, en puntos porcentuales del total de votos |
| `triunfo_original` | Variable heredada de la base original; solo compara VxM contra JHH, por lo que **no** debe usarse como alianza ganadora (ignora los triunfos de MC) |

## Advertencias sobre los datos

- **San Quintín, Baja California** (`02006`) aparece en la cartografía pero
  no tiene resultados: el municipio se creó en 2020 y en la elección de 2021
  sus secciones se contabilizaron dentro de Ensenada. En el mapa quedará con
  valores `NA`; decidan cómo mostrarlo (gris con nota, por ejemplo).
- **8 municipios de Chiapas y Oaxaca** aparecen con la categoría
  "Sin votación": en 2021 no registraron votos (casillas no instaladas o
  votación anulada). Su `margen_pp` es `NA`.
- Existen 3 municipios con empate exacto entre las fuerzas punteras;
  conviene asignarles un color propio.
- Los porcentajes se reportan en escala 0 a 100.

## El reto: replicar la aplicación

Construyan una aplicación Shiny que incluya, como mínimo:

1. **Un mapa interactivo con `leaflet`** que pinte los municipios según la
   alianza ganadora, con una paleta consistente (sugerencia: azul VxM,
   guinda JHH, naranja MC, gris Otros/Empate).
2. **Un selector de estado** que filtre el mapa (pueden cargar el geojson
   estatal correspondiente de `geo/estados/`, como hace la app original, o
   filtrar el nacional).
3. **Ventanas emergentes (popups)** al dar clic en un municipio, con nombre,
   alianza ganadora, votos por fuerza, margen y participación.
4. **Al menos una vista adicional**: tabla filtrable, gráfica de barras por
   estado o conmutador para colorear por margen o por participación en vez
   de por ganador.

Extensiones opcionales: autenticación con `shinyauthr` (sin escribir las
contraseñas en el código), descargas en CSV, o una capa de análisis de
municipios competidos (`margen_pp` bajo).

### Paquetes sugeridos

```r
install.packages(c("shiny", "leaflet", "sf", "dplyr", "readr", "DT"))
```

### Ejemplo mínimo de arranque

```r
library(sf)
library(dplyr)
library(readr)
library(leaflet)

mpios <- st_read("geo/municipios_mexico.geojson")
resultados <- read_csv("datos/resultados_municipales_2021.csv")

pal <- colorFactor(
  palette = c("#9E9E9E", "#8B1E3F", "#FF8300", "#616161", "#D6D6D6",
              "#0D47A1"),
  domain = c("Empate", "Juntos Haremos Historia", "Movimiento Ciudadano",
             "Otros", "Sin votación", "Va por México")
)

leaflet(mpios) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(
    fillColor = ~pal(alianza_ganadora),
    fillOpacity = 0.7,
    color = "white",
    weight = 0.5,
    label = ~paste0(nom_mpo, ": ", alianza_ganadora)
  ) %>%
  addLegend(pal = pal, values = ~alianza_ganadora,
            title = "Alianza ganadora")
```

## Sugerencia de prompt de arranque (vibe-coding)

> Construye una aplicación Shiny en R. En la carpeta `geo/` tengo un geojson
> con los municipios de México (`municipios_mexico.geojson`, EPSG:4326, llave
> `cve_edo_mpo_ine`) y en `datos/resultados_municipales_2021.csv` tengo los
> resultados de la elección federal de 2021 por municipio, con la variable
> `alianza_ganadora` (lee el README para el diccionario completo). Quiero un
> mapa con leaflet coloreado por alianza ganadora, un selector de estado, un
> conmutador para colorear por margen de victoria o participación, popups
> con el detalle de votos de cada municipio y una tabla filtrable con DT.
> Usa tidyverse y comenta el código en español.

## Fuentes

- Resultados: cómputos distritales de la elección federal de diputaciones
  2021 (INE), procesados en la base del proyecto original.
- Cartografía: marco geográfico electoral del INE (cartografía municipal).
- Población y escolaridad: Censo de Población y Vivienda 2020 (INEGI).
