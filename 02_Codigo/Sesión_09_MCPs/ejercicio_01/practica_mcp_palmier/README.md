# Práctica: editar un reel con Claude Code y el MCP de Palmier Pro

Esta carpeta contiene todo el material necesario para reproducir, de punta a
punta, el armado de un reel vertical (1080x1920) usando Claude Code como
operador de Palmier Pro a través de su servidor MCP (Model Context Protocol,
el protocolo con el que un asistente de IA llama herramientas de una
aplicación externa).

El caso es real: la "Agenda económica de la semana" del 24 al 28 de agosto de
2026 de México ¿Cómo Vamos?. Se parte de una toma a cámara ya editada y de su
transcripción, y se termina con un MP4 con gráficas a pantalla completa,
badges de calendario, subtítulos quemados y clip institucional de cierre.

Todo lo que hay aquí pesa 71 MB y ningún archivo rebasa los 50 MB, así que la
carpeta se puede subir a GitHub sin Git LFS.

## Qué hay en cada carpeta

| Carpeta | Contenido | Para qué sirve en la práctica |
|---|---|---|
| `01_video_base/` | Toma a cámara, 1280x720, 30 fps, 154.9 s | Es el clip que se recorta a 9:16 y va en la pista principal |
| `02_transcripcion/` | Transcripción por bloques y por palabra (CSV), SRT y script de re-segmentación | De aquí salen los subtítulos sin retranscribir |
| `03_graficas/` | 28 PNG de semáforos e infobites, organizados por día del guión, con su `LEEME.md` | Son las gráficas que entran a pantalla completa |
| `04_badges_calendario/` | Cinco PNG, uno por día de la semana | Se colocan en la esquina superior izquierda |
| `05_cierre/` | Clip institucional de 3 s en dos versiones (morada y blanca) | Va al final con fundido cruzado |
| `06_plan/` | Plan de edición de referencia (la respuesta) y una plantilla vacía | El plan es el entregable de la Fase 1 |
| `07_referencias/` | Valores exactos de transformación para Palmier y lista de verificación | Se consultan en las fases 2 y 3 |
| `08_resultado_esperado/` | El reel terminado, recomprimido | Sirve para comparar el resultado propio |
| `verificar_carpeta.sh` | Script de bash | Confirma que la carpeta siga siendo apta para GitHub |

El video base original pesaba 234 MB (12 Mbps). Aquí viaja recomprimido con
H.264 a CRF 23, que conserva resolución, duración y cuadros por segundo.

## Requisitos

- Palmier Pro instalado y abierto. Su servidor MCP responde en
  `http://127.0.0.1:19789/mcp` mientras la aplicación corre.
- Claude Code instalado.
- `ffmpeg` y `ffprobe` para verificar el material y el archivo exportado.
- Python 3 con Pillow, solo si se quiere regenerar los subtítulos.
- La tipografía Ubuntu Regular instalada. Si no está, los subtítulos se rinden
  con otra fuente y hay que volver a correr el script de re-segmentación con
  `--fuente`, porque los cortes de línea dependen de las métricas de la
  tipografía.

## Guía paso a paso, con los prompts

La regla del flujo es que cada fase termina en un alto. Claude Code propone,
la persona revisa y aprueba, y solo entonces se pasa a la siguiente. La parte
que da valor al video es el mapeo de qué gráfica acompaña a qué frase, y esa
decisión es humana. Los prompts de abajo se copian tal cual en la sesión de
Claude Code abierta dentro de esta carpeta. Cada uno le dice al asistente
dónde detenerse, y eso no es adorno: sin esa instrucción encadena las tres
fases de un jalón y se pierde el punto de la práctica.

Tiempos aproximados para un taller: 5 minutos de preparación, 5 de Fase 0,
15 de Fase 1, 20 a 30 de Fase 2 y 10 de Fase 3.

### Preparación (antes de sentar a nadie)

