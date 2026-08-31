# Genera los esquemas de la Clase 11 con la paleta Tec (Ubuntu, 300 DPI).
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Circle

mpl.rcParams['font.family'] = 'Ubuntu'
mpl.rcParams['axes.spines.top'] = False
mpl.rcParams['axes.spines.right'] = False
mpl.rcParams['axes.edgecolor'] = '#888888'

NAVY = '#1E4C7D'
LIGHT_BLUE = '#EAF2FA'
SOFT_BLUE = '#DDE5ED'
SOFT_GREEN = '#D5F5E3'
SOFT_RED = '#FADBD8'
DARK_RED = '#C0392B'
DARK_GREEN = '#1A7A3A'
GRAY = '#555555'
MID_BLUE = '#7FA7CC'
AMBER = '#F5CBA7'
DARK_AMBER = '#B9770E'
DPI = 300


def nodo(ax, x, y, w, h, texto, fc, tc=NAVY, fs=11):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.12",
                                facecolor=fc, edgecolor=NAVY, linewidth=1.3))
    ax.text(x + w / 2, y + h / 2, texto, ha='center', va='center',
            fontsize=fs, fontweight='bold', color=tc, linespacing=1.3)


def linea(ax, x1, y1, x2, y2):
    ax.plot([x1, x2], [y1, y2], color=NAVY, linewidth=1.6, zorder=1)


def flecha(ax, x1, y1, x2, y2, color=NAVY):
    ax.add_patch(FancyArrowPatch((x1, y1), (x2, y2),
                                 arrowstyle='-|>', mutation_scale=22,
                                 linewidth=2.0, color=color))


# --- 1. Arbol de etiquetas HTML ---
fig, ax = plt.subplots(figsize=(9.2, 5.4), dpi=DPI)
ax.set_xlim(0, 20)
ax.set_ylim(0, 12)
ax.axis('off')

# Nivel 0
nodo(ax, 8.6, 10.2, 2.8, 1.3, "<html>", NAVY, tc='white', fs=13)
# Nivel 1
nodo(ax, 3.4, 7.6, 3.0, 1.2, "<head>", SOFT_BLUE, fs=12)
nodo(ax, 12.6, 7.6, 3.0, 1.2, "<body>", SOFT_BLUE, fs=12)
linea(ax, 10.0, 10.2, 4.9, 8.8)
linea(ax, 10.0, 10.2, 14.1, 8.8)
# Nivel 2 bajo head
nodo(ax, 2.9, 5.0, 4.0, 1.2, "<title>", LIGHT_BLUE, fs=11)
linea(ax, 4.9, 7.6, 4.9, 6.2)
# Nivel 2 bajo body
nodo(ax, 8.4, 5.0, 3.2, 1.2, "<h1>", LIGHT_BLUE, fs=11)
nodo(ax, 12.4, 5.0, 3.2, 1.2, "<table>", SOFT_GREEN, tc=DARK_GREEN, fs=11)
nodo(ax, 16.4, 5.0, 3.3, 1.2, '<div\nclass="nota">', LIGHT_BLUE, fs=9.5)
linea(ax, 14.1, 7.6, 10.0, 6.2)
linea(ax, 14.1, 7.6, 14.0, 6.2)
linea(ax, 14.1, 7.6, 18.0, 6.2)
# Nivel 3
nodo(ax, 10.7, 2.4, 2.6, 1.2, "<tr> <td>", SOFT_GREEN, tc=DARK_GREEN, fs=10)
nodo(ax, 14.2, 2.4, 2.4, 1.2, "<p>", LIGHT_BLUE, fs=11)
nodo(ax, 17.2, 2.4, 2.6, 1.2, "<a href=...>", LIGHT_BLUE, fs=9.5)
linea(ax, 14.0, 5.0, 12.0, 3.6)
linea(ax, 18.0, 5.0, 15.4, 3.6)
linea(ax, 18.0, 5.0, 18.5, 3.6)

# Anotaciones
ax.text(1.0, 10.7, "La raíz: todo el\ndocumento", fontsize=10, color=GRAY,
        style='italic', linespacing=1.3)
ax.text(0.6, 3.1, "<head>: metadatos\n(no se ven en la página)",
        fontsize=10, color=GRAY, style='italic', linespacing=1.3)
ax.text(7.9, 3.1, "las tablas ya vienen\nestructuradas: oro puro",
        fontsize=10, color=DARK_GREEN, style='italic', linespacing=1.3,
        ha='center')
ax.set_title("Una página web es un árbol: el scraping navega sus ramas",
             fontsize=14, fontweight='bold', color=NAVY, pad=12)
plt.tight_layout()
plt.savefig("img/arbol_html.png", bbox_inches='tight', facecolor='white')
plt.close()

# --- 2. Flujo rvest ---
fig, ax = plt.subplots(figsize=(9.4, 3.8), dpi=DPI)
ax.set_xlim(0, 24)
ax.set_ylim(0, 8)
ax.axis('off')

