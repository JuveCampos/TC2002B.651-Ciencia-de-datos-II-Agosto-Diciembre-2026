"""Construye la presentación HTML autocontenida a partir de plantilla.html.

Inyecta en la plantilla los datos reales exportados del modelo de
analisis_resenas.R (carpeta datos/) y el logo en base64. Se ejecuta desde
la carpeta construccion/:  python3 construir.py
"""
import base64
import json
from pathlib import Path

aqui = Path(__file__).resolve().parent
datos = aqui / "datos"

def leer(nombre):
    return json.loads((datos / nombre).read_text(encoding="utf-8"))

# Diccionario con todo lo que usa el JavaScript de la presentación
D = {
    "pred": leer("pred_prueba.json"),       # p = P(positiva), y = 1 si positiva
    "cv": leer("cv.json"),                  # métricas medias por penalización
    "pliegues": leer("pliegues.json"),      # métricas por pliegue (penalización 0.01)
    "ruta": leer("ruta_coef.json"),         # trayectoria de coeficientes glmnet
    "errores": leer("errores.json"),        # errores más confiados en prueba
    "acc_categoria": leer("acc_categoria.json"),
    "coef_top": leer("coef_top.json"),
    "resumen": leer("resumen.json"),        # tokens con peso, vocabulario, métricas
}

logo = "data:image/png;base64," + base64.b64encode((datos / "logo_tec.png").read_bytes()).decode("ascii")

plantilla = (aqui / "plantilla.html").read_text(encoding="utf-8")
html = plantilla.replace("__DATOS__", json.dumps(D, ensure_ascii=False, separators=(",", ":")))
html = html.replace("__LOGO__", logo)

salida = aqui.parent / "Sesion_15_metricas_y_validacion_cruzada.html"
salida.write_text(html, encoding="utf-8")
print("Escrito", salida, f"({salida.stat().st_size / 1024:.0f} KB)")
