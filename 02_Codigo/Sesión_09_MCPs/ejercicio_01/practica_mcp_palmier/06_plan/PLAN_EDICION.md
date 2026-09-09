# Plan de edición — Agenda económica del 24 al 28 de agosto de 2026

Estado: Fase 3 completada el 9 de septiembre de 2026. Exportado a `exportes/agenda_economica_24-28_ago_2026.mp4` y verificado sobre el archivo.

## Datos verificados (ffprobe)

- Video base: `01_video_base/video_base_1280x720.mp4`
  1280x720, 30 fps, 154.900 s, H.264 + AAC 48 kHz estéreo (1.42 Mbps).
- Clip de cierre: `05_cierre/reel_mcv_morada_1080x1920_3s.mp4`
  1080x1920, 30 fps, 3.000 s, H.264 + AAC 44.1 kHz estéreo. La versión blanca (`reel_mcv_normal_1080x1920_3s.mp4`) tiene las mismas características y no se usa.
- Transcripción usada como fuente de verdad:
  `02_transcripcion/bloques_subtitulo.csv` (47 bloques, de 0.000 a 154.420 s). Los cortes finos dentro de un bloque se tomaron de `palabras_con_duracion.csv` (455 palabras). Subtítulos: `subtitulos_2lineas.srt`.
- Gráficas: 27 PNG en `03_graficas/` (2 + 6 + 5 + 6 + 6 + 2 por subcarpeta), que coinciden con los 27 que describe `03_graficas/LEEME.md`. El README general habla de 28; la cifra correcta es 27. Los infobites miden 3200x1800 salvo `balanza_comercial_saldo.png` (2862x1610); las dos capturas miden 1302x938 y 521x520.
- Badges: 5 PNG con el día correcto (lunes 24 a viernes 28 de agosto de 2026), de anchos distintos (758 a 1033 px).
- Duración final estimada: 157.60 s (video base de 154.90 s + cierre de 3.00 s solapado 0.30 s).

## Decisiones aprobadas

1. **Encuadre.** El cuadro del segundo 10 recortado al centro en 9:16 muestra el rostro ocupando casi todo el lienzo (de la frente a la barbilla va de y ≈ 300 a y ≈ 1350 sobre 1920, y el micrófono en mano ocupa la franja inferior). No queda espacio para superponer una gráfica sin taparlo. Recorte central con `width 3.1605` y enfoque de 0.35.
2. **Tratamiento de las gráficas.** Van a pantalla completa, sobre una copia desenfocada del video base (gaussiano 32, audio anidado a -60 dB), a 1000 px de ancho centradas en y = 910. Nunca sobrepuestas al rostro.
3. **Posición del badge.** Esquina superior izquierda, 360 px de ancho, borde superior en y = 40 y borde izquierdo en x = 40. Un badge por día del guión; sin badge en el gancho (0 a 22.44 s) ni en el cierre (desde 136.30 s).
4. **Permanencia mínima por gráfica.** 2.5 s. Todas las filas con gráfica cumplen; la más corta dura 2.60 s (inflación, fila 6). Cuando el fragmento no alcanza, la fila va a cámara.
5. **Fundidos y cierre.** Fundido de 9 cuadros solo al entrar y salir de cada bloque de gráficas; corte seco entre gráficas contiguas (filas 5 a 8 y filas 15 a 17). El clip de cierre morado entra en 154.60 s, solapado 0.30 s con el final del video base, con fundido de entrada de 9 cuadros en imagen y audio.

## Tabla de mapeo

Tiempos en segundos del video base; cuadros a 30 fps (`[inicio, fin)`). Las rutas se abrevian con `...` dentro de `03_graficas/` y `04_badges_calendario/`.