Con Palmier Pro abierto, en la terminal y dentro de esta carpeta:

```
claude mcp add --scope local --transport http palmier-pro http://127.0.0.1:19789/mcp
claude
```

Ya dentro de Claude Code se escribe `/mcp` y se confirma que `palmier-pro`
aparezca como conectado. Si aparece con error de conexión, Palmier no está
abierto o el registro se hizo en otra carpeta. Nada de lo que sigue funciona
sin este paso, así que conviene ensayarlo el día anterior.

### Fase 0: verificar el material

Aquí todavía no interviene el MCP. Lo que se enseña es que el asistente
inspecciona antes de proponer.

```
Lee el README.md de esta carpeta. Después:

1. Verifica con ffprobe el video base (01_video_base/), el clip de cierre
   morado (05_cierre/) y confirma que existan los archivos de
   02_transcripcion/. Reporta resolución, fps, duración y códecs.
2. Cuenta los PNG de 03_graficas/ por subcarpeta y confirma que coincidan
   con lo que describe 03_graficas/LEEME.md.
3. Extrae un cuadro del video base en el segundo 10, recortado al centro
   en 9:16 y escalado a 1080x1920, y míralo. Dime si queda espacio para
   superponer una gráfica sin tapar el rostro.

No propongas todavía ninguna tabla de mapeo ni toques Palmier. Termina
con un resumen de lo verificado y espera mi visto bueno.
```

La conclusión que debe salir sola es que el rostro ocupa el lienzo completo
y que las gráficas tienen que entrar a pantalla completa, no superpuestas.

### Fase 1: proponer la tabla de mapeo

Es la parte con más valor pedagógico porque la decisión es humana.

```
Material verificado. Ahora propón el plan de edición.

Lee 02_transcripcion/bloques_subtitulo.csv (tiempos y texto de cada
bloque del diálogo) y 03_graficas/LEEME.md (qué muestra cada gráfica, de
dónde sale y qué advertencias trae). Escribe 06_plan/PLAN_EDICION.md a
partir de 06_plan/PLAN_EDICION_plantilla.md, con una tabla de mapeo fila
por fila: inicio, fin, fragmento del diálogo, asset asignado y badge del
día.

Reglas:
- Cada gráfica permanece 2.5 s como mínimo. Si el fragmento dura menos,
  va a cámara.
- Solo asignas una gráfica si existe un archivo que corresponda al dato
  que se dice. Si no existe, la fila va a cámara y anotas por qué.
- Abre cada PNG que asignes y confirma que su contenido sea lo que su
  nombre anuncia. Si alguno no lo es, repórtalo.
- Descarta las gráficas cuyo dato esté desactualizado según el LEEME,
  aunque calcen con la frase.
- Los badges van por día: lunes 24, martes 25, miércoles 26, jueves 27 y
  viernes 28 de agosto.
- Lista al final los archivos que quedan sin usar.

No leas 06_plan/PLAN_EDICION_referencia.md. No armes nada en Palmier.
Detente cuando el plan esté escrito y espera mi revisión.
```

Se revisa la propuesta en voz alta, se corrige alguna fila y se aprueba de
manera explícita. Solo entonces se compara contra
`06_plan/PLAN_EDICION_referencia.md`. Ahí salen los dos hallazgos que
justifican la revisión humana: un archivo cuyo contenido no corresponde a su
nombre y una gráfica que trae datos del 2023.

### Fase 2: armar la línea de tiempo en Palmier

Aquí entra el MCP y es lo que el público quiere ver. En pantalla pasan
`manage_project`, la importación de medios, `set_project_settings`, los
`add_clip` con sus transformaciones, `add_captions` con el SRT y
`update_text` con el resaltado. Este prompt está afinado con los valores que
ya se probaron; cambiarlos a ojo produce un video peor.

