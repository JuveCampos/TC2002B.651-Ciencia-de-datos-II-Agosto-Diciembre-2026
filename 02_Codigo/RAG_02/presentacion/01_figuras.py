"""Figuras de la presentación (paleta Tec, Ubuntu, 300 dpi). Todos los datos
vienen de datos/ y del índice del corpus; nada se inventa."""
import json, csv, datetime as dt
import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from matplotlib.ticker import FuncFormatter
MESES = {5: 'may', 6: 'jun', 7: 'jul', 8: 'ago', 9: 'sep'}
fmt_mes = FuncFormatter(lambda x, pos: f"{MESES[mdates.num2date(x).month]} 2026")
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Rectangle

mpl.rcParams['font.family'] = 'Ubuntu'
mpl.rcParams['axes.spines.top'] = False
mpl.rcParams['axes.spines.right'] = False
NAVY, DARK_RED, DARK_GREEN, GRAY = '#1E4C7D', '#C0392B', '#1A7A3A', '#555555'
LIGHT_BLUE, SOFT_BLUE, SOFT_RED, SOFT_GREEN = '#EAF2FA', '#DDE5ED', '#FADBD8', '#D5F5E3'
GOLD, SOFT_GOLD = '#C9A227', '#F6ECC8'
OUT = 'img_presentacion'
D = json.load(open('datos/datos_presentacion.json', encoding='utf-8'))
E = json.load(open('datos/esquema_fragmentacion.json', encoding='utf-8'))
indice = list(csv.DictReader(open('../mananeras/indice_mananeras.csv', encoding='utf-8')))
mananeras = [r for r in indice if r['descargado'] == 'TRUE']
fechas = sorted(dt.date.fromisoformat(r['fecha_conferencia']) for r in mananeras)
chars = {dt.date.fromisoformat(r['fecha_conferencia']): int(r['caracteres']) for r in mananeras}

def save(fig, name):
    fig.savefig(f'{OUT}/{name}.png', dpi=300, bbox_inches='tight', facecolor='white')
    plt.close(fig)

def box(ax, x, y, w, h, text, fc, ec=None, tc='black', size=11, bold=False, radius=0.06):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle=f'round,pad=0,rounding_size={radius}',
                                fc=fc, ec=ec or fc, lw=1.2))
    ax.text(x + w / 2, y + h / 2, text, ha='center', va='center', fontsize=size,
            color=tc, fontweight='bold' if bold else 'normal', wrap=True)

def arrow(ax, x1, y1, x2, y2, color=NAVY, label=None, lw=1.6, ls='-'):
    ax.add_patch(FancyArrowPatch((x1, y1), (x2, y2), arrowstyle='-|>', mutation_scale=14,
                                 color=color, lw=lw, linestyle=ls))
    if label:
        ax.text((x1 + x2) / 2, (y1 + y2) / 2 + 0.12, label, ha='center', va='bottom',
                fontsize=9, color=color)

# --- fig04: línea de tiempo: fecha de corte frente a mañaneras ---
fig, ax = plt.subplots(figsize=(9, 3.2))
x0, x1 = dt.date(2026, 5, 20), dt.date(2026, 9, 12)
ax.axvspan(dt.date(2026, 5, 31), x1, color=SOFT_RED, alpha=.6, zorder=0)
ax.text(dt.date(2026, 7, 20), 1.55, 'El modelo no leyó nada de esto:\n71 mañaneras posteriores a su entrenamiento',
        ha='center', va='center', fontsize=11, color=DARK_RED, fontweight='bold')
ax.scatter(fechas, [1] * len(fechas), s=28, color=NAVY, zorder=3)
ax.axvline(dt.date(2026, 9, 1), color=GRAY, ls=':', lw=1)
ax.annotate('1 de septiembre:\ninforme de gobierno,\nsin mañanera', (dt.date(2026, 9, 1), 1),
            (dt.date(2026, 8, 12), 0.45), fontsize=9, color=GRAY, ha='center',
            arrowprops=dict(arrowstyle='->', color=GRAY))
ax.annotate('Fecha de corte del modelo\n(meses o años antes, según el modelo)', (x0, 1),
            (dt.date(2026, 6, 6), 0.45), fontsize=9, color=NAVY, ha='center',
            arrowprops=dict(arrowstyle='->', color=NAVY))
