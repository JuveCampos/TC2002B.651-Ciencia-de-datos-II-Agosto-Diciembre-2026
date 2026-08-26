# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> Existe también `AGENTS.md` en la raíz, con las convenciones generales del repositorio
> (directorios, trato de los datos, estilo, git). Este archivo no las repite: agrega lo
> que solo se descubre leyendo varios archivos a la vez.

## Qué es esto

Materiales del curso **Ciencia de Datos II (TC2002B.651)** del Tec de Monterrey,
agosto–diciembre de 2026. Es contenido didáctico, no una aplicación: no hay build,
ni tests, ni CI, ni gestor de dependencias. El "producto" son los PDF de
`01_Presentaciones/` y las carpetas de ejercicios de `02_Codigo/`.

Idioma de trabajo: español de México, tanto en el código como en los comentarios,
los README y los mensajes de commit.

## Cómo se organiza `02_Codigo/`

Cada sesión de clase vive en `Sesion_XX_Nombre/` y se subdivide en `ejercicio_01/`
a `ejercicio_04/`. Lo importante es que **el número de ejercicio identifica el tipo
de reto, no el tema**, y se reutiliza entre sesiones:

| Ejercicio | Tipo de reto | Insumo característico |
|---|---|---|
| `ejercicio_01` | Generar algo desde cero con IA | HTML suelto (`snake.html`) o una definición de *skill* |
| `ejercicio_02` | Interrogar datos ya existentes | Base SQLite o documentos `.md` |
| `ejercicio_03` | Limpieza y unión de datos tabulares | XLSX de INEGI + CSV de CONAPO |
| `ejercicio_04` | Aplicación Shiny con mapa | `insumos_alianza_ganadora/` (CSV + GeoJSON) |

Por eso `Sesion_06_Taller_vibe_coding/` es en buena medida una reedición de
`Sesion_05_Vibe_coding/`: los ejercicios 03 y 04 son copias idénticas, y solo
cambian el 01 y el 02. Antes de "arreglar" una duplicación aparente entre sesiones,
conviene confirmar con `diff -rq` que de verdad se trata de un error y no del patrón.

### Los `.zip` se desincronizan

Cada `Sesion_XX.zip` es la instantánea que se reparte a los alumnos. Hoy
`Sesion_06_Taller_vibe_coding.zip` trae `ejercicio_01/` vacío, mientras que el
directorio de trabajo ya tiene `simulador-de-calificacion/`. Al tocar archivos de
una sesión, hay que regenerar el zip o dejar constancia en el commit de que quedó
desfasado.

## Insumos que conviene conocer antes de tocarlos

### `ejercicio_02/mr_rib_eye.db` (Sesión 06)

Base SQLite de un restaurante ficticio, pensada para practicar SQL. Ocho tablas
(`sucursales`, `empleados`, `productos`, `proveedores`, `ventas`, `detalle_ventas`,
`compras_proveedores`, `nomina`) y tres vistas ya definidas
(`resumen_ventas_sucursal`, `productos_mas_vendidos`, `rendimiento_empleados`).
Es deliberadamente pequeña (88 ventas, 34 empleados, marzo a agosto de 2024) y las
tablas llevan `CHECK` sobre los campos categóricos, así que cualquier inserción de
ejemplo debe respetar los valores permitidos.

```bash
sqlite3 02_Codigo/Sesion_06_Taller_vibe_coding/ejercicio_02/mr_rib_eye.db ".schema"
```

### `ejercicio_04/insumos_alianza_ganadora/`

El README de esa carpeta es el enunciado del reto y el diccionario de datos
completo; conviene leerlo antes de escribir código sobre el CSV o el GeoJSON.
Tres cosas que ahorran depuración:

- La llave de unión entre el CSV y la cartografía es `cve_edo_mpo_ine` (cinco dígitos).
- La columna `triunfo_original` es una herencia de la base fuente y **no** sirve como
  resultado: solo compara VxM contra JHH e ignora los triunfos de Movimiento Ciudadano.
  La variable correcta es `alianza_ganadora`.
- Hay `NA` esperados (San Quintín sin resultados, ocho municipios "Sin votación",
  tres empates). No son un defecto de los datos y no hay que "corregirlos".

**`00_preparar_insumos.R` no se puede volver a correr aquí.** Apunta con rutas
absolutas a `/Volumes/Extreme SSD/...` y a archivos `.rds` del INE que no están en
el repositorio. Está incluido como documentación reproducible de cómo se generaron
los insumos, no como paso de un pipeline. Los CSV y GeoJSON del repositorio son la
salida ya materializada.

### `ejercicio_01/simulador-de-calificacion/` (Sesión 06)

Copia local de la definición de una *skill* (`SKILL.md`, `calcular_rango.py`,
plantillas). Es material de enseñanza sobre cómo se escribe una skill; no lo
modifiques salvo petición explícita. `calcular_rango.py` no toma argumentos: se
edita la constante `RUBRICA` dentro del archivo y se ejecuta con `python3`.

## Verificación

No hay tests. La validación es manual y depende del insumo:

```bash
# SQL: probar la consulta contra la base
sqlite3 ruta/a/mr_rib_eye.db "SELECT ..."

# R: correr el script en RStudio o Positron, o desde la terminal
Rscript ruta/al/script.R

# HTML de vibe-coding: abrir el archivo en el navegador
open 02_Codigo/Sesion_05_Vibe_coding/ejercicio_01/snake.html
```

Para un script de R que genera insumos, la comprobación es comparar dimensiones y
primeras filas contra la versión anterior antes de sobrescribir nada.

## Git

- Mensajes de commit con fecha al frente: `[20260826] Push clase 6`.
- `.gitignore` lista los `.key` **uno por uno**, no con un patrón `*.key`. Al agregar
  una presentación nueva de Keynote hay que añadir su ruta explícita al `.gitignore`
  en el mismo commit, o se subirá el binario.
- Los `.DS_Store` ya versionados se quedan como están; no los borres en masa ni
  agregues nuevos.
- Ojo con `01_Presentaciones/Clase 06 VibeCoding/`: los archivos ahí dentro se llaman
  `Clase05_VibeCoding`. El nombre de la carpeta manda sobre el del archivo.

## Contenido del curso, para poner los ejercicios en contexto

Cuatro bloques: (1) IA generativa como herramienta de trabajo, (2) bases de datos,
(3) limpieza de texto, (4) procesamiento de lenguaje natural, hilado por la pregunta
de quién impone los temas de la discusión pública. R 4.4+ con tidyverse es el
lenguaje principal; Python y HTML aparecen solo de forma incidental. El `README.md`
tiene el temario, la evaluación y la política de uso de IA (las tres etiquetas que
marcan cuánta IA se permite en cada tarea).
