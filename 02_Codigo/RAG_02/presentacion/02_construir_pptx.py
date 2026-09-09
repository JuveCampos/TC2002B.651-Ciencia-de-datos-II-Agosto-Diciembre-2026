"""Construye RAG_mananeras.pptx (estilo Tec, 4:3, Ubuntu) a partir del guion
plan_presentacion.md, las figuras de img_presentacion/ y los datos reales."""
import json, re
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.oxml.ns import qn

IMG = "img_presentacion"
OUT = "RAG_mananeras.pptx"
NAVY = RGBColor(0x1E, 0x4C, 0x7D); LIGHT_BLUE = RGBColor(0xEA, 0xF2, 0xFA); SOFT_BLUE = RGBColor(0xDD, 0xE5, 0xED)
SOFT_GREEN = RGBColor(0xD5, 0xF5, 0xE3); DARK_GREEN = RGBColor(0x1A, 0x7A, 0x3A); SOFT_RED = RGBColor(0xFA, 0xDB, 0xD8)
DARK_RED = RGBColor(0xC0, 0x39, 0x2B); HIGHLIGHT_GREEN = RGBColor(0xF0, 0xFA, 0xF0); GRAY_TOP = RGBColor(0xF0, 0xF0, 0xF0)
GRAY = RGBColor(0x55, 0x55, 0x55); WHITE = RGBColor(0xFF, 0xFF, 0xFF); BLACK = RGBColor(0, 0, 0)
SOFT_GOLD = RGBColor(0xF6, 0xEC, 0xC8); DARK_GOLD = RGBColor(0x6B, 0x52, 0x10)
UBUNTU = "Ubuntu"
TOTAL = 25
TITULO_CORTO = "RAG con las mañaneras"

D = json.load(open("datos/datos_presentacion.json", encoding="utf-8"))
LOG = open("datos/salida_02_rag.log", encoding="utf-8").read().splitlines()
def linea_log(prefijo):
    return next(l for l in LOG if l.startswith(prefijo)).replace("**", "").strip()
RESP_MANUAL = linea_log("El promedio diario de homicidios dolosos")
RESP_HERR = linea_log("Según los datos de la mañanera del 13/08/2026")
RESP_CTRL1 = linea_log("En la mañanera del 12/08/2026")
RESP_CTRL2 = linea_log("No aparecen datos específicos del Mundial")
SIN_RAG = D["sin_rag"].split("\n\n")[0].strip()

prs = Presentation(); prs.slide_width = Inches(10); prs.slide_height = Inches(7.5)
SW, SH = prs.slide_width, prs.slide_height; BLANK = prs.slide_layouts[6]

def quitar_estilo(shape):
    el = shape._element.find(qn("p:style"))
    if el is not None: shape._element.remove(el)

def add_text(slide, text, left, top, width, height, *, size=14, bold=False, color=BLACK, align=PP_ALIGN.LEFT,
             italic=False, line_spacing=None, anchor=None, font=UBUNTU):
    box = slide.shapes.add_textbox(left, top, width, height); tf = box.text_frame; tf.word_wrap = True
    for m in ("margin_left", "margin_right", "margin_top", "margin_bottom"): setattr(tf, m, Emu(0))
    if anchor is not None: tf.vertical_anchor = anchor
    for i, line in enumerate(text.split("\n")):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph(); p.alignment = align
        if line_spacing: p.line_spacing = line_spacing
        r = p.add_run(); r.text = line; r.font.size = Pt(size); r.font.bold = bold; r.font.italic = italic
        r.font.color.rgb = color; r.font.name = font
    return box

def add_rect(slide, left, top, width, height, fill, *, line=None):
    sh = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, left, top, width, height)
    sh.fill.solid(); sh.fill.fore_color.rgb = fill
    if line is None: sh.line.fill.background()
    else: sh.line.color.rgb = line; sh.line.width = Pt(1)
    sh.shadow.inherit = False; quitar_estilo(sh); return sh

def add_header(slide, title):
    add_rect(slide, 0, Inches(0.3), SW, Inches(0.95), NAVY)
    add_text(slide, title, Inches(0.35), Inches(0.3), Inches(9.3), Inches(0.95), size=18, bold=True, color=WHITE,
             anchor=MSO_ANCHOR.MIDDLE)

def add_card(slide, left, top, width, height, *, fill=LIGHT_BLUE, title=None, body=None, title_color=NAVY,
             body_color=BLACK, title_size=13, body_size=11, line_spacing=1.25):
    add_rect(slide, left, top, width, height, fill)
    if title and body:
        add_text(slide, title, left + Inches(0.12), top + Inches(0.08), width - Inches(0.24), Inches(0.4), size=title_size, bold=True, color=title_color)
        add_text(slide, body, left + Inches(0.12), top + Inches(0.42), width - Inches(0.24), height - Inches(0.5), size=body_size, color=body_color, line_spacing=line_spacing)
    elif title:
        add_text(slide, title, left + Inches(0.12), top + Inches(0.08), width - Inches(0.24), height - Inches(0.16), size=title_size, bold=True, color=title_color, anchor=MSO_ANCHOR.MIDDLE, line_spacing=line_spacing)
    elif body:
        add_text(slide, body, left + Inches(0.12), top + Inches(0.1), width - Inches(0.24), height - Inches(0.2), size=body_size, color=body_color, line_spacing=line_spacing)

def add_footer(slide, num, fuente=None):
    if fuente:
        add_text(slide, fuente, Inches(0.3), Inches(7.16), Inches(7.0), Inches(0.3), size=9, color=GRAY)
    add_text(slide, f"{TITULO_CORTO} · {num}/{TOTAL}", Inches(7.4), Inches(7.16), Inches(2.3), Inches(0.3), size=9, color=GRAY, align=PP_ALIGN.RIGHT, italic=True)

