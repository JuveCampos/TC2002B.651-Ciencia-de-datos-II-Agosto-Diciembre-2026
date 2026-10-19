"""Presentación alterna de la Clase 14 (estilo Tec, 4:3).

Uso:  python3 deck.py <carpeta_resultados> <excel_etiquetado> <carpeta_img> <salida.pptx>
Los números de los títulos y cuerpos se leen de los CSV que exporta
02_modelo_tidymodels.R, para que el deck se regenere con los datos finales.
"""
import sys
import csv
from collections import Counter
import openpyxl
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.oxml.ns import qn

RES, XLSX, IMG, OUT = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

# === Paleta Tec ===
NAVY = RGBColor(0x1E, 0x4C, 0x7D)
LIGHT_BLUE = RGBColor(0xEA, 0xF2, 0xFA)
SOFT_BLUE = RGBColor(0xDD, 0xE5, 0xED)
SOFT_GREEN = RGBColor(0xD5, 0xF5, 0xE3)
DARK_GREEN = RGBColor(0x1A, 0x7A, 0x3A)
SOFT_RED = RGBColor(0xFA, 0xDB, 0xD8)
DARK_RED = RGBColor(0xC0, 0x39, 0x2B)
HIGHLIGHT_GREEN = RGBColor(0xF0, 0xFA, 0xF0)
GRAY_TOP = RGBColor(0xF0, 0xF0, 0xF0)
GRAY = RGBColor(0x55, 0x55, 0x55)
GRAY_SRC = RGBColor(0x66, 0x66, 0x66)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
BLACK = RGBColor(0x00, 0x00, 0x00)
CODE_BG = RGBColor(0x1B, 0x2A, 0x3A)
UBUNTU = 'Ubuntu'
MONO = 'Menlo'

prs = Presentation()
prs.slide_width = Inches(10)
prs.slide_height = Inches(7.5)
SW, SH = prs.slide_width, prs.slide_height
BLANK = prs.slide_layouts[6]
TITULO_CORTO = "Clase 14 · Modelos de clasificación"
FUENTE_DATOS = ("Fuente: comentarios de YouTube a videos de El Heraldo de México, "
                "SinEmbargo, Revista Etcétera y La Jornada de Oriente (sep.-oct. 2026). "
                "Etiquetado con Claude (Fable 5.1). Cálculos propios.")


# ============ DATOS PARA LOS TÍTULOS ============
def leer_csv(nombre):
    with open(f"{RES}/{nombre}", encoding="utf-8") as f:
        return list(csv.DictReader(f))


resumen = leer_csv("resumen.csv")[0]
metricas = leer_csv("metricas.csv")
balance = leer_csv("balance_clases.csv")
errores = leer_csv("errores_bosque.csv")
importancia = leer_csv("importancia_bosque.csv")

wb = openpyxl.load_workbook(XLSX, read_only=True)
filas = list(wb.active.iter_rows(values_only=True))
cab = filas[0]
it, ie = cab.index("canal"), cab.index("etiqueta_final")
por_tema = Counter((r[it], r[ie]) for r in filas[1:] if r[ie] is not None)
N_TOTAL = sum(por_tema.values())
TEMAS = sorted({t for t, _ in por_tema})
PCT_TEMA = {t: round(100 * por_tema.get((t, "Ofensivo"), 0) /
                     (por_tema.get((t, "Ofensivo"), 0) +
                      por_tema.get((t, "No ofensivo"), 0))) for t in TEMAS}
TEMA_MAX = max(TEMAS, key=lambda t: PCT_TEMA[t])
TEMA_MIN = min(TEMAS, key=lambda t: PCT_TEMA[t])
N_OF = int(next(b["n"] for b in balance if b["etiqueta"] == "Ofensivo"))
N_NO = int(next(b["n"] for b in balance if b["etiqueta"] == "No ofensivo"))
PCT_OF = round(100 * N_OF / (N_OF + N_NO))
N_ENT, N_PRU = int(resumen["n_entrenamiento"]), int(resumen["n_prueba"])
PCT_MAYOR = round(100 * float(resumen["exactitud_mayoritaria"]))
VOCAB, TERMINOS = int(resumen["vocabulario_total"]), int(resumen["terminos_receta"])


def metrica(modelo, nombre):
    return round(100 * float(next(m["valor"] for m in metricas
                                  if m["modelo"] == modelo
                                  and m["metrica"] == nombre)))


RF = {k: metrica("Bosque aleatorio", k)
      for k in ["accuracy", "precision", "recall", "f_meas", "roc_auc"]}
LG = {k: metrica("Regresión logística", k)
      for k in ["accuracy", "precision", "recall", "f_meas", "roc_auc"]}
MEJOR = "Bosque aleatorio" if RF["f_meas"] >= LG["f_meas"] else "Regresión logística"
TOP_PALABRAS = ", ".join(r["palabra"] for r in importancia[:6])


# ============ HELPERS ============
def quitar_sombra(shape):
    el = shape._element.find(qn("p:style"))
    if el is not None:
        shape._element.remove(el)


def add_text(slide, text, left, top, width, height, *, size=14, bold=False,
             color=BLACK, align=PP_ALIGN.LEFT, italic=False,
             line_spacing=None, font=UBUNTU, anchor=None):
    box = slide.shapes.add_textbox(left, top, width, height)
    tf = box.text_frame
    tf.word_wrap = True
    for m in ("margin_left", "margin_right", "margin_top", "margin_bottom"):
        setattr(tf, m, Emu(0))
    if anchor is not None:
        tf.vertical_anchor = anchor
    for i, line in enumerate(text.split("\n")):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = align
        if line_spacing is not None:
            p.line_spacing = line_spacing
        run = p.add_run()
        run.text = line
        run.font.size = Pt(size)
        run.font.bold = bold
        run.font.italic = italic
        run.font.color.rgb = color
        run.font.name = font
    return box


def add_rect(slide, left, top, width, height, fill_color):
    shape = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, left, top, width,
                                   height)
    shape.fill.solid()
    shape.fill.fore_color.rgb = fill_color
    shape.line.fill.background()
    quitar_sombra(shape)
    return shape


def add_header(slide, title):
    """Banda navy con el action title. Ancho completo para títulos-oración."""
    size = 22 if len(title) <= 48 else (19 if len(title) <= 62 else 17)
    add_rect(slide, 0, Inches(0.3), Inches(9.4), Inches(0.7), NAVY)
    add_text(slide, title, Inches(0.3), Inches(0.3), Inches(8.9),
             Inches(0.7), size=size, bold=True, color=WHITE,
             anchor=MSO_ANCHOR.MIDDLE)


