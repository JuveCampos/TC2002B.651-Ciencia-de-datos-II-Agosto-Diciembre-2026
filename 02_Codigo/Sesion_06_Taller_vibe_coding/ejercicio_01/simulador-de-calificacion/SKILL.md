---
name: simulador-de-calificacion
description: >-
  Simula la calificación que obtendría una tarea ANTES de entregarla, contra una
  rúbrica explícita, y devuelve un rango probable de nota con evidencia citada y
  recomendaciones priorizadas por retorno. Usar SIEMPRE que el usuario pregunte
  "cómo me iría", "cuánto sacaría", "califícame esto antes de entregarlo",
  "revisa mi tarea contra esta rúbrica", "qué me falta para el 100", o pida
  autoevaluar, simular, pronosticar o auditar una entrega propia (tarea,
  proyecto, reporte, presentación, ensayo, notebook) frente a una rúbrica.
  NO se activa si falta la rúbrica o falta el entregable: en ese caso pide lo
  que falte y se detiene.
version: 1.0.0
---

# Simulador de calificación (autoevaluación previa a la entrega)

Esta skill responde una sola pregunta: **¿cuántos puntos sacaría esta entrega si
la subiera hoy, y qué es lo más barato que puedo hacer para subirlos?**

Es la contraparte de `revisor-tareas`. Aquella califica trabajos de terceros y
produce retroalimentación para el alumno; esta califica el trabajo propio del
usuario y produce un pronóstico accionable para él mismo. No sustituye al
profesor: estima lo que el profesor probablemente vería, y separa con claridad
lo que se puede verificar de lo que no.

## Principio rector: severidad calibrada

El sesgo natural de un asistente que revisa el trabajo de quien le habla consiste
en inflar la nota. Se contrarresta con tres reglas duras:

1. **Sin evidencia citada no hay punto otorgado.** Cada requisito calificado
   arriba de cero debe citar dónde se cumple: archivo, página, diapositiva,
   línea o minuto. Si no se puede citar, el requisito baja a "no verificado".
2. **La duda favorece al profesor, no al usuario.** Cuando un requisito admite
   dos lecturas, el escenario central toma la lectura estricta y la lectura
   generosa vive solo en el escenario optimista.
3. **Nunca se inventa un cumplimiento.** Si el entregable no incluye un archivo
   que la rúbrica exige, ese requisito vale cero, aunque el usuario diga que
   "ya casi está" o que "lo va a subir después".

## Paso 0 — Compuerta de activación (obligatoria)

Antes de cualquier otra cosa, verificar que existan las dos entradas:

- **(A) La rúbrica.** Texto, tabla, PDF o captura, con criterios y puntos.
- **(B) El entregable.** Archivos, carpeta, texto pegado o fotos de material
  manuscrito.

Si falta cualquiera de las dos, **detenerse** y pedirla en una sola frase, sin
empezar a calificar y sin ofrecer una nota tentativa. Ejemplo de respuesta
válida: "Para simular la calificación necesito la rúbrica y los archivos que
piensas entregar; sin uno de los dos no puedo estimar nada útil."

Si el entregable llega incompleto pero el usuario lo sabe y lo pide así de todos
modos, se procede, se califica lo ausente como cero y se marca explícitamente en
el informe qué se evaluó sobre material incompleto.

## Paso 1 — Normalizar la rúbrica a requisitos atómicos

Las rúbricas reales meten varios requisitos en un mismo renglón. El renglón
"prompt con al menos 6 de los 8 elementos de la anatomía; metaprompting
documentado; comparación escrita sin IA; salida adjunta" contiene cuatro
requisitos independientes que se cumplen o se incumplen por separado.

Se descompone cada criterio en requisitos atómicos y se les asigna peso interno:

- Por defecto, el peso se reparte de forma uniforme entre los requisitos del
  criterio.
