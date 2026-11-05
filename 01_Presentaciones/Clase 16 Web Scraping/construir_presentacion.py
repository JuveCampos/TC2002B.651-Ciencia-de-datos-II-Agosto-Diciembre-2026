"""Construye Clase16_httr2_y_precauciones.pptx (estilo Tec, 4:3).

Uso: python3 construir_presentacion.py, desde esta carpeta.
"""
import csv
import matplotlib as mpl
import matplotlib.pyplot as plt
from PIL import ImageFont
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.oxml.ns import qn
from pptx.util import Emu, Inches, Pt

IMG = "img_presentacion"
OUT = "Clase16_httr2_y_precauciones.pptx"
CORTO = "httr2 y precauciones"
FUENTE_NEGRITA = "/opt/anaconda3/fonts/Ubuntu-B.ttf"

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
NOTA = RGBColor(0x66, 0x66, 0x66)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
BLACK = RGBColor(0x00, 0x00, 0x00)
UBUNTU = "Ubuntu"
MONO = "Menlo"

# Figura: longitud de las 100 conferencias frente al límite de Excel --------
mpl.rcParams["font.family"] = "Ubuntu"
with open(f"{IMG}/longitudes_conferencias.csv") as f:
    longitudes = [int(r["n"]) for r in csv.DictReader(f)]
assert len(longitudes) == 100 and min(longitudes) > 32767

fig, ax = plt.subplots(figsize=(9.2, 4.1), dpi=300)
ax.hist([n / 1000 for n in longitudes], bins=range(0, 125, 5),
        color="#1E4C7D", edgecolor="white", linewidth=1.5)
ax.axvline(32.767, color="#C0392B", linewidth=2.2)
ax.annotate("Límite de una celda de Excel:\n32,767 caracteres",
            xy=(32.767, 17), xytext=(34.5, 17), fontsize=12, color="#C0392B",
            fontweight="bold", va="center")
ax.annotate(f"La conferencia más corta\ntiene {min(longitudes):,} caracteres",
            xy=(min(longitudes) / 1000, 1.2), xytext=(36, 10.5), fontsize=12,
            color="#333333",
            arrowprops=dict(arrowstyle="->", color="#555555", lw=1.2))
ax.annotate(f"La más larga tiene\n{max(longitudes):,}",
            xy=(max(longitudes) / 1000, 1.2), xytext=(104, 10.5), fontsize=12,
            color="#333333",
            arrowprops=dict(arrowstyle="->", color="#555555", lw=1.2))
ax.set_xlim(0, 125)
ax.set_ylim(0, 19)
ax.set_yticks(range(0, 19, 3))
ax.set_xlabel("Miles de caracteres por conferencia", fontsize=12, color="#333333")
ax.set_ylabel("Número de conferencias", fontsize=12, color="#333333")
ax.tick_params(labelsize=11, colors="#555555")
for lado in ("top", "right"):
    ax.spines[lado].set_visible(False)
for lado in ("left", "bottom"):
    ax.spines[lado].set_color("#888888")
ax.grid(axis="y", alpha=0.25)
ax.set_axisbelow(True)
plt.tight_layout()
plt.savefig(f"{IMG}/longitud_conferencias.png", dpi=300, facecolor="white")
plt.close()

# Helpers --------------------------------------------------------------------
prs = Presentation()
prs.slide_width = Inches(10)
prs.slide_height = Inches(7.5)
SW = prs.slide_width
BLANK = prs.slide_layouts[6]
I = Inches


def add_text(slide, text, x, y, w, h, *, size=14, bold=False, color=BLACK,
             align=PP_ALIGN.LEFT, italic=False, spacing=None, font=UBUNTU,
             anchor=None):
    box = slide.shapes.add_textbox(I(x), I(y), I(w), I(h))
    tf = box.text_frame
    tf.word_wrap = True
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = Emu(0)
    if anchor is not None:
        tf.vertical_anchor = anchor
    for i, linea in enumerate(text.split("\n")):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.alignment = align
        if spacing is not None:
            p.line_spacing = spacing
        run = p.add_run()
        run.text = linea
        run.font.size = Pt(size)
        run.font.bold = bold
        run.font.italic = italic
        run.font.color.rgb = color
        run.font.name = font
    return box


def add_rect(slide, x, y, w, h, fill):
    sh = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, I(x), I(y), I(w), I(h))
    sh.fill.solid()
    sh.fill.fore_color.rgb = fill
    sh.line.fill.background()
    sh.shadow.inherit = False
    estilo = sh._element.find(qn("p:style"))
    if estilo is not None:
        sh._element.remove(estilo)
    return sh