def add_pic(slide, name, left, top, width=None, height=None):
    return slide.shapes.add_picture(f"{IMG}/{name}.png", left, top, width=width, height=height)

def notas(slide, texto):
    slide.notes_slide.notes_text_frame.text = texto

def nueva(title=None):
    s = prs.slides.add_slide(BLANK)
    if title: add_header(s, title)
    return s

def tres_cards(slide, top, height, cards, **kw):
    xs = [0.3, 3.43, 6.57]
    for x, (fill, tcol, t, b) in zip(xs, cards):
        add_card(slide, Inches(x), top, Inches(3.0), height, fill=fill, title_color=tcol, title=t, body=b, **kw)

# ---------------------------------------------------------------- 1 Portada
s = nueva()
add_rect(s, 0, 0, SW, Inches(1.1), GRAY_TOP)
add_text(s, "Tecnológico de Monterrey", Inches(0.4), Inches(0.25), Inches(6), Inches(0.6), size=20, color=NAVY, bold=True, anchor=MSO_ANCHOR.MIDDLE)
add_rect(s, 0, Inches(1.1), SW, Inches(3.7), SOFT_BLUE)
add_text(s, "RAG con las mañaneras", Inches(0.6), Inches(1.5), Inches(8.8), Inches(1.0), size=48, color=NAVY, bold=True)
add_text(s, "Cómo hacer que un modelo de lenguaje lea antes de responder", Inches(0.6), Inches(2.55), Inches(8.8), Inches(0.7), size=24, color=NAVY, bold=True)
add_text(s, "Recuperación, embeddings y generación con las conferencias de prensa\nde la presidenta, todo en R y en tu computadora", Inches(0.6), Inches(3.45), Inches(8.8), Inches(1.0), size=16, color=NAVY, italic=True, line_spacing=1.2)
add_text(s, "[PENDIENTE: nombre del curso y grupo]\n[PENDIENTE: fecha de la sesión]", Inches(0.6), Inches(5.4), Inches(8.8), Inches(0.9), size=14, color=BLACK, line_spacing=1.3)
notas(s, "Adelantar que habrá dos demostraciones en vivo: la búsqueda sin generador y la respuesta completa.")

# ---------------------------------------------------------------- 2 Hoja de ruta
s = nueva("La sesión recorre el flujo completo, de las mañaneras crudas a una respuesta con cita")
bloques = [("1. El problema", "Qué sabe y qué no sabe un modelo de lenguaje, y por qué inventa cuando no sabe."),
           ("2. El corpus", "71 mañaneras convertidas en texto plano con fecha y fuente, descargadas con R."),
           ("3. El flujo de trabajo", "Fragmentar, convertir en vectores, guardar, buscar y redactar. Dos demostraciones en vivo."),
           ("4. La evaluación", "Cómo sabemos si funcionó, qué mide hit@5 y qué no mide, y dónde falla el sistema.")]
for (x, y), (t, b) in zip([(0.3, 1.7), (5.05, 1.7), (0.3, 4.3), (5.05, 4.3)], bloques):
    add_card(s, Inches(x), Inches(y), Inches(4.65), Inches(2.3), title=t, body=b, title_size=20, body_size=17, line_spacing=1.45)
add_footer(s, 2)

# ---------------------------------------------------------------- 3 Situación
s = nueva("Un modelo de lenguaje predice la siguiente palabra, y con eso redacta, resume y conversa")
add_text(s, "predice la\nsiguiente palabra", Inches(0.3), Inches(1.5), Inches(9.4), Inches(2.0), size=44, bold=True, color=NAVY, align=PP_ALIGN.CENTER, line_spacing=1.0)
add_text(s, "Eso es todo lo que hace. Y con eso basta para responder preguntas, resumir y redactar con fluidez.", Inches(0.8), Inches(3.55), Inches(8.4), Inches(0.5), size=14, italic=True, color=GRAY, align=PP_ALIGN.CENTER)
tres_cards(s, Inches(4.3), Inches(2.6), [
    (LIGHT_BLUE, NAVY, "Modelo de lenguaje grande", "Un modelo estadístico entrenado con enormes cantidades de texto para predecir qué palabra sigue. Todo lo que \"sabe\" quedó fijado en sus parámetros durante el entrenamiento: al responder no consulta nada."),
    (LIGHT_BLUE, NAVY, "Token", "La unidad mínima con la que trabaja: un fragmento de palabra. En español, mil tokens son unas 600 o 700 palabras. Costos, límites y tamaños de fragmento se miden en tokens."),
    (LIGHT_BLUE, NAVY, "Ventana de contexto", "Cuántos tokens puede leer de una sola vez. En el modelo de la sesión son 8,192 tokens, unas 5,000 palabras. Una mañanera completa tiene unas 14,000: no cabe.")])
add_footer(s, 3)

# ---------------------------------------------------------------- 4 Fecha de corte
s = nueva("Lo que el modelo sabe se congeló en su fecha de corte: no leyó la mañanera de ayer")
add_pic(s, "fig04_linea_tiempo", Inches(0.3), Inches(1.4), height=Inches(3.35))
add_card(s, Inches(0.3), Inches(4.95), Inches(9.4), Inches(2.05), title="Fecha de corte del conocimiento", body=(
    "Es la fecha hasta la que llegan los datos con los que se entrenó el modelo. Todo lo posterior no existe para él. "
    "Tampoco conoce nunca lo que no estaba en internet al entrenarse: actas internas, bases propias, encuestas sin publicar.\n"
    "Las mañaneras son el caso extremo: hay una nueva cada día hábil y cada una trae cifras, nombres y anuncios que no estaban en ningún lado la víspera."), body_size=12, line_spacing=1.3)
add_footer(s, 4, "Fuente: corpus propio de mañaneras (gob.mx). La fecha de corte varía por modelo y proveedor.")

