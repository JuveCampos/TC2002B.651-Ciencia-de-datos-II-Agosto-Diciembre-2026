# TC2002B.651 · Ciencia de Datos II

Materiales del curso **Ciencia de Datos II** del Tecnológico de Monterrey,
periodo agosto-diciembre de 2026. Aquí se publican las presentaciones de cada
clase, el código de los ejercicios y las guías de los exámenes.

## Estructura del repositorio

```
.
├── 01_Presentaciones/   Una carpeta por clase con el PDF (y el Keynote cuando pesa poco)
├── 02_Codigo/           Una carpeta por sesión con los ejercicios en R
├── 03_Examenes/         Guías de estudio y bancos de preguntas (solo PDF)
└── assets/              Imágenes para la portada del curso
```

### 01_Presentaciones

Cada carpeta se llama `Clase NN Tema` y contiene el archivo de la clase con
el mismo número (`ClaseNN_Tema.pdf`, `ClaseNN_Tema.key`). Dentro de cada
carpeta puede existir:

- `borradores/`: versiones intermedias y copias locales de Keynote. Esta
  carpeta **no se sube a GitHub**.
- `fuente_pptx/`: scripts de Python e imágenes que generan la presentación
  cuando ésta se construyó con código (por ahora solo la Clase 09).

| Clase | Tema |
|---|---|
| 01 | Introducción al curso |
| 02 | Conceptos de los modelos de lenguaje (LLM) |
| 03 | Discusión sobre la IA |
| 04 | Prompting |
| 05 | Vibe coding |
| 06 | Vibe coding II (taller) |
| 07 | APIs |
| 08 | APIs II (taller) |
| 09 | Web scraping |

### 02_Codigo

Cada sesión es un proyecto de RStudio (`.Rproj`) con subcarpetas
`ejercicio_NN_tema/`. Los scripts se numeran en el orden en que se ven en
clase.

| Sesión | Contenido |
|---|---|
| `Sesion_05_Vibe_coding/` | Insumos de los cuatro ejercicios de vibe coding (snake, ofertas de empleo, proyecciones CONAPO, mapa electoral 2021) |
| `Sesion_06_Taller_vibe_coding/` | Los mismos ejercicios con las soluciones trabajadas en el taller |
| `Sesion_07_APIs/` | PokeAPI y Open-Meteo con `httr` y `jsonlite` |
| `Sesion_08_APIs_2/` | INEGI (`inegiR`), precios de acciones (`tidyquant`), twitterapi.io y un modelo local con `ellmer` + Ollama (app Shiny de carta natal) |

## Credenciales y llaves de API

**Ninguna llave, token o contraseña se escribe en los scripts ni se sube al
repositorio.** Las credenciales viven en el archivo `.Renviron` de cada
persona y se leen con `Sys.getenv()`.

Para configurarlas:

```r
usethis::edit_r_environ()
```

Se agregan las variables que use cada sesión, una por línea, y se reinicia R:

```
INEGI_TOKEN = "..."
TWITTERAPI_IO_KEY = "..."
```

El `.gitignore` excluye `.Renviron`, `.Rhistory`, `.Rproj.user/`, los
archivos `.zip` y las carpetas `borradores/` y `verify/`. Antes de hacer
`git push` conviene revisar con `git status` que no se cuele ningún archivo
de sesión de RStudio.

## Requisitos

- R 4.4 o superior con `tidyverse`, `httr`, `jsonlite`, `inegiR`,
  `tidyquant`, `ellmer`, `shiny`, `future` y `promises`.
- Para el ejercicio de `ellmer`, [Ollama](https://ollama.com) corriendo en
  local con al menos un modelo descargado (`ollama pull qwen3.5:4b`).
