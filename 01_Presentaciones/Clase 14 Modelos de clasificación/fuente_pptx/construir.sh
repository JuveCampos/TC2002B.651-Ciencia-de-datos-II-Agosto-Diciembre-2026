#!/bin/zsh
# Regenera la presentación alterna de la Clase 14 de principio a fin:
# 1) modelo con tidymodels, 2) figuras, 3) deck, 4) PDF de verificación.
set -e
AQUI="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$AQUI/../../.." && pwd)"
SESION="$REPO/02_Codigo/Sesion_14_Clasificacion"
VERIFY="${1:-$AQUI/verify}"
mkdir -p "$VERIFY" "$AQUI/img"

cd "$SESION"
Rscript 02_modelo_tidymodels.R 01_datos/comentarios_etiquetados.xlsx
rm -f Rplots.pdf

cd "$AQUI"
python3 figuras.py "$SESION/03_resultados" \
  "$SESION/01_datos/comentarios_etiquetados.xlsx" "$AQUI/img"
python3 deck.py "$SESION/03_resultados" \
  "$SESION/01_datos/comentarios_etiquetados.xlsx" "$AQUI/img" \
  "$AQUI/../Clase14_alterna.pptx"

soffice --headless --convert-to pdf "$AQUI/../Clase14_alterna.pptx" \
  --outdir "$VERIFY" > /dev/null 2>&1
python3 -m markitdown "$AQUI/../Clase14_alterna.pptx" > "$VERIFY/texto.md"
echo "Listo: $AQUI/../Clase14_alterna.pptx"