| #  | Inicio (s) | Fin (s) | Cuadros | Dur. (s) | Fragmento del diálogo | Asset | Badge |
|----|-----------|---------|---------|----------|-----------------------|-------|-------|
| 1 | 0.00 | 3.94 | 0–118 | 3.94 | Un trabajo formal en México paga, en promedio, el doble que un informal. | `Cámara (a)` | — |
| 2 | 3.94 | 8.82 | 118–265 | 4.88 | Pero desafortunadamente, más de la mitad de las personas que trabajan están en la informalidad. | `00_gancho.../tasa_informalidad_serie_trimestral.png` | — |
| 3 | 8.82 | 22.44 | 265–673 | 13.62 | Esta semana salen los datos nuevos [...] Del 24 al 28 de agosto, que viene bastante cargadita. | `Cámara` | — |
| 4 | 22.44 | 25.48 | 673–764 | 3.04 | El lunes es día cargado de información, ya que | `Cámara` | 24_ago_lunes |
| 5 | 25.48 | 28.10 | 764–843 | 2.62 | sale el PIB del segundo trimestre, inflación de la | `01_lunes.../pib_crecimiento_anual_trimestre.png` | 24_ago_lunes |
| 6 | 28.10 | 30.70 | 843–921 | 2.60 | primera quincena de agosto y la actividad | `01_lunes.../inflacion_general_anual.png` | 24_ago_lunes |
| 7 | 30.70 | 33.30 | 921–999 | 2.60 | económica de junio. Con todo esto actualizamos dos | `01_lunes.../igae_variacion_anual.png` | 24_ago_lunes |
| 8 | 33.30 | 41.04 | 999–1231 | 7.74 | semáforos, el de crecimiento y el de inflación. Los resultados ya los puedes consultar en mexicocomovamos.mx al publicar este video. | `05_capturas.../semaforos_economicos_nacionales.png (b)` | 24_ago_lunes |
| 9 | 41.04 | 58.44 | 1231–1753 | 17.40 | El martes viene lo bueno [...] Al respecto, tenemos dos pendientes estructurales. El primero, la | `Cámara (c)` | 25_martes |
| 10 | 58.44 | 64.24 | 1753–1927 | 5.80 | informalidad, ya que el trimestre pasado el 54.8% de la población ocupada en México | `02_martes.../informalidad_serie_trimestral_alt.png` | 25_martes |
| 11 | 64.24 | 69.14 | 1927–2074 | 4.90 | trabaja en un empleo sin prestaciones ni seguridad social. Además, | `Cámara` | 25_martes |
| 12 | 69.14 | 76.92 | 2074–2308 | 7.78 | la participación laboral de las mujeres está muy baja, con una brecha de casi 30 puntos porcentuales con respecto a la tasa de participación masculina. | `02_martes.../brecha_participacion_mujeres_hombres_v2.png` | 25_martes |
| 13 | 76.92 | 83.54 | 2308–2506 | 6.62 | Esto importa porque casi el 70% del ingreso de las familias justamente viene del ingreso del trabajo. | `Cámara (d)` | 25_martes |
| 14 | 83.54 | 89.74 | 2506–2692 | 6.20 | El miércoles toca revisar pobreza laboral, aquellas personas cuyo ingreso por trabajar no alcanza ni para | `Cámara` | 26_miercoles |
| 15 | 89.74 | 93.00 | 2692–2790 | 3.26 | pagar la canasta alimentaria de los miembros de su hogar. | `03_miercoles.../canasta_alimentaria_LPEI.png (e)` | 26_miercoles |
| 16 | 93.00 | 99.30 | 2790–2979 | 6.30 | Si bien el trimestre pasado marcó su mínimo histórico, o sea, el número más bajo que ha tenido en la historia, aún así son más | `03_miercoles.../pobreza_laboral_porcentaje_serie.png` | 26_miercoles |
| 17 | 99.30 | 102.36 | 2979–3071 | 3.06 | de 40 millones de personas que viven en esta situación. | `03_miercoles.../pobreza_laboral_millones_personas.png` | 26_miercoles |
| 18 | 102.36 | 103.72 | 3071–3112 | 1.36 | La salida es una. | `Cámara (f)` | 26_miercoles |
| 19 | 103.72 | 106.52 | 3112–3196 | 2.80 | Nos toca crear más empleos formales en el país. | `03_miercoles.../pobreza_laboral_hogar_con_un_formal.png` | 26_miercoles |
| 20 | 106.52 | 107.42 | 3196–3223 | 0.90 | El jueves | `Cámara` | 27_jueves |
| 21 | 107.42 | 110.22 | 3223–3307 | 2.80 | sale la balanza comercial de julio, la | `04_jueves.../balanza_comercial_saldo.png` | 27_jueves |
| 22 | 110.22 | 113.14 | 3307–3394 | 2.92 | ENOE mensual de julio y el informe trimestral de Banxico, | `04_jueves.../enoe_mensual_desocupacion.png` | 27_jueves |
| 23 | 113.14 | 118.34 | 3394–3550 | 5.20 | en el cual sabremos cómo ve el Banco Central los riesgos para el crecimiento y la inflación. | `Cámara (g)` | 27_jueves |
| 24 | 118.34 | 136.30 | 3550–4089 | 17.96 | Finalmente, el viernes cerramos con las finanzas públicas de julio [...] así le va a las finanzas públicas del gobierno. | `Cámara (h)` | 28_viernes |
| 25 | 136.30 | 147.12 | 4089–4414 | 10.82 | Si te interesan estos resúmenes semanales [...] para nuestros análisis más especializados. | `Cámara` | — |
| 26 | 147.12 | 152.64 | 4414–4579 | 5.52 | Por ejemplo, la semana pasada publicamos uno exclusivamente sobre la informalidad laboral. | `05_capturas.../estudio_informalidad_laboral_portada.png (i)` | — |
| 27 | 152.64 | 154.90 | 4579–4647 | 2.26 | Que tengas un excelente inicio de semana. | `Cámara` | — |
| 28 | 154.60 | 157.60 | 4638–4728 | 3.00 | (sin diálogo) clip institucional, solapado 0.3 s con el final del video base | `05_cierre/reel_mcv_morada_1080x1920_3s.mp4` | — |