# ---------------------------------------------------------------- 5 Alucinación
s = nueva("Cuando no sabe, el modelo no se calla: afirma con seguridad cosas falsas")
add_rect(s, Inches(0.3), Inches(1.45), Inches(9.4), Inches(0.75), NAVY)
add_text(s, "¿Cuál fue el promedio diario de homicidios dolosos en México en agosto de 2026,\nsegún lo que informó la presidenta Claudia Sheinbaum en su conferencia de prensa?", Inches(0.45), Inches(1.45), Inches(9.1), Inches(0.75), size=12, bold=True, color=WHITE, anchor=MSO_ANCHOR.MIDDLE, align=PP_ALIGN.CENTER)
add_card(s, Inches(0.3), Inches(2.35), Inches(4.65), Inches(2.9), fill=SOFT_RED, title_color=DARK_RED, title="Sin documentos: qwen3.5:4b, respuesta textual",
         body="“" + SIN_RAG + "”", body_size=11.5, line_spacing=1.3)
add_card(s, Inches(5.05), Inches(2.35), Inches(4.65), Inches(2.9), fill=SOFT_GREEN, title_color=DARK_GREEN, title="Lo que dijo la mañanera del 8 de septiembre",
         body="“…el mes que acaba de concluir que cerró en un promedio de 40.8 homicidios diarios, siendo además este agosto de 2026 el mes más bajo de estos meses analizados.”\n\nEl modelo no solo desconoce el dato: asegura que agosto de 2026 no ha ocurrido y que Sheinbaum no ha sido electa. Todo dicho con el mismo tono seguro.", body_size=11.5, line_spacing=1.3)
add_card(s, Inches(0.3), Inches(5.45), Inches(9.4), Inches(1.5), fill=HIGHLIGHT_GREEN, title_color=DARK_GREEN, title="Alucinación",
         body="Una afirmación fluida, con el tono correcto, y falsa. Ocurre porque el modelo optimiza plausibilidad, no verdad. Sin la fuente a la mano no hay forma de distinguirla de una respuesta correcta.", body_size=11)
add_footer(s, 5, "Fuente: versión estenográfica del 8 de septiembre de 2026, Presidencia de la República; respuesta generada con qwen3.5:4b vía Ollama.")
notas(s, "Momento de tensión de la clase. Preguntar al grupo cómo distinguirían la respuesta inventada de la real si no tuvieran la fuente.")

# ---------------------------------------------------------------- 6 Tres caminos
s = nueva("De las tres formas de darle información nueva a un modelo, solo una escala a un corpus que cambia cada día")
filas = [["", "Ajuste fino", "Contexto largo", "RAG"],
         ["Qué hace", "Reentrena parte del modelo con datos propios", "Pega todos los documentos en el prompt", "Busca los fragmentos relevantes y solo pega esos"],
         ["Costo", "Alto: horas de cómputo por versión", "Bajo por consulta, pero crece con el corpus", "Bajo: el índice se construye una vez"],
         ["Actualización", "Reentrenar", "Volver a pegar todo", "Agregar archivos al almacén"],
         ["Cita la fuente", "No", "Difícil", "Sí: es su ventaja central"],
         ["Límite", "Datos que cambian cada mes", "Miles de documentos no caben", "Depende de que la búsqueda acierte"]]
tb = s.shapes.add_table(len(filas), 4, Inches(0.3), Inches(1.5), Inches(9.4), Inches(4.2)).table
tb.columns[0].width = Inches(1.5)
for j in range(1, 4): tb.columns[j].width = Inches(2.6333)
for i, fila in enumerate(filas):
    for j, val in enumerate(fila):
        c = tb.cell(i, j); c.text = ""; p = c.text_frame.paragraphs[0]; r = p.add_run(); r.text = val
        r.font.name = UBUNTU; r.font.size = Pt(11); c.margin_left = c.margin_right = Inches(0.08)
        c.fill.solid()
        if i == 0: c.fill.fore_color.rgb = NAVY; r.font.color.rgb = WHITE; r.font.bold = True
        elif j == 0: c.fill.fore_color.rgb = SOFT_BLUE; r.font.bold = True; r.font.color.rgb = NAVY
        elif j == 3: c.fill.fore_color.rgb = SOFT_GREEN; r.font.color.rgb = BLACK
        else: c.fill.fore_color.rgb = WHITE if i % 2 else LIGHT_BLUE; r.font.color.rgb = BLACK
        c.vertical_anchor = MSO_ANCHOR.MIDDLE
add_card(s, Inches(0.3), Inches(5.9), Inches(9.4), Inches(1.1), fill=HIGHLIGHT_GREEN, title_color=DARK_GREEN, title="Con 71 mañaneras el contexto largo ya no alcanza",
         body="Son 6 millones de caracteres, alrededor de 1.5 millones de tokens. Ni siquiera caben completas en los modelos comerciales, y aunque cupieran, el modelo se distrae con el ruido.", body_size=11)
add_footer(s, 6, "Elaboración propia a partir de Lewis et al. (2020).")

# ---------------------------------------------------------------- 7 RAG
s = nueva("RAG resuelve el problema con una regla simple: buscar primero, redactar después")
add_pic(s, "fig07_flujo_rag", Inches(0.5), Inches(1.4), width=Inches(9.0))
add_card(s, Inches(0.3), Inches(5.15), Inches(4.65), Inches(1.85), title="RAG: generación aumentada por recuperación",
         body="Antes de responder, el sistema busca en una colección de documentos los fragmentos relevantes y se los entrega al modelo como contexto. El modelo responde a partir de ese material, no de su memoria. El término lo acuñaron Lewis et al. (2020).", body_size=11)
add_card(s, Inches(5.05), Inches(5.15), Inches(4.65), Inches(1.85), title="Dos modelos, dos trabajos",
         body="Uno busca (el modelo de embeddings) y otro redacta (el generador). Se cambian por separado: el corpus y el índice no se tocan al cambiar de generador. Y como el material viene con fecha, la respuesta puede citar de dónde salió cada dato.", body_size=11)