def add_card(slide, x, y, w, h, title, body, *, fill=LIGHT_BLUE,
             title_color=NAVY, title_size=14, body_size=13):
    add_rect(slide, x, y, w, h, fill)
    add_text(slide, title, x + 0.14, y + 0.1, w - 0.28, 0.35, size=title_size,
             bold=True, color=title_color)
    add_text(slide, body, x + 0.14, y + 0.47, w - 0.28, h - 0.55,
             size=body_size, spacing=1.2)


def add_code(slide, code, x, y, w, h, *, size=12, fill=GRAY_TOP):
    add_rect(slide, x, y, w, h, fill)
    add_text(slide, code, x + 0.14, y + 0.1, w - 0.28, h - 0.2, size=size,
             font=MONO, spacing=1.15)


def add_stat(slide, numero, etiqueta, x, y, w, *, color=NAVY):
    add_text(slide, numero, x, y, w, 0.95, size=54, bold=True, color=color,
             align=PP_ALIGN.CENTER)
    add_text(slide, etiqueta, x, y + 1.0, w, 0.6, size=13, color=GRAY,
             align=PP_ALIGN.CENTER, spacing=1.1)


def add_table(slide, filas, x, y, anchos, alto_fila, *, size=13, mono_col=None,
              colores=None):
    tabla = slide.shapes.add_table(len(filas), len(anchos), I(x), I(y),
                                   I(sum(anchos)),
                                   I(alto_fila * len(filas))).table
    for j, ancho in enumerate(anchos):
        tabla.columns[j].width = I(ancho)
    for i, fila in enumerate(filas):
        tabla.rows[i].height = I(alto_fila)
        for j, valor in enumerate(fila):
            celda = tabla.cell(i, j)
            celda.vertical_anchor = MSO_ANCHOR.MIDDLE
            celda.margin_left = celda.margin_right = I(0.1)
            celda.fill.solid()
            celda.fill.fore_color.rgb = (NAVY if i == 0 else
                                         SOFT_BLUE if i % 2 == 0 else WHITE)
            p = celda.text_frame.paragraphs[0]
            run = p.add_run()
            run.text = valor
            run.font.size = Pt(size)
            es_mono = mono_col == j and i > 0
            run.font.name = MONO if es_mono else UBUNTU
            run.font.bold = i == 0
            run.font.color.rgb = WHITE if i == 0 else BLACK
            if colores and i > 0 and (i, j) in colores:
                run.font.color.rgb = colores[(i, j)]
                run.font.bold = True


numero = [0]


def nueva(titulo, notas, subtitulo=None, fuente=None):
    """Diapositiva con banda navy; el título debe caber en una sola línea."""
    ancho = ImageFont.truetype(FUENTE_NEGRITA, 240).getlength(titulo) / 720
    assert ancho <= 9.3, f"Título demasiado largo ({ancho:.1f}): {titulo}"
    s = prs.slides.add_slide(BLANK)
    numero[0] = len(prs.slides)
    add_rect(s, 0, 0.3, 9.7, 0.7, NAVY)
    add_text(s, titulo, 0.2, 0.3, 9.3, 0.7, size=24, bold=True, color=WHITE,
             anchor=MSO_ANCHOR.MIDDLE)
    if subtitulo:
        add_text(s, subtitulo, 0.4, 1.15, 9.2, 0.4, size=15, italic=True)
    if fuente:
        add_text(s, fuente, 0.3, 7.2, 6.6, 0.2, size=9, color=NOTA)
    add_text(s, f"{CORTO} - {numero[0]}", 7.0, 7.2, 2.7, 0.2, size=9,
             color=GRAY, italic=True, align=PP_ALIGN.RIGHT)
    s.notes_slide.notes_text_frame.text = notas
    return s


def portada_base(s):
    add_rect(s, 0, 0, 10, 1.1, GRAY_TOP)
    add_text(s, "Tecnológico de Monterrey", 0.4, 0.25, 6, 0.6, size=20,
             bold=True, color=NAVY, anchor=MSO_ANCHOR.MIDDLE)
    add_rect(s, 0, 1.1, 10, 3.5, SOFT_BLUE)


EXTRACCION = "extracción propia del 4 de noviembre de 2026."

# 1. Portada -----------------------------------------------------------------
s = prs.slides.add_slide(BLANK)
portada_base(s)
add_text(s, "httr2 y precauciones", 0.6, 1.9, 8.8, 1.2, size=54, bold=True,
         color=NAVY)
add_text(s, "Qué hacer cuando read_html() ya no alcanza", 0.6, 3.3, 8.8, 0.6,
         size=18, italic=True, color=NAVY)
add_text(s, "Ciencia de Datos II. Complemento de la Clase 16\n"
            "Jorge Juvenal Campos Ferreira", 0.6, 5.3, 8.8, 0.8, size=14,
         spacing=1.3)
s.notes_slide.notes_text_frame.text = (
    "Este material complementa la Clase 16. Parte de un error real al "
    "descargar las versiones estenográficas de gob.mx.")

