"""Figuras para la presentación alterna de la Clase 14 (paleta Tec).

Lee los CSV que exporta 02_modelo_tidymodels.R y el Excel etiquetado.
Uso:  python3 figuras.py <carpeta_resultados> <excel_etiquetado> <carpeta_img>
"""
import sys
import csv
from collections import Counter
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, FancyBboxPatch
import openpyxl

RES, XLSX, IMG = sys.argv[1], sys.argv[2], sys.argv[3]

mpl.rcParams['font.family'] = 'Ubuntu'
mpl.rcParams['axes.spines.top'] = False
mpl.rcParams['axes.spines.right'] = False
mpl.rcParams['axes.edgecolor'] = '#888888'
NAVY, DARK_RED, DARK_GREEN, GRAY = '#1E4C7D', '#C0392B', '#1A7A3A', '#555555'
LIGHT_BLUE, SOFT_RED, SOFT_GREEN = '#EAF2FA', '#FADBD8', '#D5F5E3'
DPI = 300


def leer_csv(nombre):
    with open(f"{RES}/{nombre}", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def guardar(fig, nombre):
    fig.savefig(f"{IMG}/{nombre}", dpi=DPI, bbox_inches='tight',
                facecolor='white')
    plt.close(fig)


# ---------- 1. Ofensivos por canal (Excel etiquetado) ----------
wb = openpyxl.load_workbook(XLSX, read_only=True)
ws = wb.active
filas = list(ws.iter_rows(values_only=True))
cab = filas[0]
it, ie = cab.index("canal"), cab.index("etiqueta_final")
por_tema = Counter((r[it], r[ie]) for r in filas[1:] if r[ie] is not None)
temas = sorted({t for t, _ in por_tema},
               key=lambda t: -sum(v for (tt, _), v in por_tema.items()
                                  if tt == t))
cats = ["Ofensivo", "No ofensivo"]
n_of = [por_tema.get((t, "Ofensivo"), 0) for t in temas]
n_no = [por_tema.get((t, "No ofensivo"), 0) for t in temas]
pct_of = [100 * o / (o + n) for o, n in zip(n_of, n_no)]

fig, ax = plt.subplots(figsize=(6.2, 4.2))
y = range(len(temas))
ax.barh(y, n_no, color=NAVY, height=0.55, label="No ofensivo")
ax.barh(y, n_of, left=n_no, color=DARK_RED, height=0.55, label="Ofensivo")
for i, (o, n, p) in enumerate(zip(n_of, n_no, pct_of)):
    ax.text(o + n + 8, i, f"{o + n:,} comentarios, {p:.0f} % ofensivos",
            va='center', fontsize=10.5, color=GRAY, fontweight='bold')
ax.set_yticks(list(y))
ax.set_yticklabels(temas, fontsize=12)
ax.invert_yaxis()
ax.set_xlim(0, max(o + n for o, n in zip(n_of, n_no)) * 1.75)
ax.set_xlabel("Comentarios", fontsize=11, color=NAVY, fontweight='bold')
ax.set_title("Comentarios etiquetados con Claude por canal de YouTube",
             fontsize=12.5, fontweight='bold', color=NAVY)
ax.legend(frameon=False, fontsize=10, loc='lower right')
guardar(fig, "fig_ofensivos_canal.png")

# ---------- 2. Balance de clases ----------
bal = leer_csv("balance_clases.csv")
fig, ax = plt.subplots(figsize=(6.2, 4.0))
etq = [b["etiqueta"] for b in bal]
n = [int(b["n"]) for b in bal]
colores = [DARK_RED if e == "Ofensivo" else NAVY for e in etq]
barras = ax.bar(etq, n, color=colores, width=0.55)
for b, v, p in zip(barras, n, [float(b["proporcion"]) for b in bal]):
    ax.text(b.get_x() + b.get_width() / 2, v + max(n) * 0.02,
            f"{v:,}  ({100 * p:.0f} %)", ha='center', fontsize=13,
            fontweight='bold', color=GRAY)
ax.set_ylabel("Comentarios etiquetados", fontsize=11, color=NAVY,
              fontweight='bold')
ax.set_title("Base completa: todos los comentarios etiquetados con Claude",
             fontsize=12, fontweight='bold', color=NAVY)
ax.set_ylim(0, max(n) * 1.18)
ax.tick_params(axis='x', labelsize=12)
guardar(fig, "fig_balance.png")

# ---------- 3. Matriz de confusión esquemática ----------
fig, ax = plt.subplots(figsize=(6.4, 4.8))
celdas = [("Verdadero positivo\n(VP)", SOFT_GREEN, DARK_GREEN,
           "ofensivo y el modelo\nlo detectó"),
          ("Falso negativo\n(FN)", SOFT_RED, DARK_RED,
           "ofensivo, pero el modelo\nlo dejó pasar"),
          ("Falso positivo\n(FP)", SOFT_RED, DARK_RED,
           "inofensivo, pero el modelo\nlo marcó"),
          ("Verdadero negativo\n(VN)", SOFT_GREEN, DARK_GREEN,
           "inofensivo y el modelo\nlo dejó pasar")]
pos = [(0, 1), (1, 1), (0, 0), (1, 0)]
for (x, y), (t, fc, tc, sub) in zip(pos, celdas):
    ax.add_patch(Rectangle((x, y), 1, 1, facecolor=fc, edgecolor='white',
                           linewidth=3))
    ax.text(x + 0.5, y + 0.66, t, ha='center', va='center', fontsize=12,
            fontweight='bold', color=tc)
    ax.text(x + 0.5, y + 0.3, sub, ha='center', va='center', fontsize=9.5,
            color=GRAY)
ax.set_xlim(0, 2); ax.set_ylim(0, 2)
ax.set_xticks([0.5, 1.5]); ax.set_xticklabels(["Ofensivo", "No ofensivo"],
                                               fontsize=12)
ax.set_yticks([1.5, 0.5]); ax.set_yticklabels(["Ofensivo", "No ofensivo"],
                                               fontsize=12)
ax.set_xlabel("El modelo predijo", fontsize=12, fontweight='bold', color=NAVY)
ax.set_ylabel("Etiqueta real", fontsize=12, fontweight='bold', color=NAVY)
for s in ax.spines.values():
    s.set_visible(False)
ax.tick_params(length=0)
guardar(fig, "fig_confusion_esquema.png")

# ---------- 4. Matriz de confusión real del bosque ----------
pred = leer_csv("predicciones_prueba.csv")
resumen = leer_csv("resumen.csv")[0]
for nombre_modelo, archivo in [("Bosque aleatorio", "fig_confusion_bosque.png"),
                               ("Regresión logística", "fig_confusion_logistica.png")]:
    sub = [p for p in pred if p["modelo"] == nombre_modelo]
    cnt = Counter((p["etiqueta"], p[".pred_class"]) for p in sub)
    m = [[cnt.get((r, c), 0) for c in cats] for r in cats]
    tot = sum(sum(r) for r in m)
    fig, ax = plt.subplots(figsize=(6.2, 4.6))
    for i in range(2):
        for j in range(2):
            color = SOFT_GREEN if i == j else SOFT_RED
            ax.add_patch(Rectangle((j, 1 - i), 1, 1, facecolor=color,
                                   edgecolor='white', linewidth=3))
            ax.text(j + 0.5, 1 - i + 0.55, f"{m[i][j]}", ha='center',
                    va='center', fontsize=26, fontweight='bold',
                    color=DARK_GREEN if i == j else DARK_RED)
            ax.text(j + 0.5, 1 - i + 0.22,
                    ["VP", "FN", "FP", "VN"][i * 2 + j], ha='center',
                    va='center', fontsize=11, color=GRAY)
    ax.set_xlim(0, 2); ax.set_ylim(0, 2)
    ax.set_xticks([0.5, 1.5]); ax.set_xticklabels(cats, fontsize=12)
    ax.set_yticks([1.5, 0.5]); ax.set_yticklabels(cats, fontsize=12)
    ax.set_xlabel("El modelo predijo", fontsize=12, fontweight='bold',
                  color=NAVY)
    ax.set_ylabel("Etiqueta real", fontsize=12, fontweight='bold', color=NAVY)
    exact = (m[0][0] + m[1][1]) / tot
    sens = m[0][0] / max(1, m[0][0] + m[0][1])
    ax.set_title(f"{nombre_modelo} en la base de prueba (n = {tot}): "
                 f"exactitud {100 * exact:.0f} %, sensibilidad {100 * sens:.0f} %",
                 fontsize=11.5, fontweight='bold', color=NAVY)
    for s in ax.spines.values():
        s.set_visible(False)
    ax.tick_params(length=0)
    guardar(fig, archivo)

# ---------- 5. Métricas comparadas ----------
met = leer_csv("metricas.csv")
orden = ["accuracy", "precision", "recall", "f_meas", "roc_auc"]
nombres = {"accuracy": "Exactitud", "precision": "Precisión",
           "recall": "Sensibilidad", "f_meas": "F1", "roc_auc": "AUC ROC"}
modelos = ["Regresión logística", "Bosque aleatorio"]
vals = {m: {r["metrica"]: float(r["valor"]) for r in met if r["modelo"] == m}
        for m in modelos}
mayoritaria = float(resumen["exactitud_mayoritaria"])
fig, ax = plt.subplots(figsize=(7.2, 4.3))
w = 0.36
for k, (m, c) in enumerate(zip(modelos, [NAVY, DARK_GREEN])):
    xs = [i + (k - 0.5) * w for i in range(len(orden))]
    ys = [vals[m][o] for o in orden]
    ax.bar(xs, ys, width=w, color=c, label=m)
    for x, y in zip(xs, ys):
        ax.text(x, y + 0.015, f"{100 * y:.0f}", ha='center', fontsize=9.5,
                color=GRAY)
ax.axhline(mayoritaria, color=DARK_RED, linestyle='--', linewidth=1.8,
           label=f"Siempre 'No ofensivo': {100 * mayoritaria:.0f} % de exactitud")
ax.set_xticks(range(len(orden)))
ax.set_xticklabels([nombres[o] for o in orden], fontsize=11)
ax.set_ylim(0, 1.08)
ax.set_ylabel("Valor en la base de prueba", fontsize=11, color=NAVY,
              fontweight='bold')
ax.set_title("Métricas de los dos modelos (clase positiva: Ofensivo)",
             fontsize=12.5, fontweight='bold', color=NAVY)
ax.legend(frameon=False, fontsize=9.5, loc='upper center', ncol=3,
          bbox_to_anchor=(0.5, 1.0))
ax.set_ylim(0, 1.2)
ax.grid(axis='y', alpha=0.25)
guardar(fig, "fig_metricas.png")

# ---------- 6. Curva ROC ----------
roc = leer_csv("curvas_roc.csv")
fig, ax = plt.subplots(figsize=(5.4, 5.0))
for m, c in zip(modelos, [NAVY, DARK_GREEN]):
    pts = [(1 - float(r["specificity"]), float(r["sensitivity"]))
           for r in roc if r["modelo"] == m]
    pts.sort()
    ax.plot([p[0] for p in pts], [p[1] for p in pts], color=c, linewidth=2.4,
            label=f"{m} (AUC {vals[m]['roc_auc']:.2f})")
ax.plot([0, 1], [0, 1], color=GRAY, linestyle='--', linewidth=1.2,
        label="Azar (AUC 0.50)")
ax.set_xlabel("1 - Especificidad (falsos positivos)", fontsize=11, color=NAVY,
              fontweight='bold')
ax.set_ylabel("Sensibilidad (ofensivos detectados)", fontsize=11, color=NAVY,
              fontweight='bold')
ax.set_title("Curva ROC en la base de prueba", fontsize=12.5,
             fontweight='bold', color=NAVY)
ax.legend(frameon=False, fontsize=9.5, loc='lower right')
ax.grid(alpha=0.25)
guardar(fig, "fig_roc.png")

# ---------- 7. Importancia de palabras (bosque) ----------
imp = leer_csv("importancia_bosque.csv")[:20]
fig, ax = plt.subplots(figsize=(6.6, 5.2))
pal = [r["palabra"] for r in imp][::-1]
val = [float(r["importancia"]) for r in imp][::-1]
ax.barh(pal, val, color=NAVY)
ax.set_xlabel("Importancia (reducción de impureza de Gini)", fontsize=11,
              color=NAVY, fontweight='bold')
ax.set_title("Las 20 palabras que más usa el bosque para decidir",
             fontsize=12.5, fontweight='bold', color=NAVY)
ax.tick_params(axis='y', labelsize=11)
ax.grid(axis='x', alpha=0.25)
guardar(fig, "fig_importancia.png")

# ---------- 8. Coeficientes de la logística ----------
coef = leer_csv("coeficientes_logistica.csv")
coef = [(r["palabra"], float(r["coeficiente"])) for r in coef]
top_pos = coef[:10]
top_neg = sorted(coef, key=lambda t: t[1])[:10]
sel = sorted(top_neg, key=lambda t: t[1]) + sorted(top_pos, key=lambda t: t[1])
fig, ax = plt.subplots(figsize=(6.6, 5.2))
ax.barh([s[0] for s in sel], [s[1] for s in sel],
        color=[DARK_RED if s[1] > 0 else DARK_GREEN for s in sel])
ax.axvline(0, color=GRAY, linewidth=1)
ax.set_xlabel("Coeficiente (positivo empuja hacia 'Ofensivo')", fontsize=11,
              color=NAVY, fontweight='bold')
ax.set_title("Regresión logística: palabras que más suben o bajan la "
             "probabilidad de ofensa", fontsize=11.5, fontweight='bold',
             color=NAVY)
ax.tick_params(axis='y', labelsize=11)
ax.grid(axis='x', alpha=0.25)
guardar(fig, "fig_coeficientes.png")

# ---------- 9. Árbol de decisión esquemático ----------
fig, ax = plt.subplots(figsize=(7.4, 4.6))
ax.set_xlim(0, 10); ax.set_ylim(0, 6); ax.axis('off')


def nodo(x, y, texto, fc, tc, w=2.6, h=0.9, fs=11):
    ax.add_patch(FancyBboxPatch((x - w / 2, y - h / 2), w, h,
                                boxstyle="round,pad=0.02,rounding_size=0.15",
                                facecolor=fc, edgecolor='white'))
    ax.text(x, y, texto, ha='center', va='center', fontsize=fs,
            fontweight='bold', color=tc)


def flecha(x1, y1, x2, y2, etiqueta):
    ax.annotate("", xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle='-|>', color=GRAY, lw=1.6))
    ax.text((x1 + x2) / 2 + (0.25 if x2 > x1 else -0.25), (y1 + y2) / 2,
            etiqueta, fontsize=10, color=GRAY, ha='center', va='center',
            fontweight='bold')


