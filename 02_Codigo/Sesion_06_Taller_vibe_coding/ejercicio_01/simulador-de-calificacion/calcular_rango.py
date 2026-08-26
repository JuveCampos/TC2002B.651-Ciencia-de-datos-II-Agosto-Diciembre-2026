#!/usr/bin/env python3
"""Calcula los tres escenarios de calificación a partir de los requisitos.

Uso: se edita la lista RUBRICA con los requisitos ya calificados y se ejecuta
    python3 calcular_rango.py

Cada requisito lleva: peso dentro del criterio, nivel de cumplimiento (0 a 1) y
tipo de verificación ('D' directo, 'J' de juicio, 'N' no verificable).
"""

INCERTIDUMBRE = {"D": 0.05, "J": 0.20, "N": 0.35}

# (nombre_criterio, puntos_maximos, [(id, peso, nivel, tipo), ...])
RUBRICA = [
    ("01 Conceptos", 20, [
        ("1.1", 0.40, 1.00, "D"),
        ("1.2", 0.20, 0.75, "D"),
        ("1.3", 0.20, 0.45, "D"),
        ("1.4", 0.10, 1.00, "D"),
        ("1.5", 0.10, 1.00, "N"),
    ]),
]


def recortar(valor):
    return max(0.0, min(1.0, valor))


def puntos(maximo, requisitos, desplazamiento):
    total = 0.0
    for _, peso, nivel, tipo in requisitos:
        u = INCERTIDUMBRE[tipo] * desplazamiento
        total += peso * recortar(nivel + u)
    return maximo * total


print(f"{'Criterio':<22}{'Máx':>6}{'Consv':>9}{'Central':>9}{'Optim':>9}")
gran_total = [0.0, 0.0, 0.0]
for nombre, maximo, requisitos in RUBRICA:
    fila = [puntos(maximo, requisitos, d) for d in (-1, 0, 1)]
    gran_total = [a + b for a, b in zip(gran_total, fila)]
    print(f"{nombre:<22}{maximo:>6}{fila[0]:>9.1f}{fila[1]:>9.1f}{fila[2]:>9.1f}")

suma_maximos = sum(m for _, m, _ in RUBRICA)
print(f"{'TOTAL':<22}{suma_maximos:>6}"
      f"{gran_total[0]:>9.1f}{gran_total[1]:>9.1f}{gran_total[2]:>9.1f}")