# 2. Idea central ------------------------------------------------------------
s = nueva("Extraer datos reales exige más que read_html()",
          "Situación, complicación y resolución de la sesión. Raspado web "
          "(web scraping) significa extraer datos de páginas con código.",
          "El raspado web (web scraping) extrae datos de páginas con código.")
add_card(s, 0.3, 1.75, 3.0, 3.3, "Situación",
         "read_html() descargó sin problema los 133 artículos de Atiempo.",
         body_size=16)
add_card(s, 3.43, 1.75, 3.0, 3.3, "Complicación",
         "El mismo método falló en gob.mx con un mensaje que no explicaba "
         "la causa.", fill=SOFT_RED, title_color=DARK_RED, body_size=16)
add_card(s, 6.57, 1.75, 3.13, 3.3, "Resolución",
         "httr2 controla la petición, y seis precauciones protegen al sitio "
         "y a los datos.", fill=SOFT_GREEN, title_color=DARK_GREEN,
         body_size=16)
add_card(s, 0.3, 5.3, 9.4, 1.5, "Pregunta de la sesión",
         "¿Qué cambia cuando el servidor deja de comportarse como esperamos?",
         fill=HIGHLIGHT_GREEN, title_color=DARK_GREEN, body_size=15)

# 3. Atiempo -----------------------------------------------------------------
s = nueva("En Atiempo, read_html() alcanzó para todo",
          "Recordar el ejercicio: 12 páginas y 133 artículos. El sitio entrega "
          "HTML normal y acepta la petición de R. Con pausas de 1 segundo, "
          "el script completo tardó 3.5 minutos.",
          "El sitio entrega HTML normal y acepta la petición que envía R.",
          f"Fuente: atiempo.tv, {EXTRACCION}")
add_stat(s, "12", "páginas recorridas", 0.3, 1.9, 3.0)
add_stat(s, "133", "artículos extraídos", 3.43, 1.9, 3.0)
add_stat(s, "0", "errores de conexión", 6.57, 1.9, 3.13, color=DARK_GREEN)
add_code(s, 'html_juve <- read_html(url_juve)\n\n'
            'titulos <- html_juve %>%\n'
            '  html_nodes(".entry-title") %>%\n'
            '  html_nodes("a") %>%\n'
            '  html_text()', 0.3, 3.9, 9.4, 2.3, size=14)
add_text(s, "Cuando todo sale bien, una sola función oculta toda la "
            "conversación con el servidor.", 0.4, 6.4, 9.2, 0.5, size=14)

# 4. Falla -------------------------------------------------------------------
s = nueva("En gob.mx, la misma función falla sin explicar",
          "Este es el error real. El mensaje no distingue entre URL mala, "
          "falta de internet o rechazo del servidor. curl sí recibió 200 "
          "con la misma URL, y eso apunta a algo propio de la sesión.",
          "El mensaje no dice si falló la URL, internet o el servidor.")
add_code(s, 'pagina <- paste0(\n'
            '  "https://www.gob.mx/presidencia/es/archivo/articulos",\n'
            '  "?idiom=es&order=DESC&page=2"\n'
            ')\n'
            'codigo_pagina <- read_html(pagina)', 0.3, 1.7, 9.4, 1.75, size=14)
add_code(s, 'Error in open.connection(x, "rb") :\n'
            '  cannot open the connection', 0.3, 3.5, 9.4, 0.95, size=15,
         fill=SOFT_RED)
add_card(s, 0.3, 4.65, 4.65, 2.2, "Lo que vimos en RStudio",
         "La conexión no abrió, y R no mostró ningún código del servidor.",
         fill=SOFT_RED, title_color=DARK_RED, body_size=16)
add_card(s, 5.05, 4.65, 4.65, 2.2, "La pista que faltaba",
         "Desde curl, la misma URL respondió con el código 200 (éxito).",
         body_size=16)

# 5. Identificador -----------------------------------------------------------
s = nueva("El servidor rechaza al identificador de RStudio",
          "Se probaron distintos valores de User-Agent contra la misma URL. "
          "La palabra RStudio sola pasó, así que no conocemos la regla exacta. "
          "No fue exceso de peticiones: el identificador normal de R siguió "
          "funcionando entre las pruebas fallidas. Los identificadores de "
          "RStudio fueron simulados desde Rscript.",
          "El identificador (User-Agent) es el texto con el que el cliente "
          "se presenta.",
          "Fuente: pruebas propias contra gob.mx, 4 de noviembre de 2026, "
          "con identificadores simulados.")
filas = [["Identificador enviado", "Resultado"],
         ["R (4.6.1 ...)", "Funciona"],
         ["Mozilla/5.0", "Funciona"],
         ["RStudio", "Funciona"],
         ["RStudio Desktop", "403"],
         ["RStudio Desktop (2026.7.1.147); R (...)", "403"]]
