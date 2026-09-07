> Este documento es el plan real con el que se armó el reel de la semana
> del 24 al 28 de agosto de 2026. Sirve como respuesta de referencia para la
> práctica. Las rutas ya apuntan a la estructura de esta carpeta. El video
> base original pesaba 234 MB a 12 Mbps; aquí viaja recomprimido a 26 MB
> con la misma resolución, duración y cuadros por segundo.

# Plan de edición — Agenda económica 24–28 de agosto de 2026

Estado: Fase 2 ejecutada y exportada el 21 de agosto de 2026. Falta la
revisión de Juvenal (Fase 3). El detalle de lo ejecutado está al final del
documento.

## Datos verificados (ffprobe)

- Video base: `01_video_base/video_base_1280x720.mp4`
  1280x720, 30 fps CFR, 154.90 s, H.264 + AAC 48 kHz estéreo.
- Clip de cierre: `05_cierre/reel_mcv_morada_1080x1920_3s.mp4`
  1080x1920, 30 fps, 3.00 s.
- Transcripción usada como fuente de verdad:
  `02_transcripcion/bloques_subtitulo.csv` (47 bloques)
  y `palabras_con_duracion.csv` para los cortes finos.
- Duración final estimada: 157.90 s (2:37.9).

## Decisiones aprobadas por Juvenal (21 de agosto de 2026)

1. Reencuadre: recorte central 9:16 a pantalla completa, se asume la pérdida
   por escalar 2.67x. Aplicar sharpening ligero.
2. Viernes y dato del 70%: sin gráfica, solo badge del día.
3. Badge del día: esquina superior **izquierda**, x = 40, y = 40, lo más
   arriba posible. Juvenal revocó el 21 de agosto la posición previa
   (superior derecha, y = 240): prevalece esta.
4. Permanencia mínima de cada gráfica: 2.5 s.
5. Las gráficas entran **a pantalla completa** (cutaway), no superpuestas:
   el encuadre no deja hueco libre. Ancho 1000 px (margen lateral de 40 px),
   centradas en la zona segura vertical, con el video de fondo desenfocado.
6. Cierre con **fundido de 0.3 s** hacia el clip institucional.
7. Se **quita** la gráfica de salarios formal/informal del arranque: traía
   datos del 2T 2023. Los primeros 3.68 s van solo a cámara.
8. En la fila 9 se usa `informalidad_por_sexo.png` desde el 48.88.

## Tabla de mapeo

| #  | Inicio | Fin    | Fragmento del diálogo | Asset | Badge |
|----|--------|--------|-----------------------|-------|-------|
| 1  | 0.00   | 3.68   | Un trabajo formal paga el doble que un informal | a cámara (gráfica retirada, dato 2023) | — |
| 2  | 3.94   | 8.56   | Más de la mitad están en la informalidad | 00/tasa_informalidad_serie_trimestral.png | — |
| 3  | 8.82   | 22.24  | Presentación y "del 24 al 28 de agosto" | a cámara | — |
| 4  | 22.44  | 25.48  | El lunes es día cargado de información | a cámara | 24_ago_lunes |
| 5  | 25.48  | 28.10  | Sale el PIB del segundo trimestre | 01/pib_crecimiento_anual_trimestre.png | 24_ago_lunes |
| 6  | 28.10  | 30.70  | Inflación de la primera quincena de agosto | 01/inflacion_general_anual.png | 24_ago_lunes |
| 7  | 30.70  | 33.30  | Y la actividad económica de junio | 01/igae_variacion_anual.png | 24_ago_lunes |
| 8  | 33.30  | 41.04  | Dos semáforos y mexicocomovamos.mx | a cámara | 24_ago_lunes |
| 9a | 41.04  | 48.88  | El martes viene lo bueno, la ENOE | a cámara | 25_martes |
| 9b | 48.88  | 52.28  | Cómo avanzó la formalidad y cuánto ganan | 02/informalidad_por_sexo.png | 25_martes |
| 9c | 52.28  | 60.76  | Se actualiza al 2T, dos pendientes estructurales | a cámara | 25_martes |
| 10 | 60.76  | 68.42  | El 54.8% trabaja sin prestaciones ni seguridad social | 02/informalidad_serie_trimestral_alt.png | 25_martes |
| 11 | 68.42  | 77.12  | Brecha de casi 30 puntos en participación de mujeres | 02/brecha_participacion_mujeres_hombres_v2.png | 25_martes |
| 12 | 77.12  | 83.90  | Casi el 70% del ingreso de las familias viene del trabajo | **SIN ASSET** | 25_martes |
| 13 | 83.90  | 87.22  | El miércoles toca revisar pobreza laboral | a cámara | 26_miercoles |
| 14 | 87.22  | 93.00  | El ingreso no alcanza para la canasta alimentaria | 03/ingreso_laboral_vs_linea_pobreza.png | 26_miercoles |
| 15 | 93.00  | 99.44  | Marcó su mínimo histórico | 03/pobreza_laboral_porcentaje_serie.png | 26_miercoles |
| 16 | 99.44  | 102.36 | Más de 40 millones de personas | 03/pobreza_laboral_millones_personas.png | 26_miercoles |
| 17 | 102.36 | 106.80 | La salida es crear más empleos formales | 03/pobreza_laboral_hogar_con_un_formal.png | 26_miercoles |
| 18 | 106.80 | 109.88 | Sale la balanza comercial de julio | 04/balanza_comercial_saldo.png | 27_jueves |
| 19 | 109.88 | 112.70 | La ENOE mensual de julio | 04/enoe_mensual_desocupacion.png | 27_jueves |
| 20 | 112.70 | 116.16 | El informe trimestral de Banxico | 04/expectativas_banxico_crecimiento.png | 27_jueves |
| 21 | 116.16 | 119.32 | Los riesgos para el crecimiento y la inflación | 04/expectativas_banxico_inflacion.png | 27_jueves |
| 22 | 119.32 | 136.54 | El viernes, finanzas públicas, ISR 4 de cada 10 | **SIN ASSET** (decidido: solo badge) | 28_viernes |
| 23 | 136.54 | 154.42 | Llamado a redes y despedida | a cámara | — |
| 24 | 154.90 | 157.90 | Clip institucional (fundido de 0.3 s a la entrada) | reel_mcv_morada_1080x1920_3s.mp4 | — |