add_footer(s, 7, "Fuente: Lewis et al. (2020).")

# ---------------------------------------------------------------- 8 Corpus
s = nueva("El corpus son 71 mañaneras en texto plano, con fecha y fuente, descargadas con R")
add_pic(s, "fig08_corpus", Inches(0.3), Inches(1.35), height=Inches(3.5))
tres_cards(s, Inches(5.05), Inches(1.95), [
    (LIGHT_BLUE, NAVY, "Corpus", "El conjunto de documentos sobre los que el sistema responde: las versiones estenográficas del 1 de junio al 8 de septiembre de 2026, publicadas en gob.mx."),
    (LIGHT_BLUE, NAVY, "Ingesta", "Se descargó con un navegador controlado desde R (chromote), porque el sitio bloquea las descargas automáticas comunes, y el texto se extrajo con rvest."),
    (LIGHT_BLUE, NAVY, "Metadatos", "Cada archivo conserva título, fecha y URL, y un párrafo por turno de palabra con el orador en mayúsculas. Son lo que permite filtrar y citar.")], body_size=10.5)
add_footer(s, 8, "Fuente: Presidencia de la República, versiones estenográficas (gob.mx). Cálculos propios.")
notas(s, "Mostrar en pantalla las primeras líneas de un archivo real. La calidad de las respuestas está acotada por la calidad del corpus.")

# ---------------------------------------------------------------- 9 Fragmentación
s = nueva("Una mañanera no cabe en el modelo ni conviene que quepa: se parte en fragmentos")
add_pic(s, "fig09_fragmentacion", Inches(0.5), Inches(1.4), width=Inches(9.0))
tres_cards(s, Inches(4.3), Inches(2.7), [
    (LIGHT_BLUE, NAVY, "Por qué fragmentar", "El modelo de embeddings tiene un límite de entrada. Un vector resume todo el texto que recibe: si habla de diez temas, no se parece a ninguna pregunta. Y el generador solo puede leer unos pocos fragmentos a la vez."),
    (LIGHT_BLUE, NAVY, "Tamaño y traslape", "Tamaño objetivo de 1,600 caracteres (unos 400 tokens) en el programa. Traslape de 25 %: cada fragmento repite el último cuarto del anterior para que ninguna idea quede partida en la frontera."),
    (LIGHT_BLUE, NAVY, "Dónde cortar", "ragnar mueve cada corte al límite de párrafo más cercano. Como cada párrafo es un turno de palabra, los fragmentos rara vez separan al orador de lo que dijo.")], body_size=11.5)
add_footer(s, 9, "Fuente: mañanera del 14 de julio de 2026; ragnar 0.3.0 con tamaño objetivo 500 y traslape 25 % (escala reducida para la figura).")

# ---------------------------------------------------------------- 10 Tamaños
s = nueva("Con 1,600 caracteres y 25 % de traslape, 26 mañaneras se convierten en 1,824 fragmentos")
add_pic(s, "fig10_tamanos", Inches(0.3), Inches(1.5), height=Inches(3.0))
for k, (t, b, fill, tc) in enumerate([
    ("Chicos (800): 3,644 fragmentos", "Vectores más precisos, pero una cifra puede quedar separada de la oración que la explica. El doble de fragmentos que embeber.", SOFT_RED, DARK_RED),
    ("Medianos (1,600): 1,824", "El punto de partida del script: unos 70 por mañanera. Cabe un turno de palabra completo.", SOFT_GREEN, DARK_GREEN),
    ("Grandes (3,200): 915", "Conservan el argumento entero, pero diluyen el significado y llenan la ventana del generador con dos o tres.", SOFT_RED, DARK_RED)]):
    add_card(s, Inches(5.5), Inches(1.5 + k * 1.85), Inches(4.2), Inches(1.7), fill=fill, title_color=tc, title=t, body=b, body_size=10.5)
add_text(s, "Es el primer parámetro que se ajusta en cualquier proyecto de RAG. No hay un valor correcto universal: depende de cómo están escritos los documentos.", Inches(0.3), Inches(5.4), Inches(5.0), Inches(1.4), size=11, italic=True, color=GRAY, line_spacing=1.3)
add_footer(s, 10, "Fuente: cálculos propios con ragnar 0.3.0 sobre 26 mañaneras (3 de agosto a 8 de septiembre de 2026).")

# ---------------------------------------------------------------- 11 Embedding
s = nueva("Un modelo de embeddings convierte cada fragmento en 1,024 números que guardan su significado, no sus palabras")
add_pic(s, "fig11_vectores", Inches(0.5), Inches(1.4), width=Inches(9.0))
add_card(s, Inches(0.3), Inches(4.7), Inches(4.65), Inches(2.3), title="Embedding y modelo de embeddings",
         body="Un embedding es la representación de un texto como un vector de números: textos con significado parecido quedan en puntos cercanos, aunque usen palabras distintas. El modelo que lo produce (bge-m3, multilingüe, 1,024 dimensiones) es distinto del que redacta: es pequeño, rápido y no genera texto. Tarda 0.1 segundos por fragmento en una computadora portátil.", body_size=10.5)
add_card(s, Inches(5.05), Inches(4.7), Inches(4.65), Inches(2.3), fill=SOFT_RED, title_color=DARK_RED, title="La regla que no se puede romper",
         body="Ningún número del vector significa algo por sí solo: importa la posición del vector completo respecto a los demás. Por eso el modelo que embebe el corpus debe ser el mismo que embebe las preguntas. Vectores de dos modelos distintos viven en espacios distintos y no se pueden comparar.", body_size=10.5)
add_footer(s, 11, "Fuente: mañanera del 14 de julio de 2026; embeddings con bge-m3 (BAAI) vía Ollama.")