col = {(i, 1): DARK_GREEN for i in (1, 2, 3)}
col.update({(i, 1): DARK_RED for i in (4, 5)})
add_table(s, filas, 0.3, 1.75, [7.4, 2.0], 0.55, mono_col=0, colores=col)
add_card(s, 0.3, 5.3, 9.4, 1.55, "Qué significa",
         "El código 403 indica que el servidor entendió la petición y se "
         "negó a atenderla. La regla exacta sigue sin conocerse.",
         fill=HIGHLIGHT_GREEN, title_color=DARK_GREEN)

# 6. Petición ----------------------------------------------------------------
s = nueva("Cada petición HTTP lleva datos que el servidor lee",
          "HTTP es el protocolo con el que clientes y servidores se comunican. "
          "req_dry_run muestra la petición sin enviarla, así que sirve para "
          "enseñar sin tocar el sitio. En httr2 1.3.0 esta salida omitió la "
          "parte ?idiom=es&order=DESC&page=2 de la URL.",
          "HTTP es el protocolo de la web; req_dry_run() muestra la petición "
          "sin enviarla.",
          "Fuente: salida de httr2 1.3.0.")
add_code(s, 'request(pagina) %>%\n'
            '  req_user_agent("Mozilla/5.0") %>%\n'
            '  req_dry_run()', 0.3, 1.75, 9.4, 1.15, size=14)
add_code(s, 'GET /presidencia/es/archivo/articulos HTTP/1.1\n'
            'accept: */*\n'
            'accept-encoding: deflate, gzip\n'
            'host: www.gob.mx\n'
            'user-agent: Mozilla/5.0', 0.3, 3.05, 9.4, 1.7, size=14,
         fill=LIGHT_BLUE)
add_card(s, 0.3, 4.95, 3.0, 1.95, "GET", "Este método pide un recurso al "
         "servidor.", body_size=14)
add_card(s, 3.43, 4.95, 3.0, 1.95, "host", "Este campo nombra el sitio que "
         "recibe la petición.", body_size=14)
add_card(s, 6.57, 4.95, 3.13, 1.95, "user-agent", "Este campo dice quién "
         "pregunta. Aquí estaba el problema.", fill=SOFT_RED,
         title_color=DARK_RED, body_size=14)

# 7. Cuatro pasos ------------------------------------------------------------
s = nueva("httr2 separa la petición en cuatro pasos",
          "read_html hace todo esto de golpe. httr2 lo separa y por eso "
          "permite intervenir en cada paso. Es como escribir una carta, "
          "firmarla, mandarla y abrir la contestación.",
          "read_html() hace todo junto; httr2 te deja intervenir en cada paso.")
pasos = [("request(url)", "Prepara la petición con la URL. Todavía no envía "
          "nada."),
         ("req_user_agent(...)", "Define el identificador con el que R se "
          "presenta."),
         ("req_perform()", "Envía la petición y recibe estado, encabezados "
          "y cuerpo."),
         ("resp_body_string()", "Saca el cuerpo de la respuesta como una "
          "cadena de texto.")]
for i, (f, t) in enumerate(pasos):
    y = 1.75 + i * 1.28
    add_rect(s, 0.3, y, 3.6, 1.12, NAVY)
    add_text(s, f, 0.42, y, 3.4, 1.12, size=14, color=WHITE, bold=True,
             font=MONO, anchor=MSO_ANCHOR.MIDDLE)
    add_rect(s, 3.9, y, 5.8, 1.12, LIGHT_BLUE)
    add_text(s, t, 4.06, y, 5.5, 1.12, size=15, anchor=MSO_ANCHOR.MIDDLE,
             spacing=1.1)

# 8. Error -------------------------------------------------------------------
s = nueva("Con httr2, el error ya dice qué pasó",
          "req_error con is_error que devuelve FALSE permite recibir la "
          "respuesta aunque sea un error, para inspeccionarla. Sirve para "
          "diagnosticar, no para dejarlo en un script de producción.",
          "El mismo rechazo se lee distinto en cada paquete.",
          "Fuente: pruebas propias con httr2 1.3.0 y rvest; 403 definido en "
          "RFC 9110.")
add_card(s, 0.3, 1.75, 4.65, 1.2, "read_html()", "", fill=SOFT_RED,
         title_color=DARK_RED)
add_text(s, "cannot open the connection", 0.44, 2.3, 4.4, 0.5, size=15,
         font=MONO)
add_card(s, 5.05, 1.75, 4.65, 1.2, "req_perform()", "", fill=SOFT_GREEN,
         title_color=DARK_GREEN)
