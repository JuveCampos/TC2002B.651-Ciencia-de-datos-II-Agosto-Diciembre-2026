# Ejemplo trabajado: rúbrica de taller de IA (100 puntos)

Este archivo muestra cómo queda la rúbrica del profesor después del Paso 1 de la
skill. Sirve como semilla, no como default: si la rúbrica de la tarea nueva
difiere, se descompone esa y no se reutiliza esta.

## Criterio 01 — Conceptos vistos en clase (20 puntos)

| # | Requisito atómico | Peso | Tipo |
|---|---|---|---|
| 1.1 | Están los 13 conceptos, sin faltar ninguno | 0.40 | D |
| 1.2 | Cada concepto ocupa de 3 a 5 líneas | 0.20 | D |
| 1.3 | Cada concepto cita su fuente | 0.20 | D |
| 1.4 | Están escritos a mano | 0.10 | D |
| 1.5 | La letra se lee a escala carta | 0.10 | N |

Nota de conteo: 13 conceptos valen 0.40 del criterio, de modo que cada concepto
faltante cuesta alrededor de 0.62 puntos del total. Doce conceptos de trece dan
nivel 0.75 en el requisito 1.1, no 1.00.

## Criterio 02 — Ingeniería de prompts (30 puntos)

| # | Requisito atómico | Peso | Tipo |
|---|---|---|---|
| 2.1 | El tema queda definido con claridad | 0.10 | J |
| 2.2 | El prompt incluye al menos 6 de los 8 elementos de la anatomía | 0.30 | D |
| 2.3 | Se documenta el metaprompting con modelo y nivel de esfuerzo | 0.20 | D |
| 2.4 | Se compara el prompt original contra el metaprompteado | 0.25 | J |
| 2.5 | La comparación está escrita sin IA | 0.05 | N |
| 2.6 | Se adjunta la salida de la IA | 0.10 | D |

Al contar el requisito 2.2 se reporta el número exacto de elementos hallados. Con
cinco de ocho el nivel baja a 0.45, porque la rúbrica fija el umbral en seis.

## Criterio 03 — Modelo de difusión (25 puntos)

| # | Requisito atómico | Peso | Tipo |
|---|---|---|---|
| 3.1 | El prompt de investigación está bien construido | 0.15 | J |
| 3.2 | Explica con exactitud qué son los modelos de difusión | 0.20 | J |
| 3.3 | Explica con exactitud cómo funcionan | 0.25 | J |
| 3.4 | Explica en qué difieren de los modelos de texto | 0.20 | J |
| 3.5 | La presentación ronda las 5 diapositivas | 0.10 | D |
| 3.6 | La presentación se elaboró sin IA | 0.10 | N |

Este criterio pesa casi todo en `J`, así que su rango se abre más que el de los
otros. Ahí es donde el resultado depende del profesor y no del archivo.

## Criterio 04 — Gasto de agua por la IA (25 puntos)

| # | Requisito atómico | Peso | Tipo |
|---|---|---|---|
| 4.1 | El artículo existe y trata el tema | 0.30 | D |
| 4.2 | Se documentan los prompts usados | 0.20 | D |
| 4.3 | Se documentan los modelos usados | 0.15 | D |
| 4.4 | Se respetó el cronómetro de 10 minutos | 0.15 | N |
| 4.5 | La presentación ronda las 5 diapositivas | 0.20 | D |

## Criterio 05 — Evento (sustituto)

Reemplaza al 02, al 03 o al 04, y toma la ponderación del que sustituya.

| # | Requisito atómico | Peso | Tipo |
|---|---|---|---|
| 5.1 | El reporte alcanza al menos una cuartilla | 0.40 | D |
| 5.2 | Está redactado con palabras propias | 0.60 | N |

Regla de decisión: conviene tomar el sustituto cuando el criterio que se
reemplazaría se quedaría por debajo de 0.60 de cumplimiento, porque el reporte de
una cuartilla es más barato de producir que cualquiera de los otros tres
ejercicios. Se calcula con números antes de recomendarlo.