ax.plot([x0, dt.date(2026, 5, 31)], [1, 1], color=NAVY, lw=3)
ax.text(x0, 1.15, '…', fontsize=16, color=NAVY, ha='left', va='bottom')
ax.set_xlim(x0, x1); ax.set_ylim(0.2, 1.9); ax.set_yticks([])
ax.xaxis.set_major_locator(mdates.MonthLocator()); ax.xaxis.set_major_formatter(fmt_mes)
ax.spines['left'].set_visible(False)
save(fig, 'fig04_linea_tiempo')

# --- fig07: flujo de RAG frente al camino sin RAG ---
fig, ax = plt.subplots(figsize=(9, 3.6)); ax.set_xlim(0, 10); ax.set_ylim(0, 4); ax.axis('off')
ax.text(0.2, 3.75, 'Con RAG', fontsize=12, fontweight='bold', color=DARK_GREEN)
box(ax, 0.2, 2.5, 1.6, 0.9, 'Pregunta', LIGHT_BLUE, NAVY, NAVY, 11, True)
box(ax, 2.5, 2.5, 2.0, 0.9, 'Búsqueda en\nel almacén', NAVY, NAVY, 'white', 11, True)
box(ax, 5.2, 2.5, 1.7, 0.9, '5 fragmentos\ncon fecha', SOFT_GOLD, GOLD, '#6B5210', 10, True)
box(ax, 7.6, 2.5, 2.2, 0.9, 'Respuesta\ncon cita', SOFT_GREEN, DARK_GREEN, DARK_GREEN, 11, True)
arrow(ax, 1.8, 2.95, 2.5, 2.95); arrow(ax, 4.5, 2.95, 5.2, 2.95); arrow(ax, 6.9, 2.95, 7.6, 2.95)
ax.text(4.85, 2.3, 'recupera', ha='center', fontsize=9, color=NAVY); ax.text(7.25, 2.3, 'el generador\nredacta', ha='center', va='top', fontsize=9, color=NAVY)
ax.text(0.2, 1.65, 'Sin RAG', fontsize=12, fontweight='bold', color=DARK_RED)
box(ax, 0.2, 0.4, 1.6, 0.9, 'Pregunta', LIGHT_BLUE, GRAY, GRAY, 11, True)
box(ax, 3.6, 0.4, 2.6, 0.9, 'Modelo responde\nde memoria', '#F0F0F0', GRAY, GRAY, 11, True)
box(ax, 7.6, 0.4, 2.2, 0.9, 'Respuesta\nsin fuente', SOFT_RED, DARK_RED, DARK_RED, 11, True)
arrow(ax, 1.8, 0.85, 3.6, 0.85, color=GRAY); arrow(ax, 6.2, 0.85, 7.6, 0.85, color=GRAY)
save(fig, 'fig07_flujo_rag')

# --- fig08: caracteres por mañanera ---
fig, ax = plt.subplots(figsize=(9, 3.4))
ax.bar(list(chars.keys()), [v / 1000 for v in chars.values()], width=0.8, color=NAVY)
ax.axvline(dt.date(2026, 9, 1), color=DARK_RED, ls='--', lw=1.2)
ax.annotate('1 de septiembre: informe de gobierno,\nsin mañanera', (dt.date(2026, 9, 1), 100),
            (dt.date(2026, 8, 8), 118), fontsize=9, color=DARK_RED, ha='center',
            arrowprops=dict(arrowstyle='->', color=DARK_RED))
prom = sum(chars.values()) / len(chars) / 1000
ax.axhline(prom, color=GRAY, lw=1, ls=':')
ax.set_ylabel('Miles de caracteres'); ax.set_ylim(0, 130)
ax.xaxis.set_major_locator(mdates.MonthLocator()); ax.xaxis.set_major_formatter(fmt_mes)
ax.set_title(f'{len(chars)} mañaneras, {sum(chars.values())/1e6:.1f} millones de caracteres en total (línea punteada: promedio de {prom:.0f} mil)', fontsize=11, color=NAVY, loc='left')
save(fig, 'fig08_corpus')

# --- fig09: regla de fragmentación (pasaje del 14 de julio) ---
N = E['n_caracteres']; f1, f2 = E['fragmentos']
starts = [1]; pos = 1
for p in E['pasaje']:
    pos += len(p) + 2; starts.append(pos)
fig, ax = plt.subplots(figsize=(9, 2.6)); ax.set_xlim(-20, N + 20); ax.set_ylim(0, 4.2); ax.axis('off')
ax.plot([1, N], [3.6, 3.6], color='black', lw=1)
for v in [1, 345, 574, N]:
    ax.plot([v, v], [3.5, 3.7], color='black', lw=1); ax.text(v, 3.85, str(v), ha='center', fontsize=10)
