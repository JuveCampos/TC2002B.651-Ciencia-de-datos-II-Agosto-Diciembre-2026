"""Re-segmenta la transcripcion por palabra en cues de subtitulo de dos lineas.

Toma el CSV de palabras con tiempos que produce la transcripcion y escribe un
SRT donde ningun cue se desborda a una tercera linea. El corte se decide
midiendo el ancho real del texto con la tipografia con la que se va a rendir,
no contando caracteres: una M mide casi el triple que una i, asi que un limite
por numero de caracteres deja pasar lineas que si se desbordan.

Uso:
    python3 resegmentar_subtitulos.py palabras_con_duracion.csv salida.srt
    python3 resegmentar_subtitulos.py entrada.csv salida.srt --max-px 515
    python3 resegmentar_subtitulos.py entrada.csv salida.srt \
        --fuente /ruta/a/Fuente.ttf --tamano 48

El CSV de entrada usa punto y coma como separador y necesita las columnas
n_bloque, palabra, inicio_s y fin_s.
"""

import argparse
import csv
import itertools
import os
import sys

from PIL import ImageFont

UBUNTU = os.path.expanduser("~/Library/Fonts/Ubuntu-Regular.ttf")


def construir_argumentos():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("entrada", help="CSV de palabras con tiempos")
    p.add_argument("salida", help="SRT a escribir")
    p.add_argument("--fuente", default=UBUNTU,
                   help="archivo de la tipografia con la que se rinden los subtitulos")
    p.add_argument("--tamano", type=int, default=48,
                   help="tamano en puntos con el que se miden las lineas")
    p.add_argument("--max-px", type=float, default=515,
                   help="ancho maximo de una linea, medido con esa tipografia")
    p.add_argument("--min-dur", type=float, default=0.8,
                   help="por debajo de esta duracion el cue se considera parpadeo")
    p.add_argument("--min-pantalla", type=float, default=0.7,
                   help="duracion minima a la que se estira un cue corto")
    return p.parse_args()


def main():
    args = construir_argumentos()
    try:
        fuente = ImageFont.truetype(args.fuente, args.tamano)
    except OSError:
        sys.exit(f"No se pudo abrir la tipografia: {args.fuente}")

    def ancho(texto):
        return fuente.getlength(texto)

    def partir(texto):
        """Devuelve el texto en una o dos lineas, o None si no cabe en dos."""
        if ancho(texto) <= args.max_px:
            return texto
        palabras = texto.split()
        mejor, dif_min = None, float("inf")
        for i in range(1, len(palabras)):
            a, b = " ".join(palabras[:i]), " ".join(palabras[i:])
            if ancho(a) > args.max_px or ancho(b) > args.max_px:
                continue
            if abs(ancho(a) - ancho(b)) < dif_min:
                mejor, dif_min = a + "\n" + b, abs(ancho(a) - ancho(b))
        return mejor

    def texto_de(cue):
        return " ".join(p["palabra"] for p in cue)

    def dur_de(cue):
        return float(cue[-1]["fin_s"]) - float(cue[0]["inicio_s"])

    with open(args.entrada, encoding="utf-8") as fh:
        filas = list(csv.DictReader(fh, delimiter=";"))
    faltan = {"n_bloque", "palabra", "inicio_s", "fin_s"} - set(filas[0])
    if faltan:
        sys.exit(f"Al CSV le faltan columnas: {', '.join(sorted(faltan))}")

    # Se acumula palabra por palabra sin cruzar el bloque original de la
    # transcripcion, y se corta en cuanto el cue deja de caber en dos lineas
    cues = []
    for _, grupo in itertools.groupby(filas, key=lambda f: f["n_bloque"]):
        actual = []
        for f in grupo:
            if actual and partir(texto_de(actual + [f])) is None:
                cues.append(actual)
                actual = [f]
            else:
                actual = actual + [f]
        if actual:
            cues.append(actual)

    # Los cues muy breves parpadean. Se fusionan primero con el anterior y
    # despues con el siguiente, siempre que el resultado siga cabiendo
    fusionados = []
    for cue in cues:
        if fusionados and dur_de(cue) < args.min_dur:
            unido = fusionados[-1] + cue
            if partir(texto_de(unido)) is not None:
                fusionados[-1] = unido
                continue
        fusionados.append(cue)
    cues = fusionados

    fusionados, i = [], 0
    while i < len(cues):
        cue = cues[i]
        if dur_de(cue) < args.min_dur and i + 1 < len(cues):
            unido = cue + cues[i + 1]
            if partir(texto_de(unido)) is not None:
                fusionados.append(unido)
                i += 2
                continue
        fusionados.append(cue)
        i += 1
    cues = fusionados

    # Lo que sigue corto se estira hacia el hueco del siguiente, sin invadirlo
    tiempos = [[float(c[0]["inicio_s"]), float(c[-1]["fin_s"])] for c in cues]
    for i, t in enumerate(tiempos):
        if t[1] - t[0] >= args.min_pantalla:
            continue
        tope = tiempos[i + 1][0] if i + 1 < len(tiempos) else t[1] + args.min_pantalla
        t[1] = min(tope, t[0] + args.min_pantalla)

    def hms(seg):
        h, m = int(seg // 3600), int(seg % 3600 // 60)
        return f"{h:02d}:{m:02d}:{seg % 60:06.3f}".replace(".", ",")

    bloques = []
    for n, cue in enumerate(cues, start=1):
        inicio, fin = tiempos[n - 1]
        bloques.append(f"{n}\n{hms(inicio)} --> {hms(fin)}\n{partir(texto_de(cue))}\n")
    with open(args.salida, "w", encoding="utf-8") as fh:
        fh.write("\n".join(bloques))

    lineas = [l for c in cues for l in partir(texto_de(c)).split("\n")]
    duraciones = sorted(b - a for a, b in tiempos)
    solapes = sum(1 for i in range(len(tiempos) - 1)
                  if tiempos[i][1] > tiempos[i + 1][0])
    print(f"cues escritos: {len(cues)}")
    print(f"linea mas ancha: {max(ancho(l) for l in lineas):.0f} px "
          f"de {args.max_px:.0f} permitidos")
    print(f"cues de mas de dos lineas: "
          f"{sum(1 for c in cues if partir(texto_de(c)).count(chr(10)) > 1)}")
    print(f"duracion minima: {duraciones[0]:.2f} s | media: "
          f"{sum(duraciones)/len(duraciones):.2f} s")
    print(f"cues por debajo de 0.6 s: {sum(1 for d in duraciones if d < 0.6)}")
    print(f"solapes entre cues: {solapes}")


if __name__ == "__main__":
    main()
