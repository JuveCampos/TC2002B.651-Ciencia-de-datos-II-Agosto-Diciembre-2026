# Plan de presentación: RAG con las mañaneras

Guion de textos por diapositiva, previo a construir el archivo .pptx. La
estructura sigue la pirámide de Minto: situación (lo que un modelo de
lenguaje sabe hacer), complicación (lo que no sabe y lo que inventa) y
resolución (RAG, mostrado paso a paso con el corpus de mañaneras). Cada
título es una oración con el hallazgo; leídos en secuencia cuentan la
historia completa (prueba del "ghost deck").

Convenciones del guion:

- **Título**: oración completa, es lo que se lee en la diapositiva.
- **Cuerpo**: texto que va en tarjetas o junto a la figura. Se escribe
  completo para que después solo se acomode.
- **Figura**: qué se muestra y con qué código se genera. Ninguna figura se
  inventa; todas salen de `02_rag_mananeras.R` o de los datos del corpus.
- **Pie**: fuente en formato corto, 9 pt gris.
- **Notas**: lo que dice el expositor y no está escrito en la diapositiva.
- **Términos**: los conceptos que esa diapositiva introduce, en el orden del
  glosario de RAG_01.

Duración estimada: 60 a 75 minutos con dos demostraciones en vivo (paso 4 y
paso 5 del script). Público: estudiantes de ciencias sociales sin
programación previa.

---

## 1. Portada

**Título:** RAG con las mañaneras: cómo hacer que un modelo de lenguaje lea
antes de responder

**Subtítulo:** Recuperación, embeddings y generación con las conferencias de
prensa de la presidenta, todo en R y en tu computadora

**Pie:** [PENDIENTE: nombre del curso y grupo] · [PENDIENTE: fecha de la
sesión] · Tecnológico de Monterrey

---

## 2. Hoja de ruta

**Título:** La sesión recorre el pipeline completo, de las mañaneras crudas a
una respuesta con cita

**Cuerpo (cuatro tarjetas en fila):**

1. **El problema.** Qué sabe y qué no sabe un modelo de lenguaje, y por qué
   inventa.
2. **El corpus.** 71 mañaneras convertidas en texto con fecha y fuente.
3. **El pipeline.** Fragmentar, embeber, guardar, buscar, redactar.
4. **La evaluación.** Cómo sabemos si funcionó y dónde falla.

**Notas:** Adelantar que habrá dos demostraciones en vivo: la búsqueda sin
generador (rápida) y la respuesta completa (tarda unos 12 segundos, se
aprovecha para explicar qué hace el modelo mientras tanto).

---

## 3. Situación: lo que un modelo de lenguaje sabe hacer

**Título:** Un modelo de lenguaje predice la siguiente palabra, y con eso
redacta, resume y conversa

**Cuerpo:**

- Un **modelo de lenguaje grande** (LLM, por sus siglas en inglés) es un
  modelo estadístico entrenado con enormes cantidades de texto para predecir
  qué palabra sigue. Esa habilidad basta para responder preguntas, resumir y
  redactar con fluidez.
- Trabaja con **tokens**, fragmentos de palabra. En español, mil tokens son
  unas 600 o 700 palabras.
- Lee de una sola vez una cantidad limitada de tokens: su **ventana de
  contexto**. En la variante que usaremos son 8,192 tokens, unas 5,000
  palabras; una mañanera completa tiene unas 14,000.

**Figura:** jerarquía tipográfica grande: "predice la siguiente palabra" en
navy, sin figura. Debajo, tres tarjetas con los tres términos.

**Términos:** modelo de lenguaje grande, token, ventana de contexto.

**Notas:** Insistir en que todo lo que el modelo "sabe" quedó fijado en sus
parámetros durante el entrenamiento. No consulta nada cuando responde.

---

## 4. Complicación 1: lo que no sabe

**Título:** Lo que el modelo sabe se congeló en su fecha de corte: no leyó la
mañanera de ayer

**Cuerpo:**

- La **fecha de corte del conocimiento** es la fecha hasta la que llegan los
  datos con los que se entrenó el modelo. Todo lo posterior no existe para
  él.
- Tampoco conoce nunca los documentos que no estaban en internet al
  entrenarse: actas internas, bases propias, encuestas sin publicar.
- Las mañaneras son el caso extremo: hay una nueva cada día hábil y cada una
  trae cifras, nombres y anuncios que no estaban en ningún lado la víspera.