for k, s in enumerate(starts[1:4]):
    ax.plot([s, s], [3.52, 3.68], color=GRAY, lw=1); ax.text(s, 3.2, f'¶{k+2}', ha='center', fontsize=8, color=GRAY)
ax.add_patch(Rectangle((1, 2.0), 573, 0.7, fc=DARK_RED, ec='none'))
ax.text(12, 2.35, 'Fragmento 1 · posiciones 1 a 574', va='center', fontsize=10, color='white', fontweight='bold')
ax.add_patch(Rectangle((345, 0.9), N - 345, 0.7, fc=NAVY, ec='none'))
ax.text(N - 12, 1.25, 'Fragmento 2 · posiciones 345 a 860', va='center', ha='right', fontsize=10, color='white', fontweight='bold')
ax.add_patch(Rectangle((345, 0.9), 229, 1.8, fc='none', ec=GOLD, lw=2, hatch='///'))
ax.text((345 + 574) / 2, 0.35, 'traslape · 230 caracteres repetidos en los dos', ha='center', fontsize=10, color='#6B5210', fontweight='bold')
save(fig, 'fig09_fragmentacion')

# --- fig10: fragmentos por tamaño ---
fig, ax = plt.subplots(figsize=(6, 3.2))
c = D['conteo']; xs = [str(r['tamano']) for r in c]; ys = [r['fragmentos'] for r in c]
cols = [GRAY, NAVY, GRAY]
bars = ax.bar(xs, ys, color=cols, width=0.6)
for b, r in zip(bars, c):
    ax.text(b.get_x() + b.get_width() / 2, b.get_height() + 60, f"{r['fragmentos']:,}\n({r['por_mananera']:.0f} por mañanera)", ha='center', fontsize=10)
ax.set_xlabel('Tamaño objetivo del fragmento (caracteres)'); ax.set_ylabel('Fragmentos'); ax.set_ylim(0, 4400)
ax.set_title('26 mañaneras, traslape de 25 %', fontsize=11, color=NAVY, loc='left')
save(fig, 'fig10_tamanos')

# --- fig11: vectores de los dos fragmentos ---
fig, ax = plt.subplots(figsize=(9, 3.0)); ax.set_xlim(0, 10); ax.set_ylim(0, 3.2); ax.axis('off')
for i, (fr, col, x) in enumerate([(f1, DARK_RED, 0.2), (f2, NAVY, 5.2)]):
    ax.add_patch(Rectangle((x, 0.2), 4.6, 2.8, fc='white', ec=col, lw=2))
    ax.text(x + 0.2, 2.7, f'Fragmento {i+1} · {fr["n"]} caracteres', fontsize=10, fontweight='bold', color=col)
    ax.text(x + 0.2, 2.3, '"' + fr['texto'].strip()[:48].replace('\n', ' ') + '…"', fontsize=8.5, color=GRAY, style='italic')
    ax.text(x + 0.2, 1.95, 'bge-m3 lo convierte en:', fontsize=9, color=col)
    ini = '  '.join(f'{v:+.4f}' for v in fr['emb_inicio'][:5]) + '\n' + '  '.join(f'{v:+.4f}' for v in fr['emb_inicio'][5:])
    fin = '  '.join(f'{v:+.4f}' for v in fr['emb_fin'][:5]) + '\n' + '  '.join(f'{v:+.4f}' for v in fr['emb_fin'][5:])
    ax.text(x + 0.2, 1.35, ini, fontsize=8, family='monospace', va='center')
    ax.text(x + 0.2, 0.85, f'… {fr["dim"] - 20:,} números más …', fontsize=8.5, color=GRAY)
    ax.text(x + 0.2, 0.45, fin, fontsize=8, family='monospace', va='center')
save(fig, 'fig11_vectores')

# --- fig12: proyección 2D de los 1,824 fragmentos ---
rows = list(csv.DictReader(open('datos/proyeccion_2d.csv', encoding='utf-8')))
fig, ax = plt.subplots(figsize=(8.5, 4.6))
colores = {'seguridad': DARK_RED, 'vivienda': DARK_GREEN, 'comercio': GOLD, 'salud': '#7B3F9E', 'tren': NAVY}
otros = [r for r in rows if r['tema'] == 'otros']
ax.scatter([float(r['pc1']) for r in otros], [float(r['pc2']) for r in otros], s=6, color='#C8CCD0', label=f'otros temas ({len(otros)})')
for t, col in colores.items():
    sub = [r for r in rows if r['tema'] == t]
    ax.scatter([float(r['pc1']) for r in sub], [float(r['pc2']) for r in sub], s=10, color=col, label=f'{t} ({len(sub)})', alpha=.85)