# ---------------------------------------------------------------- 12 Similitud coseno
s = nueva("La pregunta se convierte al mismo espacio y se mide qué fragmento le queda más cerca")
add_card(s, Inches(0.3), Inches(1.4), Inches(4.4), Inches(1.9), title="Similitud y distancia coseno",
         body="La similitud coseno es el coseno del ángulo entre dos vectores: 1 si apuntan en la misma dirección, 0 si no tienen relación. La distancia es 1 menos la similitud. Buscar \"por significado\" es calcular esa distancia entre la pregunta y cada fragmento y quedarse con los menores.", body_size=10.5)
filas = [["Pregunta", "Fragmento 1\n(trae el 48 %)", "Fragmento 2\n(la coda)"],
         ["¿Cuánto bajó el homicidio doloso?", "0.310", "0.431"],
         ["¿Cuál es la meta de viviendas en Tlaxcala?", "0.646", "0.605"]]
tb = s.shapes.add_table(3, 3, Inches(4.9), Inches(1.4), Inches(4.8), Inches(1.9)).table
tb.columns[0].width = Inches(2.6); tb.columns[1].width = Inches(1.1); tb.columns[2].width = Inches(1.1)
for i, fila in enumerate(filas):
    for j, val in enumerate(fila):
        c = tb.cell(i, j); c.text = ""; r = c.text_frame.paragraphs[0].add_run(); r.text = val; r.font.name = UBUNTU; r.font.size = Pt(10)
        c.fill.solid(); c.vertical_anchor = MSO_ANCHOR.MIDDLE; c.margin_left = c.margin_right = Inches(0.06)
        if i == 0: c.fill.fore_color.rgb = NAVY; r.font.color.rgb = WHITE; r.font.bold = True
        else:
            c.fill.fore_color.rgb = LIGHT_BLUE if i == 1 else WHITE; r.font.color.rgb = BLACK
            if (i, j) in [(1, 1), (2, 2)]: r.font.bold = True; r.font.color.rgb = DARK_GREEN
        if j > 0: c.text_frame.paragraphs[0].alignment = PP_ALIGN.CENTER
add_pic(s, "fig12_proyeccion", Inches(1.35), Inches(3.45), height=Inches(3.6))
add_footer(s, 12, "Fuente: cálculos propios con bge-m3. Proyección por componentes principales de los 1,824 fragmentos; tema asignado por palabras clave.")
notas(s, "La tabla: el fragmento con la cifra queda más cerca de la pregunta de homicidios (0.310) que de la de vivienda (0.646). La proyección pierde casi toda la información (dos componentes explican 11 % de la varianza) pero muestra que los temas se agrupan.")

# ---------------------------------------------------------------- 13 Almacén
s = nueva("Los fragmentos, sus metadatos y sus vectores viven en un solo archivo DuckDB con un índice para buscar rápido")
add_pic(s, "fig13_almacen", Inches(0.3), Inches(1.45), width=Inches(9.4))
tres_cards(s, Inches(3.9), Inches(3.05), [
    (LIGHT_BLUE, NAVY, "Base de datos vectorial", "Guarda fragmentos junto con sus embeddings y responde consultas de \"vecinos más cercanos\". Aquí es DuckDB, una base analítica embebida en un archivo de 37 MB."),
    (LIGHT_BLUE, NAVY, "Qué tiene cada fila", "Texto del fragmento, documento de origen, posiciones inicial y final, fecha, título, URL y el vector de 1,024 números."),
    (LIGHT_BLUE, NAVY, "Índice", "Acelera la búsqueda: en vez de comparar la pregunta con los 1,824 vectores uno por uno, aproxima el resultado en una fracción del tiempo. Se reconstruye al agregar documentos. Construirlo tardó 2.6 minutos, una sola vez.")], body_size=12)
add_footer(s, 13, "Fuente: estructura del almacén creado con ragnar 0.3.0 (mananeras_ago_sep.ragnar.duckdb).")

# ---------------------------------------------------------------- 14 Tres búsquedas
s = nueva("La búsqueda semántica encuentra sinónimos, la léxica encuentra nombres y cifras, y la híbrida se queda con lo mejor de ambas")
add_pic(s, "fig14_metodos", Inches(0.3), Inches(1.35), width=Inches(9.4))
tres_cards(s, Inches(4.55), Inches(2.4), [
    (LIGHT_BLUE, NAVY, "Semántica (VSS)", "Compara embeddings. Encuentra \"reducción de homicidios\" cuando se pregunta por \"baja en la violencia\"."),
    (LIGHT_BLUE, NAVY, "Léxica (BM25)", "Compara palabras, ponderadas por qué tan raras son en el corpus. Gana con términos exactos: \"Kanasín\", \"Hemosa Ingeniería\", \"40.8\". En mañaneras pesa mucho."),
    (SOFT_GREEN, DARK_GREEN, "Híbrida, con top-k = 5", "Ejecuta las dos y fusiona las listas; es la opción por defecto de ragnar. top-k es cuántos fragmentos se recuperan (5 aquí). Cuando dos vecinos del mismo documento se traslapan, ragnar los une: por eso la lista híbrida muestra 3.")], body_size=11.5)
add_footer(s, 14, "Fuente: 02_rag_mananeras.R, paso 4; Robertson y Zaragoza (2009) para BM25.")
notas(s, "Demostración en vivo 1: correr el paso 4 con una pregunta que proponga el grupo. Es rápido y no necesita el generador.")

# ---------------------------------------------------------------- 15 Filtro por fecha
s = nueva("La fecha permite acotar la búsqueda antes de buscar: qué dijo sobre aranceles la primera semana de septiembre")
add_pic(s, "fig15_filtro", Inches(0.3), Inches(1.35), width=Inches(9.4))
add_card(s, Inches(0.3), Inches(4.75), Inches(4.65), Inches(2.2), title="Filtro por metadatos",
         body="Los metadatos guardados con cada fragmento se usan como filtro previo: primero se descartan los fragmentos fuera del periodo y luego se ordena por cercanía. Sin filtro, la misma consulta trae fechas de todo el corpus.", body_size=12.5)