Notas de la tabla:

- (a) Fila 1 a cámara. El único candidato, `salario_por_condicion_formalidad.png`, se descarta por dos razones: el LEEME lo marca con dato del 2º trimestre de 2023, y además el archivo en disco no contiene lo que describe el LEEME (ver hallazgos).
- (b) La captura del tablero de semáforos entra en la palabra "semáforos" (33.12 s, redondeado a 33.30 para dar a la gráfica del IGAE sus 2.6 s) y cubre la remisión a mexicocomovamos.mx. Es una captura de pantalla de 1302x938, no 16:9: a 1000 px de ancho mide 720 px de alto (`height 0.3752`).
- (c) El tramo del martes de 41.04 a 58.44 s va a cámara: presenta la ENOE en general y "cuánto ganan los trabajadores" no tiene infobite vigente (el de salarios está descartado).
- (d) "Casi el 70% del ingreso de las familias viene del trabajo" no tiene infobite propio, según el LEEME.
- (e) Para "pagar la canasta alimentaria" se usa `canasta_alimentaria_LPEI.png` (serie mensual a julio de 2026, $2,545.72 urbana). Se descarta `ingreso_laboral_vs_linea_pobreza.png` porque su contenido no corresponde a su nombre (ver hallazgos).
- (f) "La salida es una." (1.24 s) regresa a cámara como pausa dramática antes de la gráfica de formalidad del hogar. Entre la fila 17 y la fila 19 hay dos bloques de gráficas separados, con su propio fundido cada uno.
- (g) El informe trimestral de Banxico va a cámara. Los archivos `expectativas_banxico_crecimiento.png` y `expectativas_banxico_inflacion.png` muestran la Encuesta de Expectativas de especialistas del sector privado, no la visión del Banco Central, así que no corresponden al dato que se dice. **Decisión pendiente:** si se acepta la aproximación que sugiere el LEEME, cabe `expectativas_banxico_crecimiento.png` de 113.36 a 118.34 s (4.98 s); la de inflación no cabe con 2.5 s propios porque "inflación" se dice en los últimos 0.44 s del bloque.
- (h) Finanzas públicas e ISR: no existe infobite nacional de ingresos tributarios, según el LEEME. Todo el viernes va a cámara con su badge.
- (i) La portada del estudio mide 521x520 px. A 1000 px de ancho se escala 1.92x y se verá suave; el LEEME recomienda mostrarla a 800 px (1.54x). **Decisión pendiente:** propongo 800 px (`width 0.7407`, `height 0.4159`), aunque rompe la regla de "mismo ancho" del resto de las gráficas.