Todas las gráficas cumplen la permanencia mínima de 2.5 s.
Total: 16 gráficas, 5 badges, 1 clip de cierre.

## Layout sobre el lienzo de 1080x1920

- Zonas seguras respetadas: 220 px arriba, 320 px abajo, 130 px a la derecha.
- Video base: recorte central 9:16 (405x720 -> 1080x1920, lanczos + sharpening
  ligero) como capa de fondo.
- Gráficas: a pantalla completa, 1000 px de ancho (aprox. 1000x563 al ser
  16:9), centradas horizontalmente, centro vertical en y=910 (ocupan de
  y=628 a y=1191). Fade in/out de 0.3 s. Detrás, el video desenfocado.
- Badge del día: esquina superior **izquierda**, 360 px de ancho (360x182),
  en x=40, y=40. Queda dentro de la franja insegura superior de 220 px por
  indicación expresa de Juvenal.
- Subtítulos quemados: máximo 2 líneas, entre y=1450 y y=1600. Se generan
  desde `bloques_subtitulo.csv`, sin retranscribir.

## Assets del proyecto que quedan sin usar (10)

salario_por_condicion_formalidad (retirada por dato de 2023),
pib_evolucion_serie, inflacion_subyacente, igae_actividad_economica,
participacion_laboral_por_sexo,
brecha_participacion_mujeres_hombres_v1, canasta_alimentaria_LPEI,
pobreza_laboral_por_formalidad_matriz, enoe_mensual_brecha_participacion,
exportaciones_mensuales.

## Pendientes

- **Reiniciar Claude Code** para que carguen las herramientas del MCP de
  Palmier (ya quedó registrado en el ámbito local de esta carpeta).
- Verificar dentro de Palmier: que el proyecto esté en 1080x1920 y que los
  32 archivos del plan estén importados.
- Fila 12 (77.12–83.90, el 70% del ingreso familiar) y fila 22 (viernes,
  finanzas públicas) van sin gráfica por decisión tomada: no existe infobite
  que corresponda al dato.

---

## Fase 2 ejecutada — 21 de agosto de 2026

Fase 1 aprobada por Juvenal. El timeline se armó en Palmier Pro, en el
proyecto `~/Documents/Palmier Pro/Agenda economica 24-28 ago 2026.palmier`,
a 1080x1920 y 30 fps, con los 32 archivos importados.

### Estructura de pistas (índice 0 arriba)