add_card(s, Inches(5.05), Inches(4.75), Inches(4.65), Inches(2.2), fill=HIGHLIGHT_GREEN, title_color=DARK_GREEN, title="Lo nuevo frente a un corpus de PDFs sueltos",
         body="En un corpus fechado, buena parte de las preguntas reales traen un periodo: \"en julio\", \"después del informe\", \"esta semana\". Acotar antes de buscar funciona mejor que dejar que la similitud adivine el periodo.", body_size=12.5)
add_footer(s, 15, "Fuente: 02_rag_mananeras.R, paso 4d.")

# ---------------------------------------------------------------- 16 Prompt aumentado
s = nueva("\"Aumentar\" el prompt significa literalmente pegarle los cinco fragmentos antes de la pregunta")
add_rect(s, Inches(0.3), Inches(1.4), Inches(5.6), Inches(1.45), NAVY)
add_text(s, "Instrucción de sistema", Inches(0.45), Inches(1.45), Inches(5.3), Inches(0.3), size=10, bold=True, color=WHITE)
add_text(s, "Eres un asistente que responde preguntas sobre las conferencias de prensa matutinas de la presidenta de México. Responde SOLO con la información de los fragmentos que se te entregan y menciona la fecha de la mañanera de donde sale cada dato. Si la información no está en los fragmentos, di explícitamente que no aparece en las mañaneras consultadas. Responde en español, en máximo cinco oraciones.",
         Inches(0.45), Inches(1.72), Inches(5.3), Inches(1.0), size=9.5, color=WHITE, line_spacing=1.15)
add_rect(s, Inches(0.3), Inches(2.95), Inches(5.6), Inches(2.95), GRAY_TOP)
add_text(s, "### Fragmentos recuperados  (7,354 caracteres en total)", Inches(0.45), Inches(3.0), Inches(5.3), Inches(0.3), size=10, bold=True, color=NAVY)
frag_txt = ""
for r in D["metodos"]["hibrida"]:
    frag_txt += f"[Mañanera del {r['fecha'][8:10]}/{r['fecha'][5:7]}/{r['fecha'][:4]}]\n{r['inicio']}…\n\n"
add_text(s, frag_txt.strip(), Inches(0.45), Inches(3.3), Inches(5.3), Inches(2.55), size=10, color=BLACK, line_spacing=1.2)
add_rect(s, Inches(0.3), Inches(6.0), Inches(5.6), Inches(1.0), SOFT_GREEN)
add_text(s, "### Pregunta", Inches(0.45), Inches(6.05), Inches(5.3), Inches(0.3), size=10, bold=True, color=DARK_GREEN)
add_text(s, "¿Cuál fue el promedio diario de homicidios dolosos en agosto de 2026?", Inches(0.45), Inches(6.35), Inches(5.3), Inches(0.5), size=10, color=BLACK)
add_card(s, Inches(6.1), Inches(1.4), Inches(3.6), Inches(2.6), title="Prompt aumentado",
         body="Es el mensaje final que recibe el generador: instrucciones, fragmentos recuperados (cada uno con su fecha) y la pregunta. En el ejemplo mide 7,354 caracteres, unos 1,800 tokens: cabe de sobra en la ventana de 8,192.", body_size=12)
add_card(s, Inches(6.1), Inches(4.15), Inches(3.6), Inches(2.85), fill=SOFT_RED, title_color=DARK_RED, title="Instrucción de sistema",
         body="El texto fijo que establece las reglas: responder solo con el contexto, citar la fecha y decir \"no aparece\" cuando no esté. Es la primera defensa contra la alucinación, pero no es una garantía: un modelo pequeño la desobedece a veces.", body_size=12)
add_footer(s, 16, "Fuente: 02_rag_mananeras.R, paso 5a. Los fragmentos aparecen truncados; en el prompt real van completos.")

# ---------------------------------------------------------------- 17 Respuesta
s = nueva("El generador redacta a partir de los fragmentos y cita la mañanera de donde salió cada dato")
add_card(s, Inches(0.3), Inches(1.4), Inches(5.9), Inches(3.6), fill=SOFT_GREEN, title_color=DARK_GREEN, title="Respuesta real de qwen3.5:4b, 13 segundos",
         body="“" + RESP_MANUAL + "”", body_size=10.5, line_spacing=1.3)
add_card(s, Inches(6.4), Inches(1.4), Inches(3.3), Inches(1.7), title="Modelo generador",
         body="El LLM que escribe la respuesta. Aquí corre en la computadora; puede cambiarse por Claude o GPT sin tocar el almacén.", body_size=11.5)
add_card(s, Inches(6.4), Inches(3.3), Inches(3.3), Inches(1.7), title="Atribución",
         body="Cada afirmación se puede rastrear a un fragmento con fecha y verificar. Es la ventaja central de RAG sobre un modelo sin fuentes.", body_size=11.5)
add_card(s, Inches(0.3), Inches(5.2), Inches(9.4), Inches(1.8), fill=HIGHLIGHT_GREEN, title_color=DARK_GREEN, title="Qué verificar en la respuesta",
         body="Las dos fechas citadas (8 y 4 de septiembre) corresponden a fragmentos que sí estaban en el prompt, y las cifras (40.8 y 0.17) aparecen textualmente en ellos. Lo que sí agregó el modelo por su cuenta es la frase \"en los últimos 12 años\", que no está en los fragmentos: incluso con la fuente enfrente conviene leer con lápiz.", body_size=12)
add_footer(s, 17, "Fuente: 02_rag_mananeras.R, paso 5a; generador qwen3.5:4b vía Ollama.")
notas(s, "Demostración en vivo 2: correr el paso 5a. Mientras responde, explicar que el modelo está leyendo 7,000 caracteres y escribiendo palabra por palabra.")