## Hallazgos de la verificación de contenido

Se abrieron los 27 PNG de gráficas y los 5 badges. Dos archivos no muestran lo que su nombre anuncia:

1. **`00_gancho_formalidad_vs_informalidad/salario_por_condicion_formalidad.png`.** El LEEME dice que muestra el ingreso laboral mensual promedio formal ($9,720.93) contra informal ($4,784.79) al 2º trimestre de 2023. El archivo en disco muestra otra cosa: "Ingreso real per cápita de los hogares por tipo de empleo del jefe de familia, T1 2005 a 2026 T1", con $6,918.1 (formal) contra $3,881.4 (informal). Ni el nombre ni la ficha del LEEME describen el contenido real. Aun con dato de 2026, la razón entre ambas series es 1.78 y mide ingreso per cápita del hogar, no lo que paga un trabajo, así que tampoco respalda la frase "paga el doble". Se descarta y se reporta para que el equipo de datos entregue la versión correcta.
2. **`03_miercoles_pobreza_laboral/ingreso_laboral_vs_linea_pobreza.png`.** El nombre y el LEEME anuncian "ingreso laboral frente a la línea de pobreza". El contenido real es "Valor de la canasta alimentaria del Coneval, evolución trimestral en zonas urbanas y rurales" ($2,525 y $1,897 al 1T 2026), es decir, una versión trimestral de `canasta_alimentaria_LPEI.png`. Se descarta.

Otras observaciones que no bloquean el plan:

- `brecha_participacion_mujeres_hombres_v1.png` está actualizada al 3º trimestre de 2025 (brecha de 29.3 pp); la v2 va al 1T 2026 (28.76 pp) y es la que se usa.
- `pib_crecimiento_anual_trimestre.png` ya trae el 2T 2026 (2.1%) e `inflacion_general_anual.png` ya trae julio de 2026 (3.12%), los mismos valores que muestra la captura del tablero de semáforos. `igae_variacion_anual.png` llega a mayo de 2026 (2%), mientras que el guión anuncia el dato de junio: es el corte disponible al grabar.
- El resto de los archivos asignados coincide con su nombre y con la ficha del LEEME.

## Layout sobre el lienzo de 1080x1920

- **Zonas seguras.** Franja superior de 0 a 260 px para el badge; zona central de 620 a 1200 px para las gráficas (1000 px de ancho, borde izquierdo en x = 40); franja de subtítulos centrada en y = 0.794 (≈ 1524 px), máximo dos líneas de 48 pt; el rostro queda debajo del desenfoque cuando hay gráfica.
- **Video base y copia desenfocada:** `centerX 0.5, centerY 0.5, width 3.1605, height 1`. La principal con enfoque 0.35; la copia con gaussiano 32 y audio anidado a -60 dB.
- **Gráficas 16:9:** `centerX 0.5, centerY 0.474, width 0.9259, height 0.293`.
- **Gráficas que no son 16:9** (mismo ancho, alto recalculado con `height = (1000 * alto / ancho) / 1920`):

| Archivo | Alto en px | `height` |
|---|---|---|
| semaforos_economicos_nacionales.png (1302x938) | 720 | 0.3752 |
| estudio_informalidad_laboral_portada.png (521x520), a 1000 px | 998 | 0.5198 |
| estudio_informalidad_laboral_portada.png (521x520), a 800 px | 798 | 0.4159 |
| balanza_comercial_saldo.png (2862x1610) | 563 | 0.2930 |