| Pista | Nombre | Contenido |
|---|---|---|
| V6 | Subtitulos | 82 cues desde `subtitulos_2lineas.srt`, Ubuntu Regular 48 pt, y = 0.794 (centro 1525 px) |
| V5 | Outro | clip institucional, frames 4638–4728 |
| V4 | Badges | 5 badges de calendario |
| V3 | Graficas | 15 gráficas a pantalla completa |
| V2 | Fondo | 5 copias del video base con desenfoque gaussiano de 32 px |
| V1 | Main | video base recortado 9:16, sharpening 0.35 |
| A1 | Dialogue | audio del video base |
| A2 | Extras | audios de fondo silenciados a −60 dB y audio del cierre |

### Parámetros aplicados

- Video base: `width = 3.16` normalizado (equivale al recorte central de
  405x720 escalado 2.67x), centrado.
- Gráficas: `width = 0.926` (1000 px), `height = 0.293` (562.5 px),
  centro vertical en `y = 0.474` (910 px).
- Badges: `width = 0.333` (360 px), `centerX = 0.204` (x = 40 px), alto
  proporcional a cada archivo porque no comparten proporción. El alto
  resultante va de 142 px (miércoles) a 182 px (lunes), siempre con el
  borde superior en y = 40.
- Duración total: 157.6 s (4728 frames).

### Subtítulos re-segmentados

El SRT original (`subtitulos.srt`, 47 bloques de hasta 72 caracteres) se
desbordaba a tres y cuatro líneas con la tipografía de 48 pt, contra el
máximo de dos líneas que fijaba el plan. Se generó `subtitulos_2lineas.srt`
con el script `02_transcripcion/resegmentar_subtitulos.py`, que
reagrupa las palabras de `palabras_con_duracion.csv` sin retranscribir.

El corte no se decide contando caracteres sino midiendo el ancho real del
texto con la tipografía con la que se rinden, porque una M mide casi el
triple que una i: un límite de 26 caracteres dejaba pasar líneas de 582 px
que sí se desbordaban. El tope quedó en 515 px medidos.