add_text(s, "HTTP 403 Forbidden.", 5.19, 2.3, 4.4, 0.5, size=15, font=MONO)
add_code(s, 'respuesta <- request(pagina) %>%\n'
            '  req_user_agent(identificador_rstudio) %>%\n'
            '  req_error(is_error = function(resp) FALSE) %>%\n'
            '  req_perform()\n\n'
            'resp_status(respuesta)   # 403\n'
            'resp_status_desc(respuesta)   # "Forbidden"',
         0.3, 3.15, 9.4, 2.6, size=14)
add_text(s, "Un diagnóstico preciso evita buscar la falla en el lugar "
            "equivocado.", 0.4, 6.05, 9.2, 0.5, size=16)

# 9. JavaScript --------------------------------------------------------------
s = nueva("Una respuesta 200 no garantiza que sea HTML",
          "El listado de gob.mx se llena con JavaScript: la respuesta trae "
          "instrucciones para pegar HTML en la página. read_html no falla, "
          "pero los enlaces salen con diagonales y comillas de más. Por eso "
          "siempre conviene revisar Content-Type.",
          "Con el identificador resuelto apareció un segundo problema.",
          f"Fuente: gob.mx, {EXTRACCION}")
add_code(s, '<httr2_response>\n'
            'Status: 200 OK\n'
            'Content-Type: text/javascript\n'
            'Body: In memory (10863 bytes)', 0.3, 1.75, 9.4, 1.45, size=14,
         fill=LIGHT_BLUE)
add_code(s, "$('#prensa').append('<div class=\"row clearfix\n"
            "bottom-buffer\">  <div class=\\\"col-md-4\\\">\\n\n"
            "<article>\\n ...", 0.3, 3.35, 9.4, 1.3, size=14)
add_card(s, 0.3, 4.85, 4.65, 2.0, "Qué pasa con read_html()",
         "No marca error, pero los enlaces salen como \\\"/presidencia/...\\\" "
         "y los títulos traen basura.", fill=SOFT_RED, title_color=DARK_RED,
         body_size=14)
add_card(s, 5.05, 4.85, 4.65, 2.0, "Qué conviene revisar",
         "Content-Type dice qué trae el cuerpo, y resp_content_type() lo "
         "consulta en httr2.", body_size=14)

# 10. Limpieza ---------------------------------------------------------------
s = nueva("Tres reemplazos recuperan el HTML escondido",
          "En R, cuatro diagonales dentro de una cadena equivalen a una "
          "diagonal literal en la expresión regular: una capa de escape es "
          "de R y la otra de la expresión regular.",
          "resp_body_string() entrega el texto para limpiarlo antes de "
          "read_html().",
          f"Fuente: gob.mx, {EXTRACCION}")
add_table(s, [["En la respuesta", "Se convierte en"],
              ['\\"', '"'], ["\\/", "/"], ["\\n", "un espacio"]],
          0.3, 1.75, [4.7, 4.7], 0.45, mono_col=0)
add_code(s, 'html_pagina <- texto_pagina %>%\n'
            "  str_replace_all('\\\\\\\\\"', '\"') %>%\n"
            '  str_replace_all("\\\\\\\\/", "/") %>%\n'
            '  str_replace_all("\\\\\\\\n", " ") %>%\n'
            '  read_html()', 0.3, 3.75, 9.4, 1.75, size=14)
add_card(s, 0.3, 5.65, 9.4, 1.2, "Resultado",
         "Cada página del listado entregó 9 artículos con título, fecha y "
         "enlace limpios.", fill=HIGHLIGHT_GREEN, title_color=DARK_GREEN)

# 11. Pausas -----------------------------------------------------------------
s = nueva("Las pausas protegen al sitio y a tu acceso",
          "La Clase 16 sugirió Sys.sleep(2). El script usa 1 segundo. "
          "La cuenta: 25 páginas de listado más 100 conferencias son 125 "
          "peticiones, así que las pausas suman 125 segundos como mínimo.",
          "Un bucle sin pausas dispara peticiones tan rápido como puede.",
          "Fuente: scraping_sheinbaum.R.")
add_stat(s, "125", "peticiones en total:\n25 de listado y 100 de texto",
         0.3, 1.8, 4.65)
add_stat(s, "125 s", "de espera como mínimo,\ncon 1 segundo de pausa", 5.05,
         1.8, 4.65)
add_code(s, 'for (i in 1:nrow(tabla_conferencias)) {\n'
            '  # ... descargar y extraer el texto ...\n'
            '  Sys.sleep(1)\n'
            '}', 0.3, 3.75, 9.4, 1.5, size=14)
add_card(s, 0.3, 5.45, 9.4, 1.4, "Por qué importa",
         "El servidor atiende también a otras personas. Además, un ritmo "
         "agresivo puede provocar que el sitio bloquee tu dirección.",
         fill=HIGHLIGHT_GREEN, title_color=DARK_GREEN)