# ---------------------------------------------------------------- 18 Herramienta
s = nueva("En la variante con herramienta, el modelo decide cuándo buscar y con qué palabras")
add_pic(s, "fig18_herramienta", Inches(0.5), Inches(1.35), width=Inches(9.0))
add_card(s, Inches(0.3), Inches(4.85), Inches(4.65), Inches(2.15), title="Herramienta y llamada a herramientas",
         body="Una herramienta es una función que el modelo puede invocar. La búsqueda se registra como herramienta y el modelo la llama con la consulta que él mismo formula, a veces varias veces. Sirve para preguntas compuestas y conversaciones largas. Con modelos pequeños la herramienta devuelve texto plano y solo tres fragmentos, porque las salidas largas los confunden.", body_size=10.5)
add_card(s, Inches(5.05), Inches(4.85), Inches(4.65), Inches(2.15), fill=SOFT_GREEN, title_color=DARK_GREEN, title="Respuesta real por herramienta",
         body="“" + RESP_HERR + "”", body_size=10, line_spacing=1.2)
add_footer(s, 18, "Fuente: 02_rag_mananeras.R, paso 5b.")

# ---------------------------------------------------------------- 19 Control
s = nueva("Ante una pregunta sin respuesta en el corpus el sistema debe abstenerse, y el modelo pequeño lo logró al segundo intento")
add_rect(s, Inches(0.3), Inches(1.45), Inches(9.4), Inches(0.6), NAVY)
add_text(s, "¿Qué dijo la presidenta sobre el resultado del Mundial de 2030?  (no hay nada en las mañaneras)", Inches(0.45), Inches(1.45), Inches(9.1), Inches(0.6), size=13, bold=True, color=WHITE, anchor=MSO_ANCHOR.MIDDLE, align=PP_ALIGN.CENTER)
add_card(s, Inches(0.3), Inches(2.2), Inches(4.65), Inches(2.75), fill=SOFT_RED, title_color=DARK_RED, title="Intento 1: el modelo divaga",
         body="“" + RESP_CTRL1 + "”", body_size=11, line_spacing=1.25)
add_card(s, Inches(5.05), Inches(2.2), Inches(4.65), Inches(2.75), fill=SOFT_GREEN, title_color=DARK_GREEN, title="Intento 2: el modelo se abstiene",
         body="“" + RESP_CTRL2 + "”", body_size=11, line_spacing=1.25)
add_card(s, Inches(0.3), Inches(5.1), Inches(9.4), Inches(1.85), fill=HIGHLIGHT_GREEN, title_color=DARK_GREEN, title="Lección",
         body="La recuperación fue correcta las dos veces: no había nada relevante que traer. La generación es la que falla. Un sistema de RAG hereda los errores de sus dos modelos, y con un generador más grande el primer intento no habría ocurrido. Aun así, la instrucción de sistema no garantiza nada: hay que evaluar.", body_size=12)
add_footer(s, 19, "Fuente: 02_rag_mananeras.R, paso 5b; generador qwen3.5:4b. Respuestas textuales.")

# ---------------------------------------------------------------- 20 Evaluación
s = nueva("Con ocho preguntas de respuesta conocida, los tres métodos recuperaron la mañanera correcta el 100 % de las veces")
add_pic(s, "fig20_evaluacion", Inches(0.3), Inches(1.35), width=Inches(9.4))
tres_cards(s, Inches(4.85), Inches(2.1), [
    (LIGHT_BLUE, NAVY, "Conjunto de prueba", "Preguntas con respuesta y fragmento esperado, escritas a mano por quien conoce el corpus. Sin él no se sabe si un cambio mejoró o empeoró el sistema."),
    (LIGHT_BLUE, NAVY, "hit@k", "Proporción de preguntas para las que el documento correcto aparece entre los k primeros recuperados. La métrica más simple y la primera que se calcula."),
    (SOFT_RED, DARK_RED, "Lo que hit@5 no mide", "Fidelidad: si la respuesta se sostiene solo en los fragmentos. Completitud: si cubre todo lo preguntado. La diapositiva anterior es un fallo de fidelidad con recuperación perfecta.")], body_size=11)
add_footer(s, 20, "Fuente: 02_rag_mananeras.R, paso 6; 26 mañaneras, top-k = 5.")
notas(s, "Ser honesto: 100 % significa que las preguntas fueron fáciles (datos únicos, con nombres propios). Proponer como ejercicio escribir preguntas más ambiguas y ver dónde cae.")

# ---------------------------------------------------------------- 21 Decisiones
s = nueva("Cada parámetro del flujo es una decisión con costo: tamaño de fragmento, top-k, modelo y equipo")
cards = [("Tamaño de fragmento y traslape", "Afectan precisión y volumen. Se ajustan con el conjunto de prueba, no por intuición.", LIGHT_BLUE, NAVY),
         ("top-k", "Más fragmentos, más cobertura y más ruido. También más tokens y más tiempo de respuesta.", LIGHT_BLUE, NAVY),
         ("Modelos y equipo", "Embeddings locales (bge-m3, 0.1 s por fragmento) y generador local (qwen3.5:4b, 12 s por respuesta) corren en una computadora portátil de 16 GB. Un generador remoto responde en 2 s, pero requiere llave y envía el texto fuera.", SOFT_GREEN, DARK_GREEN),
         ("Corpus", "RAG no arregla un corpus malo: si la transcripción tiene errores o le faltan días, las respuestas los heredan.", SOFT_RED, DARK_RED)]
for (x, y), (t, b, f, tc) in zip([(0.3, 1.5), (5.05, 1.5), (0.3, 4.2), (5.05, 4.2)], cards):
    add_card(s, Inches(x), Inches(y), Inches(4.65), Inches(2.55), fill=f, title_color=tc, title=t, body=b, title_size=17, body_size=14, line_spacing=1.4)