ax.legend(fontsize=9, frameon=False, loc='upper left', bbox_to_anchor=(1.01, 1), title='Tema (por palabras clave)', title_fontsize=9)
ax.set_xlabel('Componente principal 1'); ax.set_ylabel('Componente principal 2'); ax.set_xticks([]); ax.set_yticks([])
ax.set_title('1,824 fragmentos de 1,024 dimensiones proyectados a dos', fontsize=11, color=NAVY, loc='left')
save(fig, 'fig12_proyeccion')

# --- fig13: esquema de la tabla del almacén ---
fig, ax = plt.subplots(figsize=(9, 2.4)); ax.axis('off')
cols = ['origin', 'chunk_id', 'start', 'end', 'fecha', 'titulo', 'url', 'embedding', 'text']
filas = [['2026-09-08_…txt', '1', '1', '1601', '2026-09-08', 'Versión estenográfica…', 'gob.mx/…', '[−0.021, 0.007, … ×1024]', 'PRESIDENTA DE MÉXICO…'],
         ['2026-09-08_…txt', '2', '1202', '2803', '2026-09-08', 'Versión estenográfica…', 'gob.mx/…', '[0.002, −0.022, … ×1024]', 'Hoy es el informe de…'],
         ['…', '…', '…', '…', '…', '…', '…', '…', '…'],
         ['2026-08-03_…txt', '1824', '…', '…', '2026-08-03', 'Versión estenográfica…', 'gob.mx/…', '[…]', '…']]
t = ax.table(cellText=filas, colLabels=cols, loc='center', cellLoc='left', colLoc='left')
t.auto_set_font_size(False); t.set_fontsize(8.5); t.scale(1, 1.5)
for (r, c_), cell in t.get_celld().items():
    cell.set_edgecolor('#D6DAD5')
    if r == 0: cell.set_facecolor(NAVY); cell.set_text_props(color='white', fontweight='bold')
    elif c_ in (4, 5, 6): cell.set_facecolor(SOFT_GOLD)
    elif c_ == 7: cell.set_facecolor(LIGHT_BLUE)
t.auto_set_column_width(list(range(len(cols))))
ax.text(0, 0.02, 'Amarillo: metadatos que se filtran y se citan · Azul: el vector con el que se busca', fontsize=9, color=GRAY, transform=ax.transAxes)
save(fig, 'fig13_almacen')

# --- fig14: tres métodos, misma pregunta ---
fig, axs = plt.subplots(1, 3, figsize=(10, 3.2))
titulos = {'semantica': ('Semántica (distancia coseno)', 'metric_value'), 'lexica': ('Léxica BM25 (puntaje)', 'metric_value'), 'hibrida': ('Híbrida: 5 recuperados, 3 tras fusionar vecinos', None)}
for ax, (k, (tt, mk)) in zip(axs, titulos.items()):
    ax.axis('off'); ax.set_xlim(0, 1); ax.set_ylim(0, 1)
    ax.text(0, 0.97, tt, fontsize=10.5, fontweight='bold', color=NAVY, va='top')
    for i, r in enumerate(D['metodos'][k]):
        y = 0.82 - i * 0.16
        met = f"{r['metric_value']:.2f}" if mk else ('cos ' + f"{r['cosine_distance']:.2f}" if 'cosine_distance' in r else '') + (' · bm25 ' + f"{r['bm25']:.1f}" if 'bm25' in r else '')
        ax.text(0, y, f"{r['fecha'][5:]}  {met}", fontsize=9, fontweight='bold', color='black', va='top')
        ax.text(0, y - 0.065, r['inicio'][:38] + '…', fontsize=7.8, color=GRAY, va='top')
fig.suptitle('Pregunta: ¿Cuál fue el promedio diario de homicidios dolosos en agosto de 2026?', fontsize=10.5, color='black', x=0.02, ha='left')
save(fig, 'fig14_metodos')