# 12. Filtro -----------------------------------------------------------------
s = nueva("Filtrar exige revisar lo que se descarta",
          "El listado mezcla giras y otros eventos. El primer patrón buscaba "
          "'conferencia de prensa de la presidenta' y encontró 102, no 103. "
          "El faltante apareció al revisar los títulos descartados que "
          "contenían la palabra conferencia.",
          "El listado mezcla conferencias con giras y otros eventos.",
          f"Fuente: gob.mx, páginas 1 a 25 del archivo, {EXTRACCION}")
add_stat(s, "225", "artículos revisados\nen 25 páginas", 0.3, 1.8, 3.0)
add_stat(s, "103", "títulos con\n\"conferencia de prensa\"", 3.43, 1.8, 3.0)
add_stat(s, "100", "conferencias más\nrecientes conservadas", 6.57, 1.8, 3.13,
         color=DARK_GREEN)
add_card(s, 0.3, 3.75, 9.4, 1.6, "Lo que falló en el primer intento",
         "El patrón largo dejó fuera este título: \"Conferencia de prensa "
         "matutina del 21 de agosto de 2026\".", fill=SOFT_RED,
         title_color=DARK_RED, body_size=15)
add_code(s, 'filter(str_detect(\n'
            '  titulo,\n'
            '  regex("conferencia de prensa", ignore_case = TRUE)\n'
            '))', 0.3, 5.55, 9.4, 1.35, size=13)

# 13. Validación -------------------------------------------------------------
s = nueva("Validar evita confiar en datos incompletos",
          "stopifnot detiene el script si algo no cuadra. La revisión de "
          "calendario es una validación adicional: los cuatro días faltantes "
          "parecen días sin conferencia, pero solo se comprobó que no "
          "aparecen en el listado.",
          "Un script que termina sin error todavía puede estar mal.",
          f"Fuente: gob.mx, {EXTRACCION}")
add_code(s, 'stopifnot(\n'
            '  nrow(tabla_final) == numero_conferencias,\n'
            '  !any(is.na(tabla_final$texto))\n'
            ')', 0.3, 1.75, 9.4, 1.5, size=14)
add_card(s, 0.3, 3.45, 3.0, 2.0, "100 filas", "El script reunió las "
         "conferencias pedidas.", fill=SOFT_GREEN, title_color=DARK_GREEN,
         body_size=15)
add_card(s, 3.43, 3.45, 3.0, 2.0, "0 textos vacíos", "Todas las conferencias "
         "traen su versión.", fill=SOFT_GREEN, title_color=DARK_GREEN,
         body_size=15)
add_card(s, 6.57, 3.45, 3.13, 2.0, "0 fechas repetidas", "Ninguna conferencia "
         "aparece dos veces.", fill=SOFT_GREEN, title_color=DARK_GREEN,
         body_size=15)
add_card(s, 0.3, 5.6, 9.4, 1.3, "Falta confirmar con otra fuente",
         "Cuatro días hábiles no aparecen: 1, 15 y 16 de septiembre y 2 de "
         "noviembre de 2026.", fill=SOFT_RED, title_color=DARK_RED, body_size=15)

# 14. Excel ------------------------------------------------------------------
s = nueva("Las 100 conferencias rebasan el límite de Excel",
          "Es la razón por la que este script guarda CSV y no xlsx. Un archivo "
          "CSV sí conserva el texto, pero abrirlo en Excel lo vuelve a cortar: "
          "hay que leerlo con read_csv. En el ejercicio de Atiempo el texto "
          "más largo mide cerca de 16 mil caracteres y por eso xlsx sí sirvió.",
          "Por eso el script guarda en CSV y se lee con read_csv().",
          "Fuente: gob.mx, cálculos propios. Límite: Microsoft (s. f.).")
s.shapes.add_picture(f"{IMG}/longitud_conferencias.png", I(0.4), I(1.7),
                     width=I(9.2))
add_text(s, "Atiempo sí cabe en xlsx: su texto más largo ronda 16 mil "
            "caracteres.", 0.4, 6.0, 9.2, 0.5, size=14)

# 15. Ética ------------------------------------------------------------------
s = nueva("Cambiar el identificador también tiene costo ético",
          "Hay que decirlo con claridad: al enviar Mozilla/5.0 esquivamos un "
          "filtro. No sabemos si es una decisión deliberada contra RStudio o "
          "una regla amplia. robots.txt no autoriza ni prohíbe por sí solo: "
          "RFC 9309 aclara que sus reglas no son una forma de autorización "
          "de acceso. Los términos de uso de gob.mx no se revisaron para "
          "preparar este material.",
          "La información es pública, pero el filtro lo puso el sitio.",
          "Fuente: gob.mx/robots.txt; Koster et al. (2022).")
add_card(s, 0.3, 1.75, 4.65, 2.3, "Lo que hicimos",
         "Enviamos otro identificador y con eso esquivamos un filtro del "
         "sitio.", fill=SOFT_RED, title_color=DARK_RED, body_size=16)