```
Plan aprobado. Arma el proyecto en Palmier Pro usando sus herramientas
MCP, siguiendo al pie de la letra 07_referencias/palmier_valores_timeline.md
y la tabla de mapeo de 06_plan/PLAN_EDICION.md.

Orden de trabajo:

1. Crea el proyecto "Agenda economica 24-28 ago 2026" en 9:16 a 1080p y
   30 fps. Importa el video base, las gráficas que usa el plan, los cinco
   badges, el clip de cierre morado y 02_transcripcion/subtitulos_2lineas.srt.
2. Coloca el video base en la pista principal desde el cuadro 0. Justo
   después vuelve a fijar el lienzo a 1080x1920 con set_project_settings
   y confírmalo con get_timeline antes de calcular cualquier
   transformación. Palmier lo reajusta a 1280x720 al colocar el primer
   clip.
3. Al video base aplícale el recorte central 9:16 (centerX 0.5,
   centerY 0.5, width 3.1605, height 1) y enfoque ligero de 0.35.
4. En una pista encima, coloca copias del video base solo en los tramos
   que llevan gráfica, con la misma transformación y desenfoque gaussiano
   de 32. Une los tramos contiguos en un solo clip. Silencia el audio
   anidado de cada copia a -60 dB; no silencies la pista de audio entera.
5. En la pista de gráficas coloca cada PNG en los cuadros que marca el
   plan, a 1000 px de ancho centrado en y = 910 (centerX 0.5,
   centerY 0.474, width 0.9259, height 0.293 para las 16:9; para las que
   no lo sean conserva el ancho y recalcula el alto). Fundido de 9 cuadros
   solo al entrar y salir de cada bloque; entre gráficas contiguas, corte
   seco.
6. En la pista de badges coloca el badge de cada día a 360 px de ancho
   con el borde superior en y = 40 y el izquierdo en x = 40 (width 0.3333,
   centerX 0.2037, alto y centerY proporcionales a cada archivo).
7. Agrega los subtítulos con add_captions pasando el SRT como
   subtitleMediaRef, sin retranscribir. Después, con update_text, ponlos
   en y = 0.794, tipografía Ubuntu-Regular, sombra negra al 65% con
   desenfoque 12, animación highlightBlock con color #6B4FD7.
8. Coloca el clip de cierre solapado 0.3 s con el final del video base,
   con fundido de entrada de 9 cuadros en imagen y en su audio anidado.
9. Verifica con get_timeline que el lienzo siga en 1080x1920, que la
   duración total ronde 157.6 s y que ninguna gráfica dure menos de
   2.5 s.

No generes ningún contenido con modelos de IA (ni imagen, ni video, ni
voz). No exportes todavía. Al terminar, reporta toda desviación respecto
del plan y anótala en 06_plan/PLAN_EDICION.md. Espera mi revisión.
```

La trampa del lienzo que se reajusta a 720p es un buen momento para pausar y
explicar por qué la persona sigue mirando aunque el asistente tenga los
valores correctos.

### Fase 3: verificar y exportar

```
Revisa la composición antes de exportar, siguiendo
07_referencias/verificacion.md:

1. Con inspect_timeline muestra tres cuadros: uno a la mitad del bloque
   del lunes (segundo 28), el cuadro del cue de subtítulo más ancho (mide
   el SRT con Ubuntu-Regular a 48 pt y localízalo), y la entrada del clip
   de cierre. Confirma que los subtítulos no pasen de dos líneas y que el
   cierre cruce desde la imagen y no desde negro.
2. Si algo falla, corrígelo y vuelve a mostrar el cuadro.
3. Exporta a exportes/agenda_economica_24-28_ago_2026.mp4 en H.264,
   1080x1920, 30 fps, audio AAC estéreo.
4. Sobre el archivo exportado (no sobre la vista previa) corre ffprobe y
   extrae cuadros con ffmpeg en los segundos 28, 63, 90 y 155. Revisa el
   pico de audio con volumedetect; no debe rebasar -1 dB.

Reporta cuántos problemas detectaste, qué corregiste y qué quedó
pendiente de mi decisión. Compara al final contra
08_resultado_esperado/agenda_economica_24-28_ago_2026_referencia.mp4.
```