def add_card(slide, left, top, width, height, *, fill=LIGHT_BLUE, title=None,
             body=None, title_color=NAVY, body_color=BLACK, title_size=14,
             body_size=12, line_spacing=1.25):
    add_rect(slide, left, top, width, height, fill)
    if title and body:
        add_text(slide, title, left + Inches(0.12), top + Inches(0.08),
                 width - Inches(0.24), Inches(0.4), size=title_size,
                 bold=True, color=title_color)
        add_text(slide, body, left + Inches(0.12), top + Inches(0.45),
                 width - Inches(0.24), height - Inches(0.55),
                 size=body_size, color=body_color, line_spacing=line_spacing)
    elif title:
        add_text(slide, title, left + Inches(0.12), top + Inches(0.08),
                 width - Inches(0.24), height - Inches(0.16),
                 size=title_size, bold=True, color=title_color,
                 anchor=MSO_ANCHOR.MIDDLE, line_spacing=line_spacing)
    elif body:
        add_text(slide, body, left + Inches(0.12), top + Inches(0.1),
                 width - Inches(0.24), height - Inches(0.2),
                 size=body_size, color=body_color, line_spacing=line_spacing)


def add_code(slide, code, left, top, width, height, *, size=10.5):
    add_rect(slide, left, top, width, height, CODE_BG)
    add_text(slide, code, left + Inches(0.15), top + Inches(0.12),
             width - Inches(0.3), height - Inches(0.24), size=size,
             color=WHITE, font=MONO, line_spacing=1.15)


def add_formula_box(slide, formula, sub, left, top, width, height):
    add_rect(slide, left, top, width, height, NAVY)
    add_text(slide, formula, left, top + Inches(0.1), width, Inches(0.5),
             size=17, bold=True, color=WHITE, align=PP_ALIGN.CENTER,
             font=MONO)
    if sub:
        add_text(slide, sub, left + Inches(0.1), top + height - Inches(0.62),
                 width - Inches(0.2), Inches(0.58), size=10.5, color=WHITE,
                 align=PP_ALIGN.CENTER, italic=True, line_spacing=1.15)


def add_footer(slide, num):
    add_text(slide, f"{TITULO_CORTO} · {num}", Inches(6.4), Inches(7.18),
             Inches(3.4), Inches(0.22), size=9, color=GRAY,
             align=PP_ALIGN.RIGHT, italic=True)


def add_fuente(slide, texto=FUENTE_DATOS):
    add_text(slide, texto, Inches(0.3), Inches(6.78), Inches(9.4),
             Inches(0.38), size=9, color=GRAY_SRC, line_spacing=1.1)