pasos = [
    (0.4, "URL de la\npágina", LIGHT_BLUE, NAVY),
    (5.35, "read_html()\ndescarga el árbol", SOFT_BLUE, NAVY),
    (10.3, "html_elements()\nselecciona ramas", SOFT_BLUE, NAVY),
    (15.25, "html_text2() o\nhtml_table()", SOFT_BLUE, NAVY),
    (20.2, "tibble listo\npara tidyverse", SOFT_GREEN, DARK_GREEN),
]
for x, texto, fc, tc in pasos:
    ax.add_patch(FancyBboxPatch((x, 3.0), 3.4, 2.6,
                                boxstyle="round,pad=0.15",
                                facecolor=fc, edgecolor=NAVY, linewidth=1.4))
    ax.text(x + 1.7, 4.3, texto, ha='center', va='center', fontsize=10.5,
            fontweight='bold', color=tc, linespacing=1.4)
for x in [4.0, 8.95, 13.9, 18.85]:
    flecha(ax, x, 4.3, x + 1.15, 4.3)

ax.text(7.05, 1.9, 'con cortesía:\nSys.sleep(2) entre páginas',
        ha='center', fontsize=9.5, color=DARK_RED, style='italic',
        linespacing=1.3)
ax.text(12.0, 1.9, 'aquí entra el selector:\n"table", ".nota", "#titulo"',
        ha='center', fontsize=9.5, color=GRAY, style='italic',
        linespacing=1.3)
ax.text(21.9, 1.9, 'de aquí en adelante:\nfilter(), mutate(), count()',
        ha='center', fontsize=9.5, color=GRAY, style='italic',
        linespacing=1.3)
ax.text(12, 7.3, "Cinco pasos: del HTML crudo al tibble ordenado",
        ha='center', fontsize=13.5, fontweight='bold', color=NAVY)
plt.tight_layout()
plt.savefig("img/flujo_rvest.png", bbox_inches='tight', facecolor='white')
plt.close()

# --- 3. Semaforo etico del scraping ---
fig, ax = plt.subplots(figsize=(9.2, 5.0), dpi=DPI)
ax.set_xlim(0, 20)
ax.set_ylim(0, 11)
ax.axis('off')

franjas = [
    (7.4, SOFT_GREEN, DARK_GREEN, "Adelante",
     "Hay datos abiertos o API oficial; robots.txt lo permite;\n"
     "el sitio es público y se scrapea despacio, identificándose"),
    (4.0, AMBER, DARK_AMBER, "Con cuidado",
     "HTML público sin API; términos de uso ambiguos;\n"
     "volumen alto: leer robots.txt, espaciar solicitudes, citar la fuente"),
    (0.6, SOFT_RED, DARK_RED, "Alto",
     "Datos personales sin base legal; contenido tras contraseña\n"
     "o muro de pago; evadir bloqueos; ignorar un 'no' explícito del sitio"),
]
for y, fc, tc, titulo, cuerpo in franjas:
    ax.add_patch(FancyBboxPatch((0.5, y), 19.0, 2.9,
                                boxstyle="round,pad=0.12", facecolor=fc,
                                edgecolor=tc, linewidth=1.6))
    ax.add_patch(Circle((2.2, y + 1.45), 0.85, facecolor=tc,
                        edgecolor='white', linewidth=2.5, zorder=3))
    ax.text(4.0, y + 1.45, titulo, fontsize=15, fontweight='bold',
            color=tc, va='center')
    ax.text(8.3, y + 1.45, cuerpo, fontsize=10.5, color='black',
            va='center', linespacing=1.45)
ax.set_title("Tres niveles de riesgo que se evalúan antes de correr el script",
             fontsize=13.5, fontweight='bold', color=NAVY, pad=12)
plt.tight_layout()
plt.savefig("img/semaforo_etico.png", bbox_inches='tight',
            facecolor='white')
plt.close()

# --- 4. Rastreo vs visitas referidas (crawl-to-refer) ---
etiquetas = ["Google\n(búsqueda)", "PerplexityBot", "GPTBot\n(OpenAI)",
             "ClaudeBot\n(Anthropic)"]
razones = [4.9, 111, 1276, 11122]
colores = [DARK_GREEN, MID_BLUE, NAVY, DARK_RED]
fig, ax = plt.subplots(figsize=(8.8, 4.4), dpi=DPI)
y = np.arange(len(etiquetas))[::-1]
ax.barh(y, razones, color=colores, height=0.6, alpha=0.92)
ax.set_xscale('log')
ax.set_xlim(1, 300000)
ax.set_yticks(y)
ax.set_yticklabels(etiquetas, fontsize=11)
for yi, r in zip(y, razones):
    etiqueta = f"{r:,.0f} : 1" if r >= 10 else f"{r:.1f} : 1"
    ax.text(r * 1.35, yi, etiqueta, va='center', fontsize=11,
            fontweight='bold', color=NAVY)
ax.set_xlabel("Páginas rastreadas por cada visita humana referida (escala log)",
              fontsize=10.5, fontweight='bold', color=NAVY)
ax.set_title("Los bots de IA leen miles de páginas por cada visita\nque devuelven a los sitios (2026)",
             fontsize=12.5, fontweight='bold', color=NAVY, pad=10)
ax.grid(axis='x', alpha=0.25)
plt.tight_layout()
plt.savefig("img/rastreo_referencias.png", bbox_inches='tight',
            facecolor='white')
plt.close()

print("Imagenes de la clase 11 generadas")