add_card(s, 5.05, 1.75, 4.65, 2.3, "Lo que no sabemos",
         "Desconocemos si el sitio quiso bloquear a RStudio o si la regla "
         "lo alcanza por accidente.", body_size=16)
add_card(s, 0.3, 4.2, 9.4, 2.7, "Lo que conviene revisar antes",
         "Revisa robots.txt: el de gob.mx solo menciona rastreadores de "
         "Google.\n"
         "Lee los términos de uso del sitio.\n"
         "Busca primero una API o datos abiertos oficiales.\n"
         "Detente si el sitio pide inicio de sesión o CAPTCHA (prueba contra "
         "robots).",
         fill=HIGHLIGHT_GREEN, title_color=DARK_GREEN, body_size=15)

# 16. Contraste con MercadoLibre ---------------------------------------------
s = nueva("MercadoLibre obliga a buscar otra vía",
          "Contraste con gob.mx. La URL de ejemplo fue "
          "autos.mercadolibre.com.mx/tesla/tesla_Desde_49_NoIndex_True. "
          "Su robots.txt veta esas dos rutas en el grupo general y además "
          "bloquea por completo a agentes de IA como ClaudeBot y GPTBot. "
          "No se hizo ninguna petición a la página de autos. La declaración "
          "contra la extracción viene de la versión argentina; los términos "
          "de México no se localizaron. La API responde 403 sin token, y la "
          "documentación oficial pide token en recursos públicos y privados. "
          "Fuentes de terceros reportan que la búsqueda general está "
          "restringida aun con token: es un dato sin confirmar.",
          "La misma pregunta técnica recibe otra respuesta en un sitio "
          "comercial.",
          "Fuente: robots.txt de ambos sitios, 4 de noviembre de 2026; "
          "Mercado Libre (s. f.-a, s. f.-b).")
add_table(s, [["Criterio", "gob.mx", "MercadoLibre"],
              ["robots.txt", "Solo menciona rastreadores de Google",
               "Veta a todos _Desde_ y _NoIndex_True"],
              ["Sitio", "Gobierno con información pública",
               "Comercio con anuncios de terceros"],
              ["Raspado", "Sin regla general en robots.txt",
               "Declara medidas para impedirlo"],
              ["API", "No se revisó",
               "Exige aplicación registrada y token"],
              ["Decisión", "Raspar con pausas",
               "No raspar: usar API o pedir permiso"]],
          0.3, 1.7, [1.6, 3.7, 4.1], 0.58, size=13,
          colores={(5, 1): DARK_GREEN, (5, 2): DARK_RED})
add_card(s, 0.3, 5.4, 9.4, 1.5, "Una API con token no garantiza los datos",
         "Fuentes de terceros reportan que la búsqueda general sigue "
         "restringida aun con token. Falta confirmarlo con una aplicación "
         "registrada.", fill=HIGHLIGHT_GREEN, title_color=DARK_GREEN,
         body_size=14)

# 17. Herramientas -----------------------------------------------------------
s = nueva("httr2 ya incluye pausas y reintentos",
          "Este código se probó con 25 páginas: tardó 24.5 segundos y todas "
          "respondieron 200. Cuidado: req_throttle usa un depósito de fichas "
          "que arranca lleno. Con capacity = 30 las primeras 30 peticiones "
          "salen sin pausa; se comprobó con 3 peticiones en 0.66 segundos. "
          "Por eso aquí capacity = 1.",
          "Estas funciones reemplazan el Sys.sleep() manual.",
          "Fuente: prueba propia con httr2 1.3.0, 4 de noviembre de 2026.")
add_code(s, 'respuesta <- request(url_base) %>%\n'
            '  req_url_query(idiom = "es", order = "DESC", page = k) %>%\n'
            '  req_user_agent("Mozilla/5.0") %>%\n'
            '  req_throttle(capacity = 1, fill_time_s = 1) %>%\n'
            '  req_retry(max_tries = 3) %>%\n'
            '  req_perform()', 0.3, 1.75, 9.4, 2.05, size=13.5)
add_card(s, 0.3, 4.0, 3.0, 2.85, "req_url_query()", "Arma los parámetros "
         "de la URL sin pegar cadenas a mano.", body_size=15)
add_card(s, 3.43, 4.0, 3.0, 2.85, "req_throttle()", "Limita el ritmo. Así, "
         "25 páginas tardaron 24.5 segundos.", body_size=15)
add_card(s, 6.57, 4.0, 3.13, 2.85, "req_retry()", "Repite la petición hasta "
         "tres veces si ocurre una falla pasajera.", body_size=15)