- **Badges** (`width 0.3333, centerX 0.2037`, alto y centro proporcionales):

| Archivo | Alto en px | `height` | `centerY` |
|---|---|---|---|
| 24_ago_lunes.png (758x384) | 182 | 0.0950 | 0.0683 |
| 25_martes.png (851x403) | 170 | 0.0888 | 0.0652 |
| 26_miercoles.png (1033x407) | 142 | 0.0739 | 0.0578 |
| 27_jueves.png (828x385) | 167 | 0.0872 | 0.0644 |
| 28_viernes.png (866x388) | 161 | 0.0840 | 0.0628 |

- **Subtítulos:** `add_captions` con `subtitleMediaRef` al SRT de dos líneas; después `update_text` con `x 0.5, y 0.794`, Ubuntu-Regular, sombra negra al 65% con desenfoque 12, animación `highlightBlock` en `#6B4FD7`.

## Bloques de gráficas (para la copia desenfocada y los fundidos)

| Bloque | Inicio (s) | Fin (s) | Cuadros | Gráficas |
|---|---|---|---|---|
| Gancho | 3.94 | 8.82 | 118–265 | 1 |
| Lunes | 25.48 | 41.04 | 764–1231 | 4 contiguas |
| Martes 1 | 58.44 | 64.24 | 1753–1927 | 1 |
| Martes 2 | 69.14 | 76.92 | 2074–2308 | 1 |
| Miércoles 1 | 89.74 | 102.36 | 2692–3071 | 3 contiguas |
| Miércoles 2 | 103.72 | 106.52 | 3112–3196 | 1 |
| Jueves | 107.42 | 113.14 | 3223–3394 | 2 contiguas |
| Cierre | 147.12 | 152.64 | 4414–4579 | 1 |

Ocho bloques, 14 gráficas, 52.9 s con gráfica sobre 154.9 s de diálogo.

## Assets que quedan sin usar

- `00_gancho_formalidad_vs_informalidad/salario_por_condicion_formalidad.png` (contenido no corresponde; LEEME lo marca 2023).
- `01_lunes_pib_inflacion_igae/pib_evolucion_serie.png`, `inflacion_subyacente.png`, `igae_actividad_economica.png` (variantes de las tres que sí se usan).
- `02_martes_enoe_informalidad_mujeres/brecha_participacion_mujeres_hombres_v1.png` (3T 2025, desactualizada), `informalidad_por_sexo.png`, `participacion_laboral_por_sexo.png`.
- `03_miercoles_pobreza_laboral/ingreso_laboral_vs_linea_pobreza.png` (contenido no corresponde), `pobreza_laboral_por_formalidad_matriz.png` (dos paneles con texto pequeño; se prefiere la versión de un panel).
- `04_jueves_balanza_enoe_banxico/exportaciones_mensuales.png`, `enoe_mensual_brecha_participacion.png`, `expectativas_banxico_crecimiento.png`, `expectativas_banxico_inflacion.png` (ver nota g).
- `05_cierre/reel_mcv_normal_1080x1920_3s.mp4` (se usa la versión morada).
- `02_transcripcion/subtitulos.srt` (se usa `subtitulos_2lineas.srt`).

## Desviaciones respecto del plan aprobado

Se anota aquí toda diferencia entre lo planeado y lo ejecutado, aunque haya
mejorado el resultado.