La tipografía de los subtítulos es **Ubuntu Regular a 48 pt** (nombre
PostScript `Ubuntu-Regular`, instalada en `~/Library/Fonts`). Ubuntu corre
entre 1% y 4% más ancha que Helvetica, lo bastante para desbordar una línea
que estaba al límite, así que el script mide con el archivo de Ubuntu y el
SRT se regeneró con esas métricas. Si en el futuro se cambia de tipografía
hay que volver a correrlo: las métricas no se trasladan entre familias.
Se verificó en pantalla el cue de dos líneas más ancho ("El jueves sale la
balanza / comercial de julio, la", 514 px, frame 3250) y el de una línea más
ancho ("base que nos dice cómo", 513 px, frame 1452).

El script respeta los límites de los bloques originales, corta en cuanto el
texto deja de caber en dos líneas y fusiona los fragmentos que quedaban por
debajo de 0.8 s, primero hacia atrás y después hacia adelante. El resultado
son 82 cues, ninguno de más de dos líneas, con duración media de 1.81 s.
Solo dos quedan por debajo de 0.6 s porque el siguiente entra de inmediato y
no hay hueco para estirarlos.

### Desviaciones respecto de la Fase 1

1. **Gráficas: 15, no 16.** La cuenta de 16 del plan incluía la de salarios
   formal/informal que se retiró por traer datos del 2T 2023. Descontada
   esa, quedan 15.
2. **Fundido del cierre.** El clip institucional se solapa 0.3 s con el
   video a cámara (arranca en el frame 4638) para que el fundido cruce
   desde la imagen. Si arrancara en 154.90 s como decía el plan, esos
   9 frames fundirían desde negro. La diferencia deja el total en 157.6 s
   en lugar de 157.9 s.
3. **Fundidos entre gráficas contiguas.** El plan pedía fundido de entrada
   y salida de 0.3 s en cada gráfica. Aplicado literalmente, entre dos
   gráficas seguidas (por ejemplo PIB, inflación e IGAE del lunes) habría
   0.6 s de fondo desenfocado sin gráfica. Se aplicó el fundido solo al
   entrar y salir de cada bloque de gráficas, con corte seco entre las
   contiguas del mismo bloque.
4. **Sombra en los subtítulos.** El blanco liso perdía contraste sobre el
   fondo desenfocado claro. Se agregó sombra negra al 65% con desenfoque
   de 12 px.
   
5. **Desenfoque progresivo.** Las capas de fondo entran y salen con
   fundido de 0.3 s, de modo que el desenfoque aparece como disolvencia y
   no como corte.

### Hallazgo pendiente de tu decisión

El archivo `03_miercoles_pobreza_laboral/ingreso_laboral_vs_linea_pobreza.png`
no contiene lo que su nombre anuncia: la imagen es la del valor de la
canasta alimentaria del Coneval, la misma pieza que `canasta_alimentaria_LPEI.png`.
En la fila 14 (87.22–93.00 s) acompaña la frase "el ingreso no alcanza para
la canasta alimentaria", así que calza con lo que se dice, pero conviene
decidir si se sustituye por una gráfica que sí compare ingreso laboral
contra línea de pobreza.

### Entregable

`agenda_economica_24-28_ago_2026_v4_ubuntu.mp4`, H.264 1080x1920 a 30 fps,
157.6 s, audio AAC 48 kHz estéreo, alrededor de 198 MB. Las versiones v1 a
v3 son iteraciones previas de los subtítulos (v1 y v2 con la segmentación
que se desbordaba, v3 con Helvetica) y se pueden borrar.

Queda pendiente la Fase 3: tu revisión del video completo.

---

## Cambios pedidos el 21 de agosto de 2026, después de la primera revisión

### Corrección de la transcripción

La transcripción automática oyó "análisis más especiales" donde en realidad
se dice "análisis más especializados" (bloque 44, 142.88–147.12 s). Se
corrigió en `palabras_con_duracion.csv` y en `bloques_subtitulo.csv`, se
actualizó el conteo de caracteres de ese bloque y se regeneró el SRT. Los
archivos previos quedaron respaldados con extensión `.bak`.

### Dos capturas del sitio añadidas

| Tramo | Frames | Imagen | Tamaño en pantalla |
|---|---|---|---|
| 33.30–41.04 s | 999–1231 | `03_graficas/05_capturas_mexicocomovamos/semaforos_economicos_nacionales.png` | 1000x720 px |
| 147.12–152.64 s | 4414–4579 | `03_graficas/05_capturas_mexicocomovamos/estudio_informalidad_laboral_portada.png` | 800x799 px |

Ambas entran con el mismo tratamiento que las gráficas: a pantalla completa
sobre el video desenfocado, centradas en y = 910. Se extendió la capa de
fondo desenfocado del lunes hasta el frame 1231 y se agregó una capa nueva
para el tramo del estudio.

El bloque del lunes quedó continuo desde el frame 764 hasta el 1231 (PIB,
inflación, IGAE y semáforos), así que el fundido de salida del IGAE y el de
entrada de los semáforos se cambiaron por corte seco, siguiendo la regla ya
adoptada para gráficas contiguas.

Las imágenes se respaldaron en
`03_graficas/05_capturas_mexicocomovamos/` y quedaron
documentadas en el LEEME de esa carpeta.

### Advertencia sobre la captura de semáforos

El tablero completo lleva ocho indicadores con su meta y su nota al pie. A
1000 px de ancho sobre un lienzo vertical, los títulos y las cifras grandes
se leen, pero el texto de las metas no. Si interesa que se lea, conviene
recortar la captura a la fila superior de cuatro indicadores (crecimiento,
empleos formales, inflación e inversión) y mostrarla a ese mismo ancho.
Queda pendiente de tu decisión.

### Subtítulos con resaltado palabra por palabra

Aprobado por Juvenal el 21 de agosto de 2026. Se aplicó el preset
`highlightBlock` de Palmier al grupo de subtítulos: la palabra que se está
diciendo lleva un bloque de color detrás y el resto del cue se mantiene en
blanco.

El color del resaltado es **#6B4FD7**, muestreado de las bandas de crédito
de los propios infobites para que sea el morado de la casa y no un morado
inventado. Sobre él, el texto blanco da una relación de contraste de 5.6:1,
por encima del 4.5:1 que pide el nivel AA.

Limitación conocida: el resaltado avanza a ritmo fijo, seis cuadros (0.2 s)
por palabra, no siguiendo la voz. Palmier solo sincroniza palabra por palabra
cuando él mismo transcribe, y aquí los subtítulos vienen de un SRT importado.
Como los cues son cortos (de dos a cinco palabras) y el conteo se reinicia en
cada uno, el desfase no se acumula; se notaría solo en una pausa larga a
media frase. Si algún día se quisiera sincronía exacta habría que elegir
entre dejar que Palmier retranscriba (perdiendo la corrección de
"especializados" y la segmentación) o generar un cue por palabra desde
`palabras_con_duracion.csv`, que cambia el estilo a una palabra a la vez.