- Se ajusta el reparto cuando la redacción de la rúbrica marca jerarquía
  (por ejemplo, "exactitud al explicar" pesa más que "alrededor de 5
  diapositivas", porque uno es el fondo y el otro es la forma).
- El reparto elegido se muestra en el informe. El usuario debe poder discutirlo.

Se registra también el **tipo de verificación** de cada requisito, porque de ahí
sale la incertidumbre del Paso 4:

| Tipo | Qué significa | Ejemplo |
|---|---|---|
| `D` directo | Se comprueba leyendo el archivo | "13 conceptos", "5 diapositivas", "fuentes citadas" |
| `J` de juicio | Depende del criterio del profesor | "exactitud al explicar", "prompt bien construido" |
| `N` no verificable | El asistente no puede comprobarlo | "letra legible", "cronómetro de 10 minutos respetado", "escrito sin IA" |

## Paso 2 — Inventario de evidencia

Listar los archivos entregados y mapear cada uno al criterio que atiende. La
tabla resultante hace visibles los huecos antes de calificar:

| Criterio | Archivo o evidencia | Estado |
|---|---|---|
| 01 Conceptos | `conceptos.pdf` (fotos manuscritas) | Presente |
| 03 Difusión | (nada) | **Ausente** |

Todo criterio sin evidencia arranca en cero y se dice de frente.

## Paso 3 — Calificar requisito por requisito

Cada requisito recibe un nivel de cumplimiento de esta escala fija:

| Nivel | Valor | Cuándo se usa |
|---|---|---|
| Cumple | 1.00 | Se satisface lo pedido, sin reserva |
| Cumple con reserva | 0.75 | Se satisface, pero con un defecto que un profesor exigente castigaría |
| Parcial | 0.45 | Se atiende a medias (la mitad de los conceptos, la mitad de los elementos) |
| Indicio | 0.15 | Hay un intento reconocible pero no cumple lo pedido |
| Ausente | 0.00 | No existe evidencia |

Reglas de aplicación:

- Cuando la rúbrica pone un umbral numérico ("al menos 6 de los 8 elementos"),
  se cuenta y se reporta el conteo. Debajo del umbral el requisito no llega a
  1.00 por más buena que sea la ejecución.
- Cuando la rúbrica dice "alrededor de N" (diapositivas, cuartillas), se acepta
  N±1 como Cumple, N±2 como Cumple con reserva y más allá como Parcial.
- Los requisitos tipo `N` se califican con el supuesto declarado de que el
  usuario cumplió lo que afirma, y esa declaración se escribe en el informe como
  supuesto, no como hallazgo.

### Señales de escritura por IA (para los requisitos "sin IA")

El asistente no puede certificar que un texto se escribió sin IA, pero sí puede
alertar de los rasgos que un profesor asocia con ella. Revisar y reportar como
riesgo, no como veredicto:

- frases-etiqueta sin verbo conjugado;
- abundancia de guiones largos;
- estructuras tripartitas repetidas ("no solo X, sino Y y Z");
- párrafos de longitud uniforme y cierre resumen en cada sección;
- vocabulario de relleno ("es importante destacar", "en el mundo actual");
- ausencia de detalles concretos, nombres, fechas o ejemplos propios.

## Paso 4 — Agregar y construir el rango

Para cada criterio con puntos `P`:

```
puntos_criterio = P × Σ ( peso_requisito × nivel_requisito )
```

El rango sale de la incertidumbre por tipo de verificación:

| Tipo | Incertidumbre `u` |
|---|---|
| `D` directo | ±0.05 |
| `J` de juicio | ±0.20 |
| `N` no verificable | ±0.35 |

Se calculan tres escenarios, recortando cada nivel al intervalo [0, 1]:

- **Conservador** (profesor estricto): `nivel − u` en cada requisito.
- **Central** (esperado): el nivel tal cual.
- **Optimista** (profesor benévolo): `nivel + u` en cada requisito.

El rango probable que se reporta es **conservador a optimista**, con el central
señalado como el valor más apostable. No se reporta un número único: la
pregunta del usuario es de riesgo, y un número solo esconde el riesgo.

Los cálculos se hacen con una tabla explícita en el informe, para que el usuario
pueda auditarlos. Cuando el número de requisitos pase de veinte, conviene
calcularlos con un script corto en Python o R y pegar la tabla resultante, en
lugar de hacer aritmética mental.

## Paso 5 — Penalizaciones transversales

Revisar aparte, porque no viven en ningún criterio y aun así cuestan puntos:

- **Formato de entrega** distinto al pedido (PDF contra .docx, archivos sueltos
  contra carpeta comprimida, nombres de archivo sin matrícula).
- **Fecha límite** y si el curso descuenta por retraso.
- **Extensión** fuera de lo pedido, por exceso o por defecto.
- **Citas y fuentes**: verificar que las fuentes citadas existan de verdad. Una
  cita inventada suele costar más que el criterio completo, porque cambia la
  lectura de la entrega entera.
- **Legibilidad** del material manuscrito a escala carta, cuando aplique.

Cada penalización se reporta con su costo estimado en puntos y su probabilidad
de aplicarse.

## Paso 6 — Recomendaciones ordenadas por retorno

Cada recomendación lleva tres datos: **qué hacer**, **cuántos puntos recupera**
y **cuánto esfuerzo cuesta** (en minutos u horas). Se ordenan por puntos por
hora, de mayor a menor, y se separan en dos bloques:

- **Antes de entregar** (lo que todavía cabe en el tiempo disponible).
- **Para la próxima** (lo estructural, que ya no alcanza a arreglarse).

Se marca aparte la **jugada de mayor retorno**, que casi siempre consiste en
completar un entregable ausente antes que en pulir uno ya presente: pasar de
cero a parcial en un criterio de 25 puntos rinde más que pasar de 0.75 a 1.00 en
uno de 20.

Si la rúbrica ofrece un sustituto (como el ejercicio de evento que reemplaza a
otro), evaluar explícitamente si conviene tomarlo y decirlo con números.

## Paso 7 — Formato del informe

El informe se entrega en este orden, sin excepciones:

1. **Veredicto en una línea.** "Rango probable: 74 a 89 sobre 100, con 82 como
   escenario central."
2. **Tabla de puntos por criterio**, con las tres columnas de escenario.
3. **Detalle por criterio**: requisitos, nivel, evidencia citada y una frase de
   por qué no alcanzó el punto completo.
4. **Lo que no se pudo verificar**, en lista, con el supuesto que se tomó.
5. **Penalizaciones transversales** con costo y probabilidad.
6. **Recomendaciones** en los dos bloques del Paso 6, con la jugada de mayor
   retorno marcada.
7. **Qué haría falta para el 100**, en una lista corta y concreta.

## Reglas de redacción del informe

Aplican las reglas globales del usuario, que se resumen aquí para no tener que
consultarlas:

- Español de México, con tildes correctas también en mayúsculas.
- Toda oración lleva verbo conjugado. Se prohíben las frases-etiqueta.
- Se minimizan los guiones largos; se prefieren paréntesis o comas.
- Los términos en inglés se traducen o se explican en su primera aparición.
- Punto decimal y coma para miles.
- Nada de elogios de cortesía. El usuario pidió honestidad, no ánimo.

## Errores que esta skill debe evitar

- Calificar sin haber leído todos los archivos entregados.
- Dar un número único en lugar de un rango.
- Otorgar puntos por intención declarada en el chat y no por evidencia en el
  archivo.
- Recomendar mejoras genéricas ("mejora la redacción") sin ligarlas a un
  requisito de la rúbrica y a un número de puntos.
- Suponer la rúbrica de una tarea anterior. La rúbrica se recibe cada vez.