# --- fig15: con filtro y sin filtro ---
fig, axs = plt.subplots(1, 2, figsize=(10, 3.4))
for ax, (k, tt, col) in zip(axs, [('sin_filtro', 'Sin filtro: fechas de todo el corpus', DARK_RED), ('con_filtro', 'Con filtro del 1 al 7 de septiembre', DARK_GREEN)]):
    ax.axis('off'); ax.set_xlim(0, 1); ax.set_ylim(0, 1)
    ax.text(0, 0.97, tt, fontsize=10.5, fontweight='bold', color=col, va='top')
    for i, r in enumerate(D['filtro'][k][:6]):
        y = 0.84 - i * 0.14
        ax.text(0, y, f"{r['fecha']}", fontsize=9, fontweight='bold', va='top')
        ax.text(0, y - 0.06, r['inicio'][:58] + '…', fontsize=7.5, color=GRAY, va='top')
fig.suptitle('Consulta: "aranceles a países sin tratado de libre comercio"', fontsize=10.5, x=0.02, ha='left')
save(fig, 'fig15_filtro')

# --- fig18: ciclo con herramienta ---
fig, ax = plt.subplots(figsize=(9, 3.3)); ax.set_xlim(0, 10); ax.set_ylim(0, 3.6); ax.axis('off')
box(ax, 0.2, 1.3, 1.6, 0.9, 'Pregunta', LIGHT_BLUE, NAVY, NAVY, 11, True)
box(ax, 2.6, 1.3, 2.4, 0.9, 'Modelo generador\nformula una consulta', NAVY, NAVY, 'white', 10.5, True)
box(ax, 6.0, 1.3, 2.0, 0.9, 'Herramienta\nbuscar_mananeras', SOFT_GOLD, GOLD, '#6B5210', 10, True)
box(ax, 2.6, 0.1, 2.4, 0.8, 'Modelo redacta\ncon cita', SOFT_GREEN, DARK_GREEN, DARK_GREEN, 10.5, True)
arrow(ax, 1.8, 1.75, 2.6, 1.75)
arrow(ax, 5.0, 1.95, 6.0, 1.95)
ax.text(5.5, 2.35, 'consulta: "pasajeros Tren Maya"', ha='center', va='bottom', fontsize=9, color=NAVY)
arrow(ax, 6.0, 1.5, 5.0, 1.5, color=GOLD, label=None)
ax.text(5.1, 1.22, 'devuelve 3 fragmentos con fecha (texto plano)', ha='left', va='top', fontsize=9, color='#6B5210')
arrow(ax, 3.8, 1.3, 3.8, 0.9, color=DARK_GREEN)
ax.text(8.3, 1.75, 'el modelo decide\ncuándo buscar y\ncuántas veces', fontsize=9.5, color=NAVY, va='center')
ax.text(0.2, 3.3, 'Variante con herramienta: la búsqueda deja de ser un paso fijo y se vuelve una función que el modelo invoca', fontsize=10, color='black')
save(fig, 'fig18_herramienta')

# --- fig20: tabla de evaluación ---
fig, ax = plt.subplots(figsize=(9.6, 3.6)); ax.axis('off')
ev = D['evaluacion']
filas = [[r['pregunta'][:70] + ('…' if len(r['pregunta']) > 70 else ''), r['fecha_esperada'], 'Sí' if r['semantica'] else 'No', 'Sí' if r['lexica'] else 'No', 'Sí' if r['hibrida'] else 'No'] for r in ev]
h = lambda k: f"{100*sum(r[k] for r in ev)/len(ev):.0f} %"
filas.append(['hit@5', '', h('semantica'), h('lexica'), h('hibrida')])
t = ax.table(cellText=filas, colLabels=['Pregunta', 'Mañanera esperada', 'Semántica', 'Léxica', 'Híbrida'], loc='center', cellLoc='center', colLoc='center')
t.auto_set_font_size(False); t.set_fontsize(9); t.scale(1, 1.45)
for (r, c_), cell in t.get_celld().items():
    cell.set_edgecolor('#D6DAD5')
    if c_ == 0: cell.set_text_props(ha='left'); cell._loc = 'left'
    if r == 0: cell.set_facecolor(NAVY); cell.set_text_props(color='white', fontweight='bold')
    elif r == len(filas): cell.set_facecolor(SOFT_GREEN); cell.set_text_props(fontweight='bold', color=DARK_GREEN)
    elif c_ >= 2: cell.set_text_props(color=DARK_GREEN, fontweight='bold')
t.auto_set_column_width([0, 1, 2, 3, 4])
save(fig, 'fig20_evaluacion')
print('figuras listas')