**Figura:** línea de tiempo simple (matplotlib): fecha de corte del modelo a
la izquierda, mañaneras de junio a septiembre de 2026 a la derecha, con la
zona "el modelo no sabe nada de esto" sombreada en rojo suave.

**Pie:** Fuente: fechas de corte publicadas por cada proveedor; corpus
propio de mañaneras (gob.mx).

**Términos:** fecha de corte del conocimiento.

---

## 5. Complicación 2: lo que inventa

**Título:** Cuando no sabe, el modelo no se calla: inventa una cifra
verosímil

**Cuerpo:**

- A esto se le llama **alucinación**: una afirmación fluida, con el tono
  correcto, y falsa. Ocurre porque el modelo optimiza plausibilidad, no
  verdad.
- Pregunta de prueba: "¿Cuál fue el promedio diario de homicidios dolosos en
  agosto de 2026 según la presidenta?".
- Respuesta del modelo sin acceso al corpus: [PENDIENTE: generar con
  qwen3.5-4b-8k sin RAG y pegar textual; se espera una cifra inventada o una
  evasiva].
- Respuesta correcta según la mañanera del 8 de septiembre de 2026: 40.8
  homicidios diarios.

**Figura:** dos tarjetas lado a lado, roja ("sin documentos") y verde ("lo
que dijo la mañanera"), con las dos respuestas.

**Pie:** Fuente: versión estenográfica del 8 de septiembre de 2026,
Presidencia de la República; respuesta generada con qwen3.5:4b vía Ollama.

**Términos:** alucinación.

**Notas:** Este es el momento de tensión de la clase. Preguntar al grupo cómo
distinguirían la respuesta inventada de la real si no tuvieran la fuente.

---

## 6. Tres caminos para darle información nueva al modelo

**Título:** De las tres formas de darle información nueva a un modelo, solo
una escala a un corpus que cambia cada día

**Cuerpo (tabla de tres columnas):**

| | Ajuste fino | Contexto largo | RAG |
|---|---|---|---|
| Qué hace | Reentrena parte del modelo con datos propios | Pega todos los documentos en el prompt | Busca los fragmentos relevantes y solo pega esos |
| Costo | Alto, horas de cómputo por versión | Bajo por consulta, pero crece con el corpus | Bajo; el índice se construye una vez |
| Actualización | Reentrenar | Volver a pegar todo | Agregar archivos al almacén |
| Cita la fuente | No | Difícil | Sí, es su ventaja central |
| Límite | Datos que cambian cada mes | Miles de documentos no caben | Depende de que la búsqueda acierte |

**Pie:** Elaboración propia a partir de Lewis et al. (2020).

**Términos:** ajuste fino, contexto largo.

**Notas:** Con 71 mañaneras (6 millones de caracteres, unos 1.5 millones de
tokens) ni siquiera el contexto largo de los modelos comerciales las
contiene completas, y aunque cupieran, el modelo se distrae con el ruido.

---

## 7. Resolución: la idea de RAG en una oración

**Título:** RAG resuelve el problema con una regla simple: buscar primero,
redactar después

**Cuerpo:**

- **RAG** (Retrieval-Augmented Generation, generación aumentada por
  recuperación) es una arquitectura en la que, antes de responder, el
  sistema busca en una colección de documentos los fragmentos relevantes y
  se los entrega al modelo como contexto. El término lo acuñaron Lewis et
  al. (2020).
- El modelo ya no responde de memoria: responde a partir del material que
  recibe, y puede señalar de dónde salió cada dato.
- Dos modelos distintos intervienen: uno que busca (embeddings) y uno que
  redacta (generador). Se verán por separado.

**Figura:** diagrama de flujo horizontal (matplotlib): Pregunta → Búsqueda en
el almacén → 5 fragmentos con fecha → Modelo generador → Respuesta con cita.
Debajo, atenuado, el camino sin RAG: Pregunta → Modelo → Respuesta sin
fuente.

**Pie:** Fuente: Lewis et al. (2020).

**Términos:** RAG.

---

## 8. El corpus

**Título:** El corpus son 71 mañaneras en texto plano, con fecha y fuente,
descargadas con R

**Cuerpo:**

- El **corpus** es el conjunto de documentos sobre los que el sistema va a
  responder. Aquí: las versiones estenográficas de las conferencias
  matutinas del 1 de junio al 8 de septiembre de 2026, publicadas en
  gob.mx.
- Cada archivo conserva tres **metadatos** (título, fecha y URL) y el texto
  con un párrafo por turno de palabra, con el orador en mayúsculas.
- La **ingesta** se hizo con un navegador controlado desde R (chromote)
  porque el sitio bloquea las descargas automáticas comunes; el texto se
  extrajo con rvest.

**Figura:** gráfica de barras (ggplot2) de caracteres por mañanera según la
fecha, junio a septiembre de 2026, con el hueco del 1 de septiembre anotado
("Informe de gobierno, sin mañanera"). Datos: `mananeras/indice_mananeras.csv`.

**Pie:** Fuente: Presidencia de la República, versiones estenográficas
(gob.mx). Cálculos propios.

**Términos:** corpus, ingesta, metadatos.

**Notas:** Mostrar en pantalla las primeras líneas de un archivo real. El
punto pedagógico: la calidad de las respuestas está acotada por la calidad
del corpus, y aquí el corpus es limpio porque la fuente ya venía
estructurada.

---

## 9. Fragmentación: por qué

**Título:** Una mañanera no cabe en el modelo ni conviene que quepa: se
parte en fragmentos

**Cuerpo:**

- La **fragmentación** (en inglés *chunking*) divide cada documento en
  pedazos cortos, los **fragmentos**, que son la unidad que se embebe, se
  guarda y se recupera.
- Tres razones: el modelo de embeddings tiene un límite de entrada; un
  vector resume todo el texto que recibe y un texto que habla de diez temas
  produce un vector que no se parece a ninguna pregunta; y el generador solo
  puede leer unos pocos fragmentos a la vez.
- Decisiones: **tamaño** (1,600 caracteres en el script, unos 400 tokens),
  **traslape** (25 %: cada fragmento repite el último cuarto del anterior) y
  dónde cortar (ragnar mueve cada corte al límite de párrafo más cercano).

**Figura:** el esquema "Del párrafo al vector", etapa 2: regla de 860
caracteres con los dos fragmentos (1 a 574 y 345 a 860) y el traslape
rayado. Se regenera con matplotlib a partir de los mismos números.

**Pie:** Fuente: mañanera del 14 de julio de 2026; fragmentación con ragnar
0.3.0 (tamaño objetivo 500, traslape 25 %, escala reducida).

**Términos:** fragmentación, fragmento, tamaño de fragmento, traslape.

**Notas:** Afortunado en este corpus: como cada párrafo es un turno de
palabra, los fragmentos rara vez separan al orador de lo que dijo.

---

## 10. Fragmentación: el resultado en números

**Título:** Con 1,600 caracteres y 25 % de traslape, 26 mañaneras se
convierten en 1,824 fragmentos

**Cuerpo (tres tarjetas):**

- **Fragmentos chicos (800).** Vectores más precisos; una cifra puede quedar
  separada de la oración que la explica; el doble de fragmentos que embeber.
- **Fragmentos medianos (1,600).** El punto de partida del script: unos 70
  por mañanera, cabe un turno de palabra completo.
- **Fragmentos grandes (3,200).** Conservan el argumento entero; diluyen el
  significado y llenan la ventana del generador con dos o tres.

**Figura:** tabla o barras (ggplot2) con el número de fragmentos que produce
el subconjunto de agosto y septiembre para 800, 1,600 y 3,200 caracteres
[PENDIENTE: correr `fragmentar()` con los tres tamaños; hoy solo se tiene el
dato de 1,600].

**Pie:** Fuente: cálculos propios con ragnar 0.3.0 sobre 26 mañaneras (3 de
agosto a 8 de septiembre de 2026).

**Notas:** Es el primer parámetro que se ajusta en cualquier proyecto de RAG
y no hay un valor correcto universal; depende de cómo están escritos los
documentos.

---

## 11. Embedding: de texto a números

**Título:** Un modelo de embeddings convierte cada fragmento en 1,024 números
que guardan su significado, no sus palabras

**Cuerpo:**

- Un **embedding** es la representación de un texto como un vector de
  números. Textos con significado parecido quedan en puntos cercanos del
  espacio, aunque usen palabras distintas.
- El **modelo de embeddings** que lo produce (aquí bge-m3, multilingüe,
  1,024 dimensiones) es distinto del modelo que redacta: es pequeño, rápido
  y no genera texto. Cuesta 0.1 segundos por fragmento en una laptop.
- Ningún número del vector significa algo por sí solo. Lo que importa es la
  posición del vector completo respecto a los demás.

**Figura:** el esquema "Del párrafo al vector", etapa 3: los dos fragmentos
reales con las 10 primeras y 10 últimas coordenadas de su vector.

**Pie:** Fuente: mañanera del 14 de julio de 2026; embeddings con bge-m3
(BAAI) vía Ollama.

**Términos:** embedding, modelo de embeddings, dimensión.

**Notas:** Regla que importa: el modelo que embebe el corpus debe ser el
mismo que embebe las preguntas. Vectores de dos modelos distintos viven en
espacios distintos y no se pueden comparar.

---

## 12. Similitud coseno: para qué sirven los vectores

**Título:** La pregunta se convierte al mismo espacio y se mide qué fragmento
le queda más cerca

**Cuerpo:**

- La **similitud coseno** es el coseno del ángulo entre dos vectores: vale 1
  si apuntan en la misma dirección y 0 si no tienen relación. La
  **distancia coseno** es 1 menos la similitud.
- Buscar "por significado" es calcular esa distancia entre la pregunta y
  cada fragmento del almacén y quedarse con los menores.

**Figura:** tabla de distancias reales (ya calculadas):

| Pregunta | Fragmento 1 (trae la cifra del 48 %) | Fragmento 2 (la coda) |
|---|---|---|
| ¿Cuánto bajó el homicidio doloso? | 0.310 | 0.431 |
| ¿Cuál es la meta de viviendas en Tlaxcala? | 0.646 | 0.605 |

Opcional si hay tiempo de preparación: proyección en dos dimensiones
(componentes principales, ggplot2) de los 1,824 fragmentos coloreados por
tema (seguridad, vivienda, comercio) para mostrar que se agrupan
[PENDIENTE: generar desde el almacén DuckDB].

**Pie:** Fuente: cálculos propios con bge-m3 sobre la mañanera del 14 de
julio de 2026.

**Términos:** similitud coseno, distancia coseno.

---

## 13. Almacén e índice

**Título:** Los fragmentos, sus metadatos y sus vectores viven en un solo
archivo DuckDB con un índice para buscar rápido

**Cuerpo:**

- Una **base de datos vectorial** guarda fragmentos junto con sus embeddings
  y responde consultas de "vecinos más cercanos". Aquí es DuckDB, una base
  analítica embebida en un archivo (`mananeras_ago_sep.ragnar.duckdb`, 37
  MB).
- Cada fila tiene: texto del fragmento, documento de origen, posiciones
  inicial y final, fecha, título, URL y el vector de 1,024 números.
- El **índice** acelera la búsqueda: en vez de comparar la pregunta con los
  1,824 vectores uno por uno, aproxima el resultado en una fracción del
  tiempo. Se reconstruye cuando se agregan documentos.

**Figura:** esquema de una tabla (matplotlib) con cinco filas de ejemplo y
las columnas listadas; la columna del vector abreviada con "…".

**Pie:** Fuente: estructura del almacén creado con ragnar 0.3.0.

**Términos:** base de datos vectorial, índice, almacén.

**Notas:** Construir el almacén de 26 mañaneras tardó 2.6 minutos; se hace
una vez y se reutiliza. En clase no se reconstruye.

---

## 14. Tres formas de buscar

**Título:** La búsqueda semántica encuentra sinónimos, la léxica encuentra
nombres y cifras, y la híbrida se queda con lo mejor de ambas

**Cuerpo (tres tarjetas):**

- **Búsqueda semántica** (VSS, búsqueda por similitud de vectores). Compara
  embeddings. Encuentra "reducción de homicidios" cuando se pregunta por
  "baja en la violencia".
- **Búsqueda léxica** (BM25). Compara palabras, ponderadas por qué tan raras
  son en el corpus. Gana con términos exactos: "Kanasín", "Hemosa
  Ingeniería", "40.8". En mañaneras pesa mucho.
- **Búsqueda híbrida.** Ejecuta las dos y fusiona las listas. Es la opción
  por defecto de ragnar y el punto de partida recomendado.
- **top-k**: cuántos fragmentos se recuperan (5 en el script). Más
  fragmentos dan más cobertura y más ruido.

**Figura:** salida real del paso 4 del script para la pregunta de homicidios:
tres tablas pequeñas (fecha, distancia o puntaje BM25, inicio del
fragmento), una por método. Captura de consola limpia o tabla reconstruida.

**Pie:** Fuente: `02_rag_mananeras.R`, paso 4; Robertson y Zaragoza (2009)
para BM25.

**Términos:** búsqueda semántica, búsqueda léxica, búsqueda híbrida, top-k,
consulta.

**Notas:** Demostración en vivo 1: correr el paso 4 con una pregunta que
proponga el grupo. Es rápido y no necesita el generador.

---

## 15. Filtrar por metadatos

**Título:** La fecha permite acotar la búsqueda antes de buscar: "qué dijo
sobre aranceles la primera semana de septiembre"

**Cuerpo:**

- Los metadatos guardados con cada fragmento se usan como filtro previo:
  primero se descartan los fragmentos fuera del periodo y luego se ordena
  por cercanía.
- Es lo nuevo frente a un corpus de PDFs sueltos: en un corpus fechado, la
  mitad de las preguntas reales traen un periodo ("en julio", "después del
  informe").

**Figura:** dos tablas lado a lado con la misma consulta ("aranceles a países
sin tratado de libre comercio"): sin filtro trae fechas de todo el corpus
(4, 13, 14 y 24 de agosto, 2 de septiembre); con filtro del 1 al 7 de
septiembre trae solo el 2, 3 y 4 de septiembre.

**Pie:** Fuente: `02_rag_mananeras.R`, paso 4d.

**Términos:** filtro por metadatos.

---

## 16. El prompt aumentado

**Título:** "Aumentar" el prompt significa literalmente pegarle los cinco
fragmentos antes de la pregunta

**Cuerpo:**

- El **prompt aumentado** es el mensaje final que recibe el generador:
  instrucciones, fragmentos recuperados (cada uno con su fecha) y la
  pregunta. En el ejemplo mide 7,354 caracteres.
- La **instrucción de sistema** fija las reglas: responder solo con los
  fragmentos, citar la fecha de cada dato y decir "no aparece en las
  mañaneras consultadas" cuando no esté. Es la primera defensa contra la
  alucinación.

**Figura:** el prompt real, abreviado, en una caja monoespaciada con tres
bloques coloreados: instrucciones (navy), fragmentos con su etiqueta
"[Mañanera del 08/09/2026]" (gris), pregunta (verde).

**Pie:** Fuente: `02_rag_mananeras.R`, paso 5a.

**Términos:** prompt aumentado, instrucción de sistema.

---

## 17. La respuesta con cita

**Título:** El generador redacta a partir de los fragmentos y cita la
mañanera de donde salió cada dato

**Cuerpo:**

- El **modelo generador** es el LLM que escribe la respuesta. Aquí es
  qwen3.5:4b, corriendo en la laptop; puede cambiarse por Claude o GPT sin
  tocar el almacén.
- Respuesta real a "¿Cuál fue el promedio diario de homicidios dolosos en
  agosto de 2026?": "El promedio diario de homicidios dolosos en México
  cerró en 40.8 en agosto de 2026, cifra confirmada por la Presidenta
  Claudia Sheinbaum en su conferencia de prensa del día 8 de septiembre de
  2026. […] Para el estado de Zacatecas, el informe presentado el 4 de
  septiembre de 2026 indica un dato preliminar de 0.17 homicidios diarios".
- La **atribución** es la ventaja central de RAG: cada afirmación se puede
  rastrear a un fragmento y verificar. Tardó 13 segundos.

**Figura:** la respuesta en una tarjeta verde, con las dos fechas citadas
resaltadas y flechas a dos miniaturas de los fragmentos de origen.

**Pie:** Fuente: `02_rag_mananeras.R`, paso 5a; generador qwen3.5:4b vía
Ollama.

**Términos:** modelo generador, atribución (trazabilidad).

**Notas:** Demostración en vivo 2: correr el paso 5a. Mientras responde (12
segundos), explicar que el modelo está leyendo 7,000 caracteres y
escribiendo palabra por palabra.

---

## 18. Variante con herramienta

**Título:** En la variante con herramienta, el modelo decide cuándo buscar y
con qué palabras

**Cuerpo:**

- Una **herramienta** es una función que el modelo puede invocar. La
  búsqueda en el almacén se registra como herramienta y el modelo la llama
  con la consulta que él mismo formula, a veces varias veces.
- Ventaja: sirve para preguntas compuestas o para conversaciones largas.
  Costo: los modelos pequeños se confunden con salidas largas, por eso la
  herramienta devuelve texto plano y solo tres fragmentos.
- Respuesta real: "Según los datos de la mañanera del 13/08/2026, los
  pasajeros internacionales transportados por el Tren Maya fueron 56 mil
  763 […]".

**Figura:** diagrama (matplotlib) del ciclo: Pregunta → Modelo formula
consulta → Herramienta busca → Devuelve 3 fragmentos → Modelo redacta. En
contraste con el flujo lineal de la diapositiva 7.

**Pie:** Fuente: `02_rag_mananeras.R`, paso 5b.

**Términos:** herramienta, llamada a herramientas.

---

## 19. La pregunta de control

**Título:** Ante una pregunta sin respuesta en el corpus, el sistema debe
abstenerse, y el modelo pequeño lo logró al segundo intento

**Cuerpo:**

- Pregunta de control: "¿Qué dijo la presidenta sobre el resultado del
  Mundial de 2030?". No hay nada en las mañaneras.
- Primer intento (real): el modelo divagó sobre un medallero y "el espíritu
  de ser grandes anfitriones".
- Segundo intento (real): "No aparecen datos específicos del Mundial de 2030
  en las mañaneras consultadas".
- Lección: la recuperación fue correcta las dos veces (no había nada
  relevante); la generación es la que falla. Un sistema de RAG hereda los
  errores de sus dos modelos.

**Figura:** dos tarjetas, roja (intento 1) y verde (intento 2), con el texto
real.

**Pie:** Fuente: `02_rag_mananeras.R`, paso 5b; generador qwen3.5:4b.

**Notas:** Aquí conviene decir que con un generador más grande el primer
intento no habría ocurrido, y que aun así la instrucción de sistema no
garantiza nada: hay que evaluar.

---

## 20. Evaluación

**Título:** Con ocho preguntas de respuesta conocida, los tres métodos
recuperaron la mañanera correcta el 100 % de las veces

**Cuerpo:**

- Un **conjunto de prueba** es una lista de preguntas con respuesta y
  fragmento esperado, escrita a mano por quien conoce el corpus. Sin él no
  hay forma de saber si un cambio mejoró o empeoró el sistema.
- **hit@k** es la proporción de preguntas para las que el documento correcto
  aparece entre los k primeros recuperados. Es la métrica más simple y la
  primera que se calcula.
- Lo que hit@5 no mide: **fidelidad** (si la respuesta se sostiene solo en
  los fragmentos) y **completitud** (si cubre todo lo que se preguntó). La
  diapositiva anterior es un fallo de fidelidad con recuperación perfecta.

**Figura:** tabla con las ocho preguntas, la fecha esperada y tres columnas
de acierto (semántica, léxica, híbrida), todas en verde; fila final con
100 % / 100 % / 100 %.

**Pie:** Fuente: `02_rag_mananeras.R`, paso 6; 26 mañaneras, top-k = 5.

**Términos:** conjunto de prueba, hit@k, fidelidad, completitud.

**Notas:** Ser honesto con el grupo: 100 % significa que las preguntas
fueron fáciles (datos únicos, con nombres propios). Proponer como ejercicio
escribir preguntas más ambiguas y ver dónde cae.

---

## 21. Decisiones y límites

**Título:** Cada parámetro del pipeline es una decisión con costo: tamaño de
fragmento, top-k, modelo y hardware

**Cuerpo (cuatro tarjetas):**

- **Tamaño de fragmento y traslape.** Afectan precisión y volumen. Se
  ajustan con el conjunto de prueba, no por intuición.
- **top-k.** Más fragmentos, más cobertura y más ruido; también más tokens
  y más tiempo.
- **Modelos.** Embeddings locales (bge-m3, 0.1 s por fragmento) y generador
  local (qwen3.5:4b, 12 s por respuesta) corren en una laptop de 16 GB. Un
  generador remoto responde en 2 s pero requiere llave y envía el texto
  fuera.
- **Corpus.** RAG no arregla un corpus malo: si la transcripción tiene
  errores o le faltan días, las respuestas los heredan.

**Pie:** Fuente: mediciones propias en una Mac de 16 GB, 8 de septiembre de
2026.

---

## 22. Conceptos clave

**Título:** Los términos de la sesión, en el orden en que aparecen en el
pipeline

**Cuerpo (lista en dos columnas, una línea por término):**

Columna 1, el problema y el corpus: modelo de lenguaje grande · token ·
ventana de contexto · fecha de corte · alucinación · RAG · corpus ·
ingesta · metadatos · fragmentación · tamaño y traslape.

Columna 2, búsqueda y generación: embedding · modelo de embeddings ·
similitud coseno · base de datos vectorial · índice · búsqueda semántica,
léxica e híbrida · top-k · prompt aumentado · instrucción de sistema ·
herramienta · modelo generador · atribución · conjunto de prueba · hit@k ·
fidelidad.

**Notas:** Remitir al glosario escrito (`glosario_rag.md`) con definiciones
y referencias.

---

## 23. Recursos

**Título:** Todo el material corre en R con tres herramientas de código
abierto y sin llaves de API

**Cuerpo (tres tarjetas):**

- **Ollama.** Ejecuta modelos en la computadora local. `ollama pull bge-m3`
  y `ollama pull qwen3.5:4b`.
- **ragnar** (Kalinowski y Falbel, 2026). Pipeline completo de RAG en R:
  lectura, fragmentación, embeddings, DuckDB, búsqueda híbrida.
- **ellmer.** Conversación con modelos y registro de herramientas desde R.

Scripts de la sesión: `01_scraper_mananeras.R` (corpus) y
`02_rag_mananeras.R` (pipeline). Lecturas: Lewis et al. (2020) para RAG;
Robertson y Zaragoza (2009) para BM25.

**Pie:** Referencias completas en el glosario.

---

## 24. Conclusiones (queda visible durante preguntas)

**Título:** Cinco ideas para llevarse

**Cuerpo (caja verde de resumen):**

1. Un modelo de lenguaje redacta bien pero no consulta nada: lo que no
   estaba en su entrenamiento lo inventa.
2. RAG cambia la regla: buscar primero, redactar después, y citar de dónde
   salió cada dato.
3. Intervienen dos modelos distintos: el de embeddings busca por
   significado; el generador redacta. Se cambian por separado.
4. La calidad depende de decisiones concretas: cómo se fragmenta, cuántos
   fragmentos se recuperan y qué tan bueno es el corpus.
5. Nada de esto se sabe sin evaluar: un conjunto de prueba escrito a mano
   vale más que cualquier intuición.

---

## 25. Cierre

**Título:** Gracias

**Cuerpo:** ¿Preguntas? · [PENDIENTE: correo o contacto del expositor]

---

## Figuras que hay que generar con código antes de armar el .pptx

| # | Figura | Datos | Herramienta |
|---|---|---|---|
| 4 | Línea de tiempo: fecha de corte frente a mañaneras | fechas del índice | matplotlib |
| 7 | Diagrama de flujo de RAG frente al camino sin RAG | ninguno | matplotlib |
| 8 | Caracteres por mañanera por fecha, con hueco del 1 de septiembre | `indice_mananeras.csv` | ggplot2 |
| 9 | Regla de fragmentación del pasaje del 14 de julio | `esquema.json` (ya calculado) | matplotlib |
| 10 | Fragmentos por tamaño (800, 1,600, 3,200) | correr `fragmentar()` tres veces | ggplot2 |
| 11 | Vectores de los dos fragmentos | `esquema.json` | matplotlib (tabla) |
| 12 | Opcional: proyección 2D de los 1,824 fragmentos | almacén DuckDB | R (prcomp) + ggplot2 |
| 13 | Esquema de la tabla del almacén | estructura de ragnar | matplotlib |
| 14 | Tablas de los tres métodos de búsqueda | salida del paso 4 | tabla nativa o PNG |
| 15 | Con filtro y sin filtro | salida del paso 4d | tabla |
| 18 | Ciclo con herramienta | ninguno | matplotlib |
| 20 | Tabla de evaluación | salida del paso 6 | tabla |

## Pendientes que requieren tu decisión

- Nombre del curso, grupo y fecha (diapositivas 1 y 25).
- Respuesta sin RAG para la diapositiva 5: hay que generarla con qwen3.5:4b
  y pegarla textual; no se inventa.
- Conteo de fragmentos con 800 y 3,200 caracteres (diapositiva 10): hay que
  correrlo.
- Si se incluye la proyección 2D (diapositiva 12): añade unos 15 minutos de
  preparación y una figura vistosa; no es indispensable.
- Duración: con las dos demostraciones en vivo el guion da para 60 a 75
  minutos. Si la sesión es de 50, se quitan las diapositivas 15 y 18.
