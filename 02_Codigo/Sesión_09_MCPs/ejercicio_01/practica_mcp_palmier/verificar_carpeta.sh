#!/usr/bin/env bash
# Comprueba que la carpeta se pueda subir a GitHub:
#   - ningún archivo rebasa los 100 MB (límite duro de GitHub)
#   - avisa de archivos de más de 50 MB (GitHub emite advertencia)
#   - no hay .DS_Store ni respaldos .bak
#   - reporta el peso total
set -euo pipefail
cd "$(dirname "$0")"

echo "== Archivos de más de 100 MB (bloquean el push) =="
find . -type f -size +100M -not -path './.git/*' || true
echo
echo "== Archivos de más de 50 MB (GitHub advierte) =="
find . -type f -size +50M -not -path './.git/*' || true
echo
echo "== Basura que no debe viajar =="
find . \( -name .DS_Store -o -name '*.bak' \) -not -path './.git/*' || true
echo
echo "== Peso por carpeta =="
du -sh ./*/ 2>/dev/null | sort -h
echo
echo "== Peso total =="
du -sh . | cut -f1
echo
echo "== Videos =="
for f in $(find . -name '*.mp4' -not -path './.git/*' | sort); do
  info=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height,r_frame_rate \
    -show_entries format=duration,size -of csv=p=0 "$f" | tr '\n' ',')
  echo "$f  ->  $info"
done