- **Redondeo de Palmier en las copias de fondo.** Al colocar las copias con `source` en segundos, Palmier recortó tres por un cuadro (recorte de fuente 117 en vez de 118; fines en 1230 y 3072 en vez de 1231 y 3071). Se corrigió con `trimStartFrame` y `durationFrames` para que cada copia quede alineada al cuadro con el video principal. Conviene colocar las copias con `endFrame` y corregir el recorte después, en vez de confiar en `source`.
- **Trampa del lienzo confirmada.** Al colocar el video base, Palmier reajustó el lienzo a 1280x720 ("Matched timeline resolution to clip"). Se volvió a fijar en 1080x1920 con `set_project_settings` y se confirmó con `get_timeline` antes de cualquier transformación.
- **Portada del estudio a 800 px** (`width 0.7407, height 0.4159`), como proponía la nota (i). Es la única gráfica que no va a 1000 px.
- **Informe de Banxico a cámara**, como proponía la nota (g). No se colocó ninguna gráfica de expectativas.
- **Subtítulos.** El SRT produjo 82 cues entre los cuadros 0 y 4646. `add_captions` los dejó en y = 0.9 y Helvetica; `update_text` los movió a y = 0.794 con Ubuntu-Regular, sombra y `highlightBlock` (6 cuadros por palabra, ritmo fijo).
- Sin otras desviaciones: los 28 renglones de la tabla se colocaron en los cuadros previstos.

## Estado del proyecto en Palmier (para la Fase 3)

- Proyecto: `~/Documents/Palmier Pro/Agenda economica 24-28 ago 2026.palmier`, línea de tiempo `35CE29D3`, 1080x1920 a 30 fps, 4728 cuadros (157.6 s).
- Pistas: V6 Subtitulos (`CF5B24DF`), V5 Outro (`3E28E681`), V4 Badges (`BF747158`), V3 Graficas (`E5F46C60`), V2 Fondo (`1E7F2D37`), V1 Main (`3E293CF5`), A1 Dialogue (`18FE3B5A`), A2 Extras (`C452F532`).
- Video base: clip `C74CD799` (audio `F5E0073A`), recorte `width 3.1605`, enfoque 0.35.
- Grupo de subtítulos: `ED8D27B4`.
- Cierre: clip `74A3ADBB` (audio `649EBE06`), cuadros 4638 a 4728, fundido de entrada de 9 cuadros en ambos.
- Gráfica más corta: 78 cuadros (2.6 s). Cuadros revisados con `inspect_timeline`: 840 y 4643.


## Verificación de la Fase 3

Composición revisada en Palmier con `inspect_timeline` en once cuadros (190, 840, 1100, 1840, 2190, 2880, 3150, 3249, 3350, 4500 y 4640): un cuadro por bloque de gráficas, el cue de subtítulo más ancho y la entrada del cierre. El cue más ancho es el 59 ("El jueves sale la balanza / comercial de julio, la"), con 514 px medidos con Ubuntu Regular a 48 pt; ningún cue del SRT pasa de dos líneas. El cierre cruza desde la imagen. No hubo nada que corregir en este ciclo.

Archivo exportado (verificado con ffprobe sobre el MP4, no sobre la vista previa):

| Dato | Exportado | Referencia |
|---|---|---|
| Video | H.264 High, 1080x1920, 30 fps, yuv420p | H.264, 1080x1920, 30 fps |
| Audio | AAC LC, 48 kHz, estéreo | AAC, estéreo |
| Duración | 157.600 s | 157.609 s |
| Tasa de bits | 10.5 Mbps (206 MB) | 1.8 Mbps (35 MB, recomprimida para GitHub) |
| Pico de audio | -8.9 dB | -8.9 dB |
| Media de audio | -36.4 dB | -36.4 dB |

Cuadros extraídos del exportado en 28, 63, 90 y 155 s y comparados con los mismos de la referencia: coinciden en encuadre, badge, posición de la gráfica y subtítulo. La única diferencia está en el segundo 90, donde la referencia muestra la canasta trimestral (`ingreso_laboral_vs_linea_pobreza.png`, el archivo cuyo contenido no corresponde a su nombre) y este reel muestra la canasta mensual (`canasta_alimentaria_LPEI.png`), conforme a la nota (e) del plan.

Problemas detectados en la Fase 3: 0. Corregidos: 0. Pendientes de decisión: ninguno. La carpeta `exportes/` está excluida por `.gitignore`.