### Versión abreviada para un video corto

Si la práctica es para grabar un video de demostración y no para un taller,
no conviene armar el reel completo. Con el bloque del lunes basta: PIB,
inflación e IGAE entre los segundos 22 y 41, con un badge y los subtítulos
de ese tramo. Son tres gráficas contiguas, así que muestra el fundido de
bloque, el corte seco entre gráficas y la trampa del lienzo en unos ocho
minutos de pantalla.

Se corren las fases 0 y 1 igual, y en la Fase 2 se sustituye el prompt por
este:

```
Arma solo el bloque del lunes del plan, del segundo 22.44 al 41.04,
siguiendo 07_referencias/palmier_valores_timeline.md:

- Video base en la pista principal, recortado a 9:16 (width 3.1605) con
  enfoque 0.35. Después de colocarlo, vuelve a fijar el lienzo a
  1080x1920 y confírmalo con get_timeline.
- Una copia desenfocada (gaussiano 32, audio anidado a -60 dB) del
  segundo 25.48 al 33.30.
- Tres gráficas a pantalla completa (width 0.9259, height 0.293,
  centerY 0.474): pib_crecimiento_anual_trimestre.png de 25.48 a 28.10,
  inflacion_general_anual.png de 28.10 a 30.70 e igae_variacion_anual.png
  de 30.70 a 33.30. Fundido de 9 cuadros solo al entrar la primera y al
  salir la tercera; corte seco entre ellas.
- El badge 24_ago_lunes.png de 22.44 a 41.04, a 360 px de ancho con el
  borde superior en y = 40 y el izquierdo en x = 40.
- Subtítulos desde 02_transcripcion/subtitulos_2lineas.srt con
  add_captions, y con update_text ponlos en y = 0.794, Ubuntu-Regular,
  sombra negra al 65% con desenfoque 12, highlightBlock en #6B4FD7.

No generes contenido con IA. Recorta la línea de tiempo al tramo 22.44 a
41.04 y exporta a exportes/demo_lunes.mp4 en 1080x1920 a 30 fps. Extrae
un cuadro del archivo exportado en el segundo 5 y muéstramelo.
```

El reel completo queda como tarea o como referencia en
`08_resultado_esperado/`.

## Reglas del material

- **No se genera contenido con modelos de IA.** Ni video, ni imágenes, ni
  voz. Solo se usa material que ya existe en esta carpeta.
- Las gráficas provienen de los repositorios `mcv_semaforos` y
  `mcv_infobites` de México ¿Cómo Vamos?. El `LEEME.md` de `03_graficas/`
  documenta el origen de cada una y advierte cuáles traen datos viejos.
- Las capturas de `03_graficas/05_capturas_mexicocomovamos/` son capturas de
  pantalla y tienen menor resolución que los infobites.

## Antes de subir a GitHub

```
./verificar_carpeta.sh
```

El script lista archivos de más de 50 MB y de más de 100 MB, detecta
`.DS_Store` y respaldos `.bak`, y reporta el peso por carpeta. El
`.gitignore` excluye los proyectos `.palmier`, la carpeta `exportes/` y las
salidas de verificación, para que cada quien genere las suyas sin inflar el
repositorio.

## Regenerar los subtítulos

Si se corrige una palabra en `palabras_con_duracion.csv` o se cambia la
tipografía, se vuelve a generar el SRT con:

```
python3 02_transcripcion/resegmentar_subtitulos.py \
  02_transcripcion/palabras_con_duracion.csv \
  02_transcripcion/subtitulos_2lineas.srt
```

Por omisión mide con Ubuntu Regular a 48 pt y un tope de 515 px por línea.