def add_picture_fit(slide, path, left, top, max_w, max_h):
    """Inserta la imagen centrada dentro de la caja sin deformarla."""
    from PIL import Image
    w, h = Image.open(path).size
    escala = min(max_w / w, max_h / h)
    pw, ph = int(w * escala), int(h * escala)
    slide.shapes.add_picture(path, left + (max_w - pw) // 2,
                             top + (max_h - ph) // 2, pw, ph)


def add_tabla(slide, filas, left, top, width, height, *, col_widths=None,
              size=11, header_fill=NAVY, alt_fill=SOFT_BLUE):
    shape = slide.shapes.add_table(len(filas), len(filas[0]), left, top,
                                   width, height)
    tabla = shape.table
    tbl = shape._element.graphic.graphicData.tbl
    tbl_pr = tbl.tblPr
    # Quitar el estilo por defecto de PowerPoint
    style_id = tbl_pr.find(qn("a:tableStyleId"))
    if style_id is not None:
        tbl_pr.remove(style_id)
    if col_widths:
        for i, cw in enumerate(col_widths):
            tabla.columns[i].width = cw
    for r, fila in enumerate(filas):
        for c, valor in enumerate(fila):
            celda = tabla.cell(r, c)
            celda.fill.solid()
            if r == 0:
                celda.fill.fore_color.rgb = header_fill
            else:
                celda.fill.fore_color.rgb = alt_fill if r % 2 == 0 else WHITE
            for m in ("margin_left", "margin_right"):
                setattr(celda, m, Inches(0.08))
            celda.margin_top = Inches(0.04)
            celda.margin_bottom = Inches(0.04)
            tf = celda.text_frame
            tf.word_wrap = True
            p = tf.paragraphs[0]
            run = p.add_run()
            run.text = valor
            run.font.name = UBUNTU
            run.font.size = Pt(size)
            run.font.bold = (r == 0 or c == 0)
            run.font.color.rgb = WHITE if r == 0 else (NAVY if c == 0 else BLACK)
    return shape


def nueva(titulo, num):
    slide = prs.slides.add_slide(BLANK)
    add_header(slide, titulo)
    add_footer(slide, num)
    return slide


def slide_figura(titulo, num, imagen, mensaje, *, fuente=True,
                 img_h=4.85):
    slide = nueva(titulo, num)
    add_picture_fit(slide, f"{IMG}/{imagen}", Inches(0.3), Inches(1.15),
                    Inches(9.4), Inches(img_h))
    add_card(slide, Inches(0.3), Inches(1.15 + img_h + 0.1), Inches(9.4),
             Inches(0.62), fill=HIGHLIGHT_GREEN, title=mensaje,
             title_size=13)
    if fuente:
        add_fuente(slide)
    return slide


# ============ SLIDES ============
n = 1
# 1. Portada
slide = prs.slides.add_slide(BLANK)
add_rect(slide, 0, 0, SW, Inches(1.1), GRAY_TOP)
add_text(slide, "Tecnológico de Monterrey", Inches(0.4), Inches(0.25),
         Inches(5), Inches(0.6), size=20, color=NAVY, bold=True,
         anchor=MSO_ANCHOR.MIDDLE)
add_rect(slide, 0, Inches(1.1), SW, Inches(3.5), SOFT_BLUE)
add_text(slide, "14. Modelos de\nclasificación", Inches(0.6), Inches(1.5),
         Inches(8.8), Inches(2.3), size=54, color=NAVY, bold=True,
         line_spacing=1.0)
add_text(slide, "Ciencia de datos para la toma de decisiones II",
         Inches(0.6), Inches(3.9), Inches(8.8), Inches(0.6), size=18,
         color=NAVY, italic=True)
add_text(slide, "Jorge Juvenal Campos Ferreira\njuvenal.campos@tec.mx",
         Inches(0.6), Inches(5.3), Inches(8.8), Inches(0.9), size=14,
         color=BLACK, line_spacing=1.3)
add_rect(slide, Inches(0.6), Inches(6.5), Inches(2), Inches(0.05), NAVY)

# 2. Agenda
n += 1
slide = nueva("Hoy vamos del texto crudo a un modelo evaluado", n)
bloques = [
    ("1. Del texto a la matriz",
     "Matriz documento-término con cast_dtm() y con recetas de "
     "textrecipes. Por qué casi toda la matriz son ceros y cómo reducirla."),
    ("2. Etiquetas con un LLM",
     "Claude clasifica 1,547 comentarios reales con una rúbrica escrita de "
     "antemano. Por qué la etiqueta es el techo del modelo."),
    ("3. Modelos supervisados",
     "Partición entrenamiento/prueba, árboles de decisión, bosque aleatorio "
     "y regresión logística penalizada, todo con tidymodels."),
    ("4. Evaluación",
     "Matriz de confusión, exactitud, precisión, sensibilidad, F1 y curva "
     "ROC. Por qué la exactitud engaña y qué palabras usa el modelo."),
]
for (x, y), (t, b) in zip([(0.3, 1.2), (5.05, 1.2), (0.3, 4.0), (5.05, 4.0)],
                          bloques):
    add_card(slide, Inches(x), Inches(y), Inches(4.65), Inches(2.65),
             title=t, body=b, title_size=16, body_size=13, line_spacing=1.35)

# 3. DTM
n += 1
slide = nueva("La matriz documento-término convierte texto en números", n)
add_text(slide, "Cada fila es un documento (comentario, tweet, párrafo), cada "
         "columna es un término y cada celda guarda cuántas veces aparece "
         "el término en el documento, o su ponderación tf-idf.",
         Inches(0.3), Inches(1.15), Inches(9.4), Inches(0.75), size=13,
         line_spacing=1.25)
add_tabla(slide, [["Documento \\ Término", "impuesto", "pinche", "videojuego",
                   "gobierno", "morena"],
                  ["Comentario 1", "2", "0", "1", "1", "0"],
                  ["Comentario 2", "0", "1", "0", "1", "1"],
                  ["Comentario 3", "1", "0", "3", "0", "0"]],
          Inches(0.3), Inches(2.0), Inches(9.4), Inches(1.45),
          col_widths=[Inches(2.4), Inches(1.4), Inches(1.4), Inches(1.5),
                      Inches(1.4), Inches(1.3)], size=11)
add_code(slide, "matriz_dtm <- tokens %>%\n"
         "  count(id, palabra) %>%\n"
         "  cast_dtm(document = id,\n"
         "           term = palabra,\n"
         "           value = n,\n"
         "           weighting = tm::weightTfIdf)",
         Inches(0.3), Inches(3.65), Inches(4.65), Inches(1.75))
add_card(slide, Inches(5.05), Inches(3.65), Inches(4.65), Inches(1.75),
         title="tidytext::cast_dtm()",
         body="document: columna que identifica al documento.\n"
              "term: columna con las palabras o tokens.\n"
              "value: frecuencia o ponderación de la celda.\n"
              "weighting: tf (conteo) o tf-idf.",
         body_size=11.5)
add_card(slide, Inches(0.3), Inches(5.55), Inches(9.4), Inches(1.3),
         fill=HIGHLIGHT_GREEN,
         title="La matriz es el puente: el modelo no lee texto, lee esta tabla.",
         body="En tidymodels no se construye a mano: una receta de textrecipes "
              "la produce dentro del flujo con step_tokenize(), "
              "step_stopwords(), step_tokenfilter() y step_tfidf().",
         title_size=13, body_size=12)

# 4. Dispersión
n += 1
slide = nueva("Casi toda la matriz de texto son ceros", n)
add_card(slide, Inches(0.3), Inches(1.2), Inches(3.0), Inches(2.4),
         title=f"{VOCAB:,} palabras",
         body="distintas aparecen en los comentarios de entrenamiento "
              "después de quitar las palabras vacías (stop words).",
         title_size=22, body_size=12)
add_card(slide, Inches(3.5), Inches(1.2), Inches(3.0), Inches(2.4),
         title="~17 palabras",
         body="usa el comentario mediano. Cada fila tiene valores en "
              "menos del 1 % de sus columnas.",
         title_size=22, body_size=12)
add_card(slide, Inches(6.7), Inches(1.2), Inches(3.0), Inches(2.4),
         title=f"{TERMINOS} columnas",
         body="quedan tras exigir que la palabra aparezca al menos 3 veces "
              "y conservar las 500 más frecuentes.",
         title_size=22, body_size=12)
add_card(slide, Inches(0.3), Inches(3.8), Inches(4.65), Inches(2.3),
         title="Por qué importa",
         body="Guardar millones de ceros desperdicia memoria y tiempo de "
              "cómputo. Un bosque con 4,000 columnas y 1,000 filas tarda "
              "mucho más y no aprende mejor: las palabras que aparecen una "
              "vez no sirven para generalizar.",
         body_size=12)
add_card(slide, Inches(5.05), Inches(3.8), Inches(4.65), Inches(2.3),
         title="Cómo reducirla",
         body="tm::removeSparseTerms(dtm, 0.99) elimina los términos ausentes "
              "en más del 99 % de los documentos.\n"
              "textrecipes::step_tokenfilter(min_times, max_tokens) hace lo "
              "mismo dentro de la receta y solo con la base de entrenamiento.",
         body_size=12)
add_card(slide, Inches(0.3), Inches(6.25), Inches(9.4), Inches(0.6),
         fill=HIGHLIGHT_GREEN,
         title="Cuánto recortar depende del tamaño del corpus y de la "
               "computadora; es una decisión del analista, no una regla.",
         title_size=12.5)

# 5. Etiquetado con LLM
n += 1
slide = nueva("Un LLM etiqueta miles de comentarios en minutos", n)
add_card(slide, Inches(0.3), Inches(1.2), Inches(4.65), Inches(2.5),
         title="Etiquetado con LLM",
         body="Asignar etiquetas a textos con un modelo de lenguaje de gran "
              "escala. En lugar de reglas o de anotadores humanos, se "
              "aprovecha la comprensión semántica del modelo para emitir un "
              "juicio contextual (\"Ofensivo\" / \"No ofensivo\").",
         body_size=12.5)
add_card(slide, Inches(5.05), Inches(1.2), Inches(4.65), Inches(2.5),
         fill=SOFT_BLUE, title="Ejemplo real de la base",
         body="Rúbrica: \"Clasifica el comentario como OFENSIVO o "
              "NO_OFENSIVO\".\n"
              "Texto: \"Pues era porra en la UNAM\".\n"
              "Respuesta: NO_OFENSIVO.",
         body_size=12.5)
add_text(slide, "Flujo técnico de la sesión (Claude + R)", Inches(0.3),
         Inches(3.9), Inches(9.4), Inches(0.35), size=14, bold=True,
         color=NAVY)
pasos = ["Excel con\n1,547 comentarios", "8 lotes de\n~200 comentarios",
         "Claude aplica\nla rúbrica", "CSV con id\ny etiqueta",
         "R une etiquetas\ny base (Excel)"]
for i, p in enumerate(pasos):
    x = 0.3 + i * 1.9
    add_card(slide, Inches(x), Inches(4.35), Inches(1.75), Inches(1.1),
             fill=LIGHT_BLUE if i % 2 == 0 else SOFT_BLUE, title=p,
             title_size=11)
    if i < 4:
        add_text(slide, ">", Inches(x + 1.75), Inches(4.6), Inches(0.15),
                 Inches(0.5), size=18, bold=True, color=NAVY,
                 align=PP_ALIGN.CENTER)
add_card(slide, Inches(0.3), Inches(5.65), Inches(9.4), Inches(1.15),
         fill=HIGHLIGHT_GREEN, title="Un modelo grande y una rúbrica explícita",
         body="El criterio se escribe antes de ver los datos y se guarda con "
              "el código. Así cualquiera puede repetir el etiquetado con "
              "otro modelo (local con Ollama o por API) y comparar.",
         title_size=13, body_size=12)

# 6. El prompt
n += 1
slide = nueva("La rúbrica define qué cuenta como ofensivo", n)
add_code(slide,
         'rubrica <- str_c(\n'
         '  "Eres un moderador de comentarios de YouTube en español de México. ",\n'
         '  "Clasifica el comentario como OFENSIVO solo si cumple al menos una: ",\n'
         '  "(1) contiene insultos, groserías o apodos despectivos dirigidos a una ",\n'
         '  "persona o grupo (incluye albures y modismos mexicanos); (2) ataca a ",\n'
         '  "alguien por su clase social, género, orientación sexual, origen, edad o ",\n'
         '  "apariencia; (3) desea daño, amenaza o humilla. Criticar con dureza, ",\n'
         '  "burlarse de una idea o estar en desacuerdo con un gobierno, partido o ",\n'
         '  "persona pública SIN insultos ni ataques personales es NO_OFENSIVO. ",\n'
         '  "Comentarios neutros, de apoyo, chistes sin blanco humano o preguntas son ",\n'
         '  "NO_OFENSIVO. Responde únicamente con una palabra: OFENSIVO o NO_OFENSIVO."\n'
         ')',
         Inches(0.3), Inches(1.2), Inches(9.4), Inches(2.55), size=9.5)
add_card(slide, Inches(0.3), Inches(3.9), Inches(4.65), Inches(2.3),
         fill=SOFT_GREEN, title_color=DARK_GREEN, title="Ventajas",
         body="Rápido y flexible ante criterios nuevos.\n"
              "No requiere datos de entrenamiento.\n"
              "Cambiar el criterio es cambiar el prompt.\n"
              "Se le puede pedir que explique su decisión.",
         body_size=12)
add_card(slide, Inches(5.05), Inches(3.9), Inches(4.65), Inches(2.3),
         fill=SOFT_RED, title_color=DARK_RED, title="Limitaciones",
         body="Varía entre intentos y entre modelos.\n"
              "Hay que normalizar la salida (regex).\n"
              "Hereda el sesgo del modelo y de la rúbrica.\n"
              "Una rúbrica vaga produce etiquetas vagas.",
         body_size=12)
add_card(slide, Inches(0.3), Inches(6.3), Inches(9.4), Inches(0.55),
         fill=HIGHLIGHT_GREEN,
         title="La definición operativa de la rúbrica es la definición "
               "operativa del modelo que entrenaremos después.",
         title_size=12.5)

# 7. Código httr2
n += 1
slide = nueva("Desde R, ellmer manda la rúbrica y cada comentario a Claude", n)
add_code(slide,
         'library(ellmer)                      # un solo paquete para varias API de LLM\n'
         '\n'
         'chat <- chat_anthropic(\n'
         '  system_prompt = rubrica,           # la rúbrica de la diapositiva anterior\n'
         '  model = "claude-fable-5-1",        # el modelo que etiquetó la base\n'
         '  params = params(temperature = 0,   # respuestas reproducibles\n'
         '                  max_tokens = 10)   # bastan pocos tokens\n'
         ')\n'
         'respuesta <- chat$chat(str_c("Comentario: \\"", texto_i, "\\""), echo = "none")\n'
         '\n'
         '# Normalizar la salida: "OFENSIVO.", "no_ofensivo", "No ofensivo" ...\n'
         'etiqueta <- case_when(\n'
         '  str_detect(str_to_upper(respuesta), "NO[_ ]?OFENSIVO") ~ "No ofensivo",\n'
         '  str_detect(str_to_upper(respuesta), "OFENSIVO")        ~ "Ofensivo",\n'
         '  TRUE ~ NA_character_\n'
         ')\n'
         '\n'
         '# Con un modelo local basta cambiar el constructor:\n'
         'chat <- chat_ollama(system_prompt = rubrica, model = "gemma4:12b")',
         Inches(0.3), Inches(1.2), Inches(9.4), Inches(4.55), size=10.5)
add_card(slide, Inches(0.3), Inches(5.9), Inches(4.65), Inches(0.95),
         fill=SOFT_RED, title_color=DARK_RED, title="Cuidado con el orden",
         body="El patrón NO_OFENSIVO se prueba primero; si no, "
              "\"no ofensivo\" caería en \"ofensivo\".",
         title_size=12, body_size=11)
add_card(slide, Inches(5.05), Inches(5.9), Inches(4.65), Inches(0.95),
         fill=SOFT_GREEN, title_color=DARK_GREEN, title="La llave nunca va en el código",
         body="ANTHROPIC_API_KEY se guarda en .Renviron; ellmer la lee "
              "sola. Un modelo local (Ollama) no necesita llave.",
         title_size=12, body_size=11)

# 8. Ofensivos por canal
n += 1
slide_figura(f"La proporción de ofensivos va de {PCT_TEMA[TEMA_MIN]} % a "
             f"{PCT_TEMA[TEMA_MAX]} % según el canal",
             n, "fig_ofensivos_canal.png",
             "La misma rúbrica aplicada a públicos distintos da bases "
             "distintas. Un modelo entrenado con un canal no generaliza solo "
             "a otro.")

# 9. Balance
n += 1
slide_figura(f"La base tiene {N_OF + N_NO:,} comentarios etiquetados, {PCT_OF} % ofensivos",
             n, "fig_balance.png",
             f"La clase mayoritaria es \"No ofensivo\" ({100 - PCT_OF} %). "
             "Ese desbalance va a importar al leer la exactitud.")

# 10. Clasificación supervisada
n += 1
slide = nueva("Clasificar es aprendizaje supervisado", n)
add_card(slide, Inches(0.3), Inches(1.2), Inches(9.4), Inches(1.25),
         title="Modelado de clasificación",
         body="Entrenar un algoritmo para predecir la categoría de documentos "
              "nuevos a partir de patrones aprendidos en documentos ya "
              "etiquetados. Es una de las aplicaciones más prácticas del "
              "análisis de texto.",
         body_size=12.5)
add_card(slide, Inches(0.3), Inches(2.6), Inches(4.65), Inches(2.9),
         title="Características",
         body="Supervisado: necesita etiquetas.\n"
              "Aprende la relación palabras -> clase.\n"
              "Predice la clase de textos que nunca vio.\n"
              "Se evalúa con datos que no usó para aprender.\n"
              "Su techo es la calidad de las etiquetas.",
         body_size=12.5, line_spacing=1.4)
add_card(slide, Inches(5.05), Inches(2.6), Inches(4.65), Inches(2.9),
         fill=SOFT_BLUE, title="Algunos modelos",
         body="Regresión logística (hoy, como base).\n"
              "Árboles de decisión y bosques aleatorios (hoy).\n"
              "XGBoost y otros ensambles.\n"
              "Máquinas de soporte vectorial (SVM).\n"
              "Redes neuronales y modelos tipo BERT.",
         body_size=12.5, line_spacing=1.4)
add_card(slide, Inches(0.3), Inches(5.65), Inches(9.4), Inches(1.2),
         fill=HIGHLIGHT_GREEN,
         title="Hoy: regresión logística y bosque aleatorio, los dos con el "
               "mismo flujo de tidymodels.",
         body="El flujo (partir, preparar, entrenar, evaluar) es el mismo para "
              "cualquier modelo; cambiar de algoritmo cuesta una línea.",
         title_size=13, body_size=12)

# 11. Partición
n += 1
slide = nueva("Primero se aparta la base de prueba, antes de tocar nada", n)
add_rect(slide, Inches(0.3), Inches(1.25), Inches(7.05), Inches(0.7), NAVY)
add_rect(slide, Inches(7.35), Inches(1.25), Inches(2.35), Inches(0.7),
         DARK_RED)
add_text(slide, f"Entrenamiento: 75 % ({N_ENT:,} comentarios)", Inches(0.3),
         Inches(1.25), Inches(7.05), Inches(0.7), size=13, bold=True,
         color=WHITE, align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
add_text(slide, f"Prueba: 25 % ({N_PRU})", Inches(7.35), Inches(1.25),
         Inches(2.35), Inches(0.7), size=13, bold=True, color=WHITE,
         align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
add_card(slide, Inches(0.3), Inches(2.15), Inches(4.65), Inches(1.9),
         title="Por qué",
         body="Un modelo puede memorizar los datos con los que aprendió "
              "(sobreajuste). Solo los datos que nunca vio dicen qué tan "
              "bien generaliza.",
         body_size=12)
add_card(slide, Inches(5.05), Inches(2.15), Inches(4.65), Inches(1.9),
         title="Cómo",
         body="initial_split(prop = 0.75, strata = etiqueta) reparte al azar y "
              "conserva la proporción de clases en ambas bases. set.seed() "
              "hace el reparto reproducible.",
         body_size=12)
add_card(slide, Inches(0.3), Inches(4.2), Inches(4.65), Inches(1.9),
         fill=SOFT_RED, title_color=DARK_RED, title="Error frecuente en texto",
         body="Construir la matriz documento-término con todos los "
              "comentarios y partir después. El vocabulario de prueba se "
              "filtra a la base de entrenamiento: fuga de información.",
         body_size=12)
add_card(slide, Inches(5.05), Inches(4.2), Inches(4.65), Inches(1.9),
         fill=SOFT_GREEN, title_color=DARK_GREEN, title="Lo que hace tidymodels",
         body="La receta se ajusta (prep) solo con entrenamiento. Al predecir "
              "la base de prueba, las palabras nuevas simplemente se ignoran.",
         body_size=12)
add_code(slide, "set.seed(2026)\n"
         "particion <- initial_split(comentarios, prop = 0.75, strata = etiqueta)\n"
         "entrenamiento <- training(particion)\n"
         "prueba        <- testing(particion)",
         Inches(0.3), Inches(6.2), Inches(9.4), Inches(0.95), size=10)

# 12. Árbol
n += 1
slide_figura("Un árbol de decisión hace preguntas sobre palabras", n,
             "fig_arbol.png",
             "Cada pregunta divide los comentarios en dos grupos más puros. "
             "Un solo árbol memoriza; muchos árboles distintos generalizan.",
             fuente=False, img_h=5.0)

# 13. Bosque
n += 1
slide = nueva("El bosque aleatorio promedia cientos de árboles distintos", n)
add_card(slide, Inches(0.3), Inches(1.2), Inches(3.0), Inches(2.5),
         title="Muestras distintas",
         body="Cada árbol se entrena con una muestra con reemplazo de los "
              "comentarios (bagging). Los que no entran sirven para estimar "
              "el error \"fuera de la bolsa\" (OOB).",
         body_size=11.5)
add_card(slide, Inches(3.5), Inches(1.2), Inches(3.0), Inches(2.5),
         title="Palabras distintas",
         body="En cada división el árbol solo puede elegir entre mtry "
              "columnas al azar. Así ningún árbol depende de la misma "
              "grosería y el bosque es más diverso.",
         body_size=11.5)
add_card(slide, Inches(6.7), Inches(1.2), Inches(3.0), Inches(2.5),
         title="Votación",
         body="Cada árbol vota una clase; el bosque reporta la proporción de "
              "votos como probabilidad. Gana la clase con más votos.",
         body_size=11.5)
add_text(slide, "Hiperparámetros que sí conviene conocer", Inches(0.3),
         Inches(3.9), Inches(9.4), Inches(0.35), size=14, bold=True,
         color=NAVY)
add_tabla(slide, [["Hiperparámetro", "Qué controla", "Valor típico en texto"],
                  ["trees (ntree)", "Número de árboles",
                   "100 para explorar; 300-500 normal; 1,000 para exprimir"],
                  ["mtry", "Columnas candidatas por división",
                   "raíz del número de columnas; con 500 columnas, ~22"],
                  ["min_n (nodesize)", "Comentarios mínimos por hoja",
                   "5-10; valores altos simplifican el árbol"]],
          Inches(0.3), Inches(4.3), Inches(9.4), Inches(1.75),
          col_widths=[Inches(1.9), Inches(3.0), Inches(4.5)], size=11)
add_code(slide, 'rand_forest(trees = 500, mtry = 25, min_n = 5) %>%\n'
         '  set_engine("ranger", importance = "impurity") %>%\n'
         '  set_mode("classification")',
         Inches(0.3), Inches(6.2), Inches(9.4), Inches(0.95), size=10)

# 14. Regresión logística
n += 1
slide = nueva("La regresión logística penalizada es el modelo base", n)
add_formula_box(slide,
                "P(ofensivo) = 1 / (1 + exp(-(b0 + b1*x1 + ... + bk*xk)))",
                "x_j es el tf-idf de la palabra j en el comentario; "
                "b_j > 0 empuja hacia \"Ofensivo\" y b_j < 0 hacia "
                "\"No ofensivo\".",
                Inches(0.3), Inches(1.2), Inches(9.4), Inches(1.3))
add_card(slide, Inches(0.3), Inches(2.7), Inches(4.65), Inches(2.3),
         title="Por qué empezar aquí",
         body="Ya la conocen de cursos anteriores. Es rápida, estable con "
              "pocas observaciones y entrega un coeficiente por palabra que "
              "se puede leer. Si un modelo complejo no la supera, algo anda "
              "mal con los datos, no con el modelo.",
         body_size=12)
add_card(slide, Inches(5.05), Inches(2.7), Inches(4.65), Inches(2.3),
         title="Penalización lasso",
         body="Con cientos de columnas y pocos cientos de filas, la regresión "
              "sin penalizar sobreajusta. La penalización L1 (mixture = 1) "
              "fuerza a cero los coeficientes de las palabras que no ayudan: "
              "selecciona variables sola.",
         body_size=12)
add_code(slide, 'logistic_reg(penalty = 0.01, mixture = 1) %>%\n'
         '  set_engine("glmnet") %>%\n'
         '  set_mode("classification")',
         Inches(0.3), Inches(5.15), Inches(9.4), Inches(0.95), size=10.5)
add_card(slide, Inches(0.3), Inches(6.25), Inches(9.4), Inches(0.6),
         fill=HIGHLIGHT_GREEN,
         title="penalty se puede afinar con validación cruzada (tune); hoy "
               "se fija en 0.01 para mantener el flujo simple.",
         title_size=12.5)

# 15. Receta
n += 1
slide = nueva("La receta aprende el vocabulario solo con entrenamiento", n)
add_code(slide,
         'library(tidymodels)\n'
         'library(textrecipes)\n'
         '\n'
         'stopwords_es <- stopwords::stopwords("es", source = "stopwords-iso")\n'
         '\n'
         'receta <- recipe(etiqueta ~ texto, data = entrenamiento) %>%\n'
         '  step_mutate(texto = str_remove_all(texto, "@@\\\\S+")) %>%  # menciones\n'
         '  step_mutate(texto = str_remove_all(texto, "\\\\d+")) %>%    # dígitos\n'
         '  step_tokenize(texto) %>%                                  # palabras\n'
         '  step_stopwords(texto, custom_stopword_source = stopwords_es) %>%\n'
         '  step_tokenfilter(texto, min_times = 3, max_tokens = 500) %>%\n'
         '  step_tfidf(texto)                                         # DTM tf-idf\n'
         '\n'
         '# Para inspeccionar la matriz que produce:\n'
         'receta %>% prep() %>% bake(new_data = NULL) %>% dim()\n'
         f'#> [1] {N_ENT} {TERMINOS + 1}',
         Inches(0.3), Inches(1.2), Inches(9.4), Inches(4.1), size=10.5)
add_card(slide, Inches(0.3), Inches(5.45), Inches(3.0), Inches(1.4),
         title="step_tokenize",
         body="Parte el texto en palabras. Acepta otros motores (n-gramas, "
              "lematización con udpipe).", title_size=12, body_size=11)
add_card(slide, Inches(3.5), Inches(5.45), Inches(3.0), Inches(1.4),
         title="step_tokenfilter",
         body="Filtra la dispersión: mínimo de apariciones y máximo de "
              "columnas, calculados en entrenamiento.", title_size=12,
         body_size=11)
add_card(slide, Inches(6.7), Inches(5.45), Inches(3.0), Inches(1.4),
         title="step_tfidf",
         body="Crea una columna tfidf_texto_palabra por término. Hace lo "
              "mismo que cast_dtm(weighting = weightTfIdf).",
         title_size=12, body_size=11)

# 16. Workflow
n += 1
slide = nueva("Receta + modelo = flujo de trabajo; el mismo para ambos", n)
add_code(slide,
         '# Un flujo de trabajo une la receta con el modelo\n'
         'flujo_bosque <- workflow() %>%\n'
         '  add_recipe(receta) %>%\n'
         '  add_model(modelo_bosque)\n'
         '\n'
         '# Entrenar: prep de la receta + ajuste del modelo, en un paso\n'
         'ajuste_bosque <- fit(flujo_bosque, data = entrenamiento)\n'
         '\n'
         '# Predecir la base de prueba: augment agrega .pred_class y .pred_Ofensivo\n'
         'predicciones <- augment(ajuste_bosque, new_data = prueba)\n'
         '\n'
         '# Evaluar\n'
         'predicciones %>% conf_mat(truth = etiqueta, estimate = .pred_class)\n'
         'predicciones %>%\n'
         '  metric_set(accuracy, precision, recall, f_meas)(\n'
         '    truth = etiqueta, estimate = .pred_class)\n'
         'predicciones %>% roc_auc(truth = etiqueta, .pred_Ofensivo)',
         Inches(0.3), Inches(1.2), Inches(9.4), Inches(4.5), size=10.5)
add_card(slide, Inches(0.3), Inches(5.85), Inches(4.65), Inches(1.0),
         title="Cambiar de modelo = cambiar una línea",
         body="add_model(modelo_logistico) reutiliza la misma receta y la "
              "misma evaluación.", title_size=12, body_size=11)
add_card(slide, Inches(5.05), Inches(5.85), Inches(4.65), Inches(1.0),
         fill=SOFT_RED, title_color=DARK_RED, title="Clase positiva",
         body="yardstick toma el primer nivel del factor como positivo: "
              "por eso etiqueta se define con levels = c(\"Ofensivo\", ...).",
         title_size=12, body_size=11)

# 17. Matriz de confusión esquema
n += 1
slide_figura("La matriz de confusión separa cuatro tipos de resultado", n,
             "fig_confusion_esquema.png",
             "Para un moderador, el falso negativo (ofensa que pasa) y el "
             "falso positivo (crítica censurada) cuestan distinto. Las métricas "
             "miden cada uno.", fuente=False, img_h=4.9)

# 18. Métricas
n += 1
slide = nueva("Cuatro métricas responden cuatro preguntas distintas", n)
cajas = [("Exactitud = (VP + VN) / total",
          "¿Qué proporción de todos los comentarios clasificó bien? "
          "Engaña cuando una clase domina."),
         ("Precisión = VP / (VP + FP)",
          "De los que marcó como ofensivos, ¿cuántos lo eran? Alta precisión "
          "= pocas críticas censuradas por error."),
         ("Sensibilidad = VP / (VP + FN)",
          "De los ofensivos reales, ¿cuántos detectó? Alta sensibilidad = "
          "pocas ofensas que se escapan. También se llama recall."),
         ("F1 = 2 * Prec * Sens / (Prec + Sens)",
          "Media armónica de precisión y sensibilidad. Resume ambas en un "
          "número cuando no hay una preferida.")]
for i, (f, s) in enumerate(cajas):
    add_formula_box(slide, f, s, Inches(0.3), Inches(1.2 + i * 1.3),
                    Inches(9.4), Inches(1.2))
add_card(slide, Inches(0.3), Inches(6.45), Inches(9.4), Inches(0.5),
         fill=HIGHLIGHT_GREEN,
         title="Siempre reportar al menos exactitud, precisión y sensibilidad "
               "de la clase que importa.",
         title_size=12.5)

# 19. Exactitud engaña
n += 1
slide_figura(f"Un modelo que nunca detecta ofensas ya tiene {PCT_MAYOR} % de exactitud",
             n, "fig_exactitud_engana.png",
             f"Cualquier modelo debe compararse contra esa referencia de "
             f"{PCT_MAYOR} %. Su sensibilidad es 0 %: no sirve para nada "
             "aunque su exactitud suene bien.", img_h=4.7)

# 20. Confusión bosque
n += 1
slide_figura(f"El bosque acierta {RF['accuracy']} % y detecta {RF['recall']} % "
             "de los ofensivos", n, "fig_confusion_bosque.png",
             f"Precisión de {RF['precision']} %: cuando el bosque marca un "
             f"comentario como ofensivo, acierta {RF['precision']} de cada 100.")

# 21. Métricas comparadas
n += 1
slide_figura(f"{MEJOR} obtiene el mejor F1; ambos superan la referencia de "
             f"{PCT_MAYOR} %", n, "fig_metricas.png",
             f"Logística: exactitud {LG['accuracy']} %, sensibilidad "
             f"{LG['recall']} %. Bosque: exactitud {RF['accuracy']} %, "
             f"sensibilidad {RF['recall']} %. La ganancia sobre la referencia "
             "es el valor real del modelo.")

# 22. ROC
n += 1
slide_figura("La curva ROC muestra el intercambio entre detectar y equivocarse",
             n, "fig_roc.png",
             f"AUC de {RF['roc_auc'] / 100:.2f} (bosque) y "
             f"{LG['roc_auc'] / 100:.2f} (logística). Mover el umbral de 0.5 "
             "cambia sensibilidad por falsos positivos sin reentrenar.")

# 23. Importancia
n += 1
slide_figura("Las palabras importantes son groserías y apodos políticos", n,
             "fig_importancia.png",
             f"Encabezan la lista: {TOP_PALABRAS}. El modelo aprendió el "
             "vocabulario del insulto, pero también el del tema: eso es "
             "señal de sesgo.")

# 24. Coeficientes
n += 1
slide_figura("Los coeficientes de la logística muestran hacia dónde empuja "
             "cada palabra", n, "fig_coeficientes.png",
             "A diferencia del bosque, el signo dice la dirección: rojo sube "
             "la probabilidad de ofensa, verde la baja. La lasso dejó en cero "
             "el resto.")

# 25. Errores
n += 1
slide = nueva("Los errores del bosque enseñan sus límites", n)
add_text(slide, "Comentarios de la base de prueba en los que el bosque se "
         "equivocó con más confianza:", Inches(0.3), Inches(1.15),
         Inches(9.4), Inches(0.4), size=13)
ejemplos = [e for e in errores
            if 8 <= len(e["texto"].split()) and len(e["texto"]) <= 260][:4]
for i, e in enumerate(ejemplos):
    texto = e["texto"].replace("\n", " ")
    texto = texto if len(texto) <= 230 else texto[:227] + "..."
    real, pred = e["etiqueta"], e[".pred_class"]
    prob = float(e[".pred_Ofensivo"])
    fill = SOFT_RED if real == "Ofensivo" else LIGHT_BLUE
    tcol = DARK_RED if real == "Ofensivo" else NAVY
    add_card(slide, Inches(0.3), Inches(1.6 + i * 1.22), Inches(9.4),
             Inches(1.12), fill=fill, title_color=tcol,
             title=f"Real: {real}  |  Modelo: {pred} "
                   f"(P(ofensivo) = {prob:.2f})",
             body=f"\"{texto}\"", title_size=11, body_size=10.5,
             line_spacing=1.15)
add_card(slide, Inches(0.3), Inches(6.5), Inches(9.4), Inches(0.45),
         fill=HIGHLIGHT_GREEN,
         title="Ironía, ofensas sin groserías y etiquetas discutibles: ahí "
               "falla la bolsa de palabras.",
         title_size=12)

# 26. LLM vs supervisado
n += 1
slide = nueva("El LLM y el modelo supervisado se complementan", n)
add_tabla(slide, [["", "Etiquetado con LLM", "Modelo supervisado"],
                  ["Datos etiquetados", "No necesita", "Cientos o miles"],
                  ["Velocidad", "Segundos por texto",
                   "Miles de textos por segundo"],
                  ["Costo por texto", "Cómputo (GPU) o API", "Casi cero una vez entrenado"],
                  ["Reproducibilidad", "Varía entre modelos e intentos",
                   "Determinista con set.seed()"],
                  ["Interpretabilidad", "Puede explicar en lenguaje natural",
                   "Coeficientes e importancia de palabras"],
                  ["Cambiar el criterio", "Reescribir el prompt",
                   "Reetiquetar y reentrenar"],
                  ["Ironía y contexto", "Mejor", "Débil (bolsa de palabras)"],
                  ["Dependencias", "Servidor o API disponible",
                   "Solo R y el modelo guardado"]],
          Inches(0.3), Inches(1.2), Inches(9.4), Inches(4.4),
          col_widths=[Inches(2.2), Inches(3.6), Inches(3.6)], size=11)
add_card(slide, Inches(0.3), Inches(5.8), Inches(9.4), Inches(1.05),
         fill=HIGHLIGHT_GREEN, title="El flujo real en la industria",
         body="El LLM etiqueta una muestra (o la etiquetan personas); con ella "
              "se entrena un modelo barato y rápido que clasifica millones de "
              "textos; el LLM revisa solo los casos dudosos.",
         title_size=13, body_size=12)

# 27. Mejoras
n += 1
slide = nueva("El modelo mejora con mejores etiquetas, no solo con más árboles", n)
mejoras = [
    ("1. Mejores etiquetas", SOFT_GREEN, DARK_GREEN,
     "Revisar a mano una muestra, pedir una segunda opinión a otro LLM o "
     "afinar la rúbrica. Es la palanca más grande: el modelo no supera el "
     "ruido de sus etiquetas."),
    ("2. Más datos", SOFT_GREEN, DARK_GREEN,
     "Comentarios de más videos y temas. Con 1,000 filas los intervalos de "
     "las métricas son anchos."),
    ("3. Mejores variables", LIGHT_BLUE, NAVY,
     "Diccionario de groserías como columna extra, bigramas, lematización "
     "con udpipe, conteo de mayúsculas o signos de exclamación."),
    ("4. Afinar hiperparámetros", LIGHT_BLUE, NAVY,
     "tune_grid() con validación cruzada para penalty, mtry y min_n. Nunca "
     "afinar sobre la base de prueba."),
    ("5. Otro modelo o ensamble", LIGHT_BLUE, NAVY,
     "XGBoost, SVM o un modelo tipo BERT en español. Cambiar add_model() "
     "y comparar con las mismas métricas."),
    ("6. Mover el umbral", LIGHT_BLUE, NAVY,
     "Si importa más no dejar pasar ofensas, bajar el umbral de 0.5 sube la "
     "sensibilidad a costa de la precisión."),
]
for i, (t, f, c, b) in enumerate(mejoras):
    x, y = 0.3 + (i % 3) * 3.2, 1.2 + (i // 3) * 2.6
    add_card(slide, Inches(x), Inches(y), Inches(3.0), Inches(2.45),
             fill=f, title_color=c, title=t, body=b, title_size=13,
             body_size=11.5)
add_card(slide, Inches(0.3), Inches(6.45), Inches(9.4), Inches(0.5),
         fill=HIGHLIGHT_GREEN,
         title="Orden sugerido: etiquetas, datos, variables; los "
               "hiperparámetros al final.",
         title_size=12.5)

# 28. Ética
n += 1
slide = nueva("Un clasificador hereda los sesgos de quien etiqueta", n)
add_card(slide, Inches(0.3), Inches(1.2), Inches(4.65), Inches(2.45),
         fill=SOFT_RED, title_color=DARK_RED, title="Lo que aprendió el bosque",
         body="Entre las palabras más importantes aparecen nombres y apodos "
              "políticos. El modelo asocia el tema con la ofensa, no solo el "
              "insulto. Un comentario crítico sin groserías puede quedar "
              "marcado.",
         body_size=12)
add_card(slide, Inches(5.05), Inches(1.2), Inches(4.65), Inches(2.45),
         fill=SOFT_RED, title_color=DARK_RED, title="Español coloquial",
         body="\"Wey\", \"pinche\" o \"neta\" aparecen en comentarios "
              "amistosos. Un modelo entrenado con etiquetas estrictas "
              "penaliza registros informales y a quienes los usan.",
         body_size=12)
add_card(slide, Inches(0.3), Inches(3.8), Inches(4.65), Inches(2.3),
         title="Preguntas antes de usarlo",
         body="¿Quién definió \"ofensivo\" y con qué criterio?\n"
              "¿Qué error cuesta más: censurar o dejar pasar?\n"
              "¿Se evaluó por tema, por grupo o solo en promedio?\n"
              "¿Hay revisión humana para los casos dudosos?",
         body_size=12, line_spacing=1.35)
add_card(slide, Inches(5.05), Inches(3.8), Inches(4.65), Inches(2.3),
         fill=SOFT_GREEN, title_color=DARK_GREEN, title="Buenas prácticas",
         body="Documentar el prompt o la guía de anotación.\n"
              "Reportar precisión y sensibilidad por subgrupo.\n"
              "Mantener a una persona en el circuito de decisión.\n"
              "Reentrenar cuando cambie el tema o el lenguaje.",
         body_size=12, line_spacing=1.35)
add_card(slide, Inches(0.3), Inches(6.25), Inches(9.4), Inches(0.6),
         fill=HIGHLIGHT_GREEN,
         title="El modelo describe las etiquetas; no define qué es ofensivo.",
         title_size=13)

# 29. Conclusiones
n += 1
slide = nueva("Conclusiones", n)
add_card(slide, Inches(0.3), Inches(1.2), Inches(9.4), Inches(5.65),
         fill=HIGHLIGHT_GREEN, title="Cinco ideas para llevarse",
         body="1. La matriz documento-término es el puente entre texto y modelo; "
              "es dispersa y hay que recortarla con criterio.\n\n"
              "2. Un LLM etiqueta rápido con una rúbrica explícita, pero la "
              "etiqueta es el techo del modelo: hay que auditarla.\n\n"
              "3. La base de prueba se aparta antes de construir el vocabulario; "
              "tidymodels lo garantiza con recetas y flujos de trabajo.\n\n"
              f"4. La exactitud engaña: la referencia era {PCT_MAYOR} %. Se "
              "reportan precisión, sensibilidad y F1 de la clase que importa.\n\n"
              "5. Las palabras importantes revelan qué aprendió el modelo, "
              "incluidos sus sesgos. Mejorar etiquetas rinde más que afinar "
              "hiperparámetros.",
         title_size=17, body_size=15, line_spacing=1.35)

# 30. Recursos
n += 1
slide = nueva("Recursos", n)
recursos = [
    ("Hvitfeldt, E. y Silge, J. (2021). Supervised Machine Learning for Text "
     "Analysis in R. CRC Press.", "Libro gratuito en línea: smltar.com. "
     "Capítulos 5 a 7 cubren exactamente el flujo de hoy."),
    ("Silge, J. y Robinson, D. (2017). Text Mining with R: A Tidy Approach. "
     "O'Reilly.", "tidytextmining.com. Capítulo 5: cast_dtm() y matrices dispersas."),
    ("Kuhn, M. y Silge, J. (2022). Tidy Modeling with R. O'Reilly.",
     "tmwr.org. Recetas, flujos de trabajo, yardstick y tune."),
    ("Documentación de textrecipes y ellmer",
     "textrecipes.tidymodels.org; ellmer.tidyverse.org (chat_anthropic, "
     "chat_ollama)."),
    ("Código y datos de la sesión",
     "02_Codigo/Sesion_14_Clasificacion: 01_etiquetado_claude.R, "
     "02_modelo_tidymodels.R y la carpeta 01_datos."),
]
for i, (t, b) in enumerate(recursos):
    add_card(slide, Inches(0.3), Inches(1.2 + i * 1.12), Inches(9.4),
             Inches(1.02), title=t, body=b, title_size=12, body_size=11)

# 31. Cierre
slide = prs.slides.add_slide(BLANK)
add_rect(slide, 0, 0, SW, Inches(1.1), GRAY_TOP)
add_text(slide, "Tecnológico de Monterrey", Inches(0.4), Inches(0.25),
         Inches(5), Inches(0.6), size=20, color=NAVY, bold=True,
         anchor=MSO_ANCHOR.MIDDLE)
add_rect(slide, 0, Inches(1.1), SW, Inches(3.5), SOFT_BLUE)
add_text(slide, "Gracias", Inches(0.6), Inches(1.7), Inches(8.8), Inches(2),
         size=80, color=NAVY, bold=True, align=PP_ALIGN.CENTER)
add_rect(slide, Inches(3.0), Inches(5.4), Inches(4.0), Inches(1.0), NAVY)
add_text(slide, "¿Preguntas?", Inches(3.0), Inches(5.4), Inches(4.0),
         Inches(1.0), size=28, color=WHITE, bold=True,
         align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)

prs.save(OUT)
print("Guardado:", OUT, "| diapositivas:", len(prs.slides))
