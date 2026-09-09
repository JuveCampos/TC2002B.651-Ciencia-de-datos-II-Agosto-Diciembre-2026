# RAG_02: mañaneras de la presidenta como corpus para RAG

Este ejercicio construye un corpus de texto con las versiones estenográficas
de las conferencias de prensa matutinas ("mañaneras") de la presidenta
Claudia Sheinbaum, publicadas en
<https://www.gob.mx/presidencia/es/archivo/articulos>.

## Archivos

- `01_scraper_mananeras.R`: recorre el archivo de artículos de Presidencia,
  arma un índice y descarga cada mañanera como texto plano.
- `02_rag_mananeras.R`: pipeline de RAG sobre el corpus con ragnar, ellmer y
  Ollama (bge-m3 para embeddings, qwen3.5:4b como generador). Lee los textos
  con sus metadatos, fragmenta, construye el almacén DuckDB con columnas de
  fecha y URL, compara recuperación semántica, léxica e híbrida, muestra el
  filtro por fecha, genera respuestas por prompt aumentado y por herramienta,
  y evalúa hit@5 con ocho preguntas verificadas a mano.
- `Modelfile.qwen3.5-4b-8k`: variante de qwen3.5:4b con contexto de 8,192
  tokens (`ollama create qwen3.5-4b-8k -f Modelfile.qwen3.5-4b-8k`).
- `mananeras_ago_sep.ragnar.duckdb`: almacén vectorial del subconjunto de
  agosto y septiembre (se reconstruye al borrarlo).
- `mananeras/indice_mananeras.csv`: índice con fecha de la conferencia,
  título, URL, si es versión estenográfica, si es mañanera, ruta del archivo
  y número de caracteres.
- `mananeras/txt/AAAA-MM-DD_<slug>.txt`: un archivo por conferencia. Las tres
  primeras líneas son metadatos (Título, Fecha, Fuente); después viene el
  texto con un párrafo por turno de palabra y una línea en blanco entre
  párrafos. El nombre del orador aparece en mayúsculas al inicio del párrafo
  ("PRESIDENTA DE MÉXICO, CLAUDIA SHEINBAUM PARDO:", "PREGUNTA:").

## Cómo correrlo

```r
# desde la carpeta RAG_02
source("01_scraper_mananeras.R")
```

El script es incremental: si un archivo ya existe no lo vuelve a descargar.
Para ampliar el corpus se cambia `fecha_min` al inicio del script.

## Por qué chromote y no rvest directo

gob.mx protege sus páginas con un reto anti-bots de Akamai. Una petición
directa con httr2 o rvest recibe una página provisional titulada "Challenge
Validation" en lugar del contenido. Un navegador real ejecuta el JavaScript
del reto y obtiene la página, así que el script controla un Chrome sin
cabeza con `chromote`, espera a que el reto se resuelva y entrega el HTML a
`rvest` para extraer el contenido. Requiere Google Chrome instalado.

## Estado del corpus (8 de septiembre de 2026)

| Concepto | Valor |
|---|---|
| Rango de fechas | 1 de junio a 8 de septiembre de 2026 |
| Mañaneras descargadas | 71 |
| Caracteres totales | 5,996,867 |
| Promedio por conferencia | 84,463 caracteres |

El 1 de septiembre de 2026 no hubo mañanera (fecha del informe de gobierno).

## Ejercicio de RAG (subconjunto de agosto y septiembre)

| Concepto | Valor |
|---|---|
| Mañaneras | 26 (3 de agosto a 8 de septiembre de 2026) |
| Fragmentos de 1,600 caracteres con traslape de 25 % | 1,824 |
| Tiempo de embeddings con bge-m3 en una Mac de 16 GB | 2.6 minutos |
| hit@5 semántica / léxica / híbrida | 100 % / 100 % / 100 % |
| Respuesta del generador (qwen3.5:4b sin razonamiento) | 12 a 13 segundos |

Dos detalles aprendidos con ragnar 0.3.0:

- La búsqueda híbrida fusiona fragmentos traslapados del mismo documento y
  devuelve las columnas extra (fecha, título, URL) como columnas-lista; el
  script las aplana antes de filtrar o formatear. Tras esa fusión el orden de
  las filas ya no es un ranking.
- qwen3.5 razona antes de responder y tarda unos 30 segundos por pregunta
  trivial. Con `api_args = list(reasoning_effort = "none")` en `chat_ollama()`
  responde en uno o dos segundos sin perder la capacidad de usar herramientas.