nodo(5, 5.3, "¿Aparece 'pinche'?", LIGHT_BLUE, NAVY)
nodo(2.3, 3.4, "Ofensivo", SOFT_RED, DARK_RED, w=2.0)
nodo(7.3, 3.4, "¿Aparece 'ignorante'?", LIGHT_BLUE, NAVY, w=3.0)
nodo(5.3, 1.4, "Ofensivo", SOFT_RED, DARK_RED, w=2.0)
nodo(9.0, 1.4, "No ofensivo", SOFT_GREEN, DARK_GREEN, w=2.0)
flecha(4.2, 4.85, 2.7, 3.85, "sí")
flecha(5.8, 4.85, 7.0, 3.85, "no")
flecha(6.7, 2.95, 5.6, 1.85, "sí")
flecha(7.9, 2.95, 8.8, 1.85, "no")
ax.text(0.2, 0.3, "Cada árbol del bosque ve una muestra distinta de "
        "comentarios y de palabras.\nEl bosque vota: gana la clase que "
        "predicen más árboles.", fontsize=10, color=GRAY, va='bottom')
guardar(fig, "fig_arbol.png")

# ---------- 10. Por qué la exactitud engaña ----------
fig, ax = plt.subplots(figsize=(7.0, 3.6))
n_prueba = int(resumen["n_prueba"])
n_no = round(mayoritaria * n_prueba)
n_of = n_prueba - n_no
ax.barh(["Modelo 'tonto':\nsiempre dice No ofensivo"], [n_no], color=NAVY)
ax.barh(["Modelo 'tonto':\nsiempre dice No ofensivo"], [n_of], left=[n_no],
        color=DARK_RED)
ax.text(n_no / 2, 0, f"{n_no} aciertos\n= {100 * mayoritaria:.0f} % de "
        f"exactitud", ha='center', va='center', color='white', fontsize=12,
        fontweight='bold')
ax.text(n_no + n_of / 2, 0, f"{n_of}\nofensivos\nsin detectar", ha='center',
        va='center', color='white', fontsize=10, fontweight='bold')
ax.set_xlabel(f"Comentarios en la base de prueba (n = {n_prueba})",
              fontsize=11, color=NAVY, fontweight='bold')
ax.set_title("Un modelo que no detecta ningún ofensivo ya tiene "
             f"{100 * mayoritaria:.0f} % de exactitud", fontsize=12.5,
             fontweight='bold', color=NAVY)
ax.tick_params(axis='y', labelsize=11)
guardar(fig, "fig_exactitud_engana.png")
print("Figuras listas en", IMG)