# 17. Resumen ----------------------------------------------------------------
s = nueva("Cada precaución evita un riesgo concreto",
          "Esta tabla responde la pregunta de por qué tomar precauciones. "
          "Cada renglón salió de un problema real del script.",
          "Las seis precauciones del script responden a seis riesgos.")
add_table(s, [["Precaución", "Riesgo que evita"],
              ["Fijar el identificador", "Recibir un rechazo 403"],
              ["Revisar Content-Type", "Extraer basura sin ver un error"],
              ["Pausar entre peticiones", "Saturar el sitio o perder acceso"],
              ["Auditar el filtro", "Perder registros en silencio"],
              ["Validar con stopifnot()", "Confiar en datos incompletos"],
              ["Guardar en CSV", "Cortar textos largos en Excel"]],
          0.3, 1.75, [4.5, 4.9], 0.68, size=14)

# 18. Recursos ---------------------------------------------------------------
s = nueva("Estas fuentes respaldan lo visto en la sesión",
          "Todas las referencias se comprobaron en línea el 4 de noviembre "
          "de 2026.")
refs = [
    ("Fielding, R., Nottingham, M., & Reschke, J. (Eds.). (2022). ",
     "HTTP semantics", " (RFC 9110). RFC Editor. "
     "https://www.rfc-editor.org/rfc/rfc9110"),
    ("Koster, M., Illyes, G., Zeller, H., & Sassman, L. (2022). ",
     "Robots Exclusion Protocol", " (RFC 9309). RFC Editor. "
     "https://www.rfc-editor.org/rfc/rfc9309"),
    ("Mercado Libre. (s. f.-a). ", "Autenticación y autorización",
     ". Mercado Libre Developers. https://developers.mercadolibre.com.ar/"
     "es_ar/autenticacion-y-autorizacion"),
    ("Mercado Libre. (s. f.-b). ",
     "¿Cómo pueden usar otros usuarios tus datos?",
     " https://www.mercadolibre.com.ar/privacidad/declaracion-privacidad/"
     "31256"),
    ("Microsoft. (s. f.). ", "Excel specifications and limits",
     ". Microsoft Support. https://support.microsoft.com/en-us/office/excel-"
     "specifications-and-limits-1672b34d-7043-467e-8e27-269d656771c3"),
    ("Wickham, H. (2025). ", "rvest: Easily harvest (scrape) web pages",
     " (versión 1.0.5) [Software]. https://CRAN.R-project.org/package=rvest"),
    ("Wickham, H. (2026). ",
     "httr2: Perform HTTP requests and process the responses",
     " (versión 1.3.0) [Software]. https://CRAN.R-project.org/package=httr2"),
]
caja = s.shapes.add_textbox(I(0.4), I(1.4), I(9.2), I(5.4))
tf = caja.text_frame
tf.word_wrap = True
for k, partes in enumerate(refs):
    p = tf.paragraphs[0] if k == 0 else tf.add_paragraph()
    p.line_spacing = 1.15
    p.space_after = Pt(10)
    for n, texto in enumerate(partes):
        run = p.add_run()
        run.text = texto
        run.font.size = Pt(13)
        run.font.name = UBUNTU
        run.font.italic = n == 1

# 19. Conclusiones -----------------------------------------------------------
s = nueva("Conclusiones: el raspado es también diagnóstico",
          "Dejar esta diapositiva visible durante las preguntas.")
add_rect(s, 0.3, 1.4, 9.4, 5.4, HIGHLIGHT_GREEN)
ideas = ["read_html() basta cuando el sitio entrega HTML y acepta tu "
         "petición.",
         "httr2 separa la petición y muestra por qué falló.",
         "Un código 200 no garantiza que recibiste el contenido esperado.",
         "Las pausas y las revisiones de términos protegen al sitio y a "
         "tu trabajo.",
         "Validar los datos y auditar los filtros detecta errores "
         "silenciosos."]
for i, idea in enumerate(ideas):
    y = 1.65 + i * 1.0
    add_text(s, str(i + 1), 0.55, y, 0.6, 0.8, size=30, bold=True,
             color=DARK_GREEN, anchor=MSO_ANCHOR.MIDDLE)
    add_text(s, idea, 1.2, y, 8.2, 0.8, size=17, anchor=MSO_ANCHOR.MIDDLE,
             spacing=1.1)

# 20. Cierre -----------------------------------------------------------------
s = prs.slides.add_slide(BLANK)
portada_base(s)
add_text(s, "Gracias", 0.6, 2.0, 8.8, 1.6, size=80, bold=True, color=NAVY,
         align=PP_ALIGN.CENTER)
add_rect(s, 3.0, 5.4, 4.0, 1.0, NAVY)
add_text(s, "¿Preguntas?", 3.0, 5.4, 4.0, 1.0, size=28, bold=True, color=WHITE,
         align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)

prs.save(OUT)
print(OUT, len(prs.slides))