add_footer(s, 21, "Fuente: mediciones propias en una Mac de 16 GB, 8 de septiembre de 2026.")

# ---------------------------------------------------------------- 22 Conceptos clave
s = nueva("Los términos de la sesión, en el orden en que aparecen en el flujo de trabajo")
add_card(s, Inches(0.3), Inches(1.5), Inches(4.65), Inches(5.4), title="El problema y el corpus", body=
    "Modelo de lenguaje grande\nToken\nVentana de contexto\nFecha de corte del conocimiento\nAlucinación\nRAG (generación aumentada por recuperación)\nCorpus\nIngesta\nMetadatos\nFragmentación, tamaño y traslape", title_size=16, body_size=15, line_spacing=1.6)
add_card(s, Inches(5.05), Inches(1.5), Inches(4.65), Inches(5.4), title="Búsqueda, generación y evaluación", body=
    "Embedding y modelo de embeddings\nSimilitud coseno\nBase de datos vectorial e índice\nBúsqueda semántica, léxica e híbrida\ntop-k y filtro por metadatos\nPrompt aumentado e instrucción de sistema\nHerramienta\nModelo generador y atribución\nConjunto de prueba y hit@k\nFidelidad y completitud", title_size=16, body_size=15, line_spacing=1.6)
add_footer(s, 22, "Definiciones completas y referencias en glosario_rag.md.")

# ---------------------------------------------------------------- 23 Recursos
s = nueva("Todo el material corre en R con tres herramientas de código abierto y sin llaves de API")
tres_cards(s, Inches(1.5), Inches(2.6), [
    (LIGHT_BLUE, NAVY, "Ollama", "Ejecuta modelos de lenguaje y de embeddings en la computadora local, sin enviar datos a ningún servidor.\n\nollama pull bge-m3\nollama pull qwen3.5:4b"),
    (LIGHT_BLUE, NAVY, "ragnar", "Paquete de R de Posit con el flujo completo de RAG: lectura, fragmentación, embeddings, almacén DuckDB y búsqueda híbrida (Kalinowski y Falbel, 2026)."),
    (LIGHT_BLUE, NAVY, "ellmer", "Paquete de R de Posit para conversar con modelos de cualquier proveedor y registrar herramientas.")], body_size=12.5)
add_card(s, Inches(0.3), Inches(4.3), Inches(4.65), Inches(2.6), fill=SOFT_GREEN, title_color=DARK_GREEN, title="Programas de la sesión",
         body="01_scraper_mananeras.R: descarga el corpus desde gob.mx.\n02_rag_mananeras.R: el flujo completo, con las dos demostraciones.\nglosario_rag.md: definiciones y referencias.", body_size=12.5, line_spacing=1.4)
add_card(s, Inches(5.05), Inches(4.3), Inches(4.65), Inches(2.6), title="Lecturas",
         body="Lewis et al. (2020). Retrieval-augmented generation for knowledge-intensive NLP tasks. NeurIPS 33.\nRobertson y Zaragoza (2009). The probabilistic relevance framework: BM25 and beyond.\nKalinowski y Falbel (2026). ragnar 0.3.0, CRAN.", body_size=12, line_spacing=1.4)
add_footer(s, 23)

# ---------------------------------------------------------------- 24 Conclusiones
s = nueva("Cinco ideas para llevarse")
add_rect(s, Inches(0.3), Inches(1.5), Inches(9.4), Inches(5.4), HIGHLIGHT_GREEN)
ideas = ["Un modelo de lenguaje redacta bien pero no consulta nada: lo que no estaba en su entrenamiento lo inventa.",
         "RAG cambia la regla: buscar primero, redactar después, y citar de dónde salió cada dato.",
         "Intervienen dos modelos distintos: el de embeddings busca por significado; el generador redacta. Se cambian por separado.",
         "La calidad depende de decisiones concretas: cómo se fragmenta, cuántos fragmentos se recuperan y qué tan bueno es el corpus.",
         "Nada de esto se sabe sin evaluar: un conjunto de prueba escrito a mano vale más que cualquier intuición."]
for k, idea in enumerate(ideas):
    y = Inches(1.7 + k * 1.02)
    add_text(s, str(k + 1), Inches(0.55), y, Inches(0.6), Inches(0.9), size=32, bold=True, color=DARK_GREEN)
    add_text(s, idea, Inches(1.25), y, Inches(8.2), Inches(0.9), size=15, color=BLACK, line_spacing=1.3, anchor=MSO_ANCHOR.MIDDLE)
add_footer(s, 24)

# ---------------------------------------------------------------- 25 Cierre
s = nueva()
add_rect(s, 0, 0, SW, Inches(1.1), GRAY_TOP)
add_text(s, "Tecnológico de Monterrey", Inches(0.4), Inches(0.25), Inches(6), Inches(0.6), size=20, color=NAVY, bold=True, anchor=MSO_ANCHOR.MIDDLE)
add_rect(s, 0, Inches(1.1), SW, Inches(3.5), SOFT_BLUE)
add_text(s, "Gracias", Inches(0.6), Inches(1.7), Inches(8.8), Inches(2), size=80, color=NAVY, bold=True, align=PP_ALIGN.CENTER)
add_rect(s, Inches(3.0), Inches(5.2), Inches(4.0), Inches(1.0), NAVY)
add_text(s, "¿Preguntas?", Inches(3.0), Inches(5.2), Inches(4.0), Inches(1.0), size=28, color=WHITE, bold=True, align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
add_text(s, "[PENDIENTE: correo o contacto del expositor]", Inches(0.6), Inches(6.5), Inches(8.8), Inches(0.4), size=12, color=GRAY, align=PP_ALIGN.CENTER)

prs.save(OUT); print("guardado", OUT, len(prs.slides), "diapositivas")
