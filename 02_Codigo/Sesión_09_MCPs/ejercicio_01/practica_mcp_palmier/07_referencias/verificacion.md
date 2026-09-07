# Verificación antes de dar por bueno un reel

Ningún reel se declara listo sin haber cerrado al menos un ciclo de revisión
y corrección. Estos son los pasos, en orden.

## 1. Revisar la composición dentro de Palmier

`inspect_timeline` devuelve el cuadro compuesto, con transformaciones,
opacidad y subtítulos ya aplicados, y de paso lista qué clips se ven en
pantalla. Sirve para revisar sin esperar un render de tres minutos.

Conviene mirar, como mínimo:

- un cuadro de cada bloque de gráficas, para confirmar encuadre y fundidos;
- el cuadro del cue de subtítulo más ancho, que es donde se desborda a una
  tercera línea si el cálculo quedó corto;
- la entrada del clip institucional, para confirmar que el fundido cruza
  desde la imagen y no desde negro.

Para localizar los cues más anchos se mide el SRT con la misma tipografía y
se ordenan de mayor a menor; se revisan los primeros.

## 2. Revisar el archivo exportado, no solo la vista previa

La vista previa de Palmier y el archivo final se generan por caminos
distintos. Después de exportar, se extraen cuadros con ffmpeg y se miran:

```
ffmpeg -v error -ss 48 -i salida.mp4 -frames:v 1 -vf scale=360:-1 f_48.jpg -y
```

Se comprueba también que el contenedor traiga lo esperado:

```
ffprobe -v error -show_entries stream=codec_name,width,height,r_frame_rate,channels \
  -show_entries format=duration -of default=nw=1 salida.mp4
```

Debe reportar 1080x1920, 30 fps y una pista de audio con dos canales.

## 3. Qué buscar en los cuadros

- Los subtítulos no deben pasar de dos líneas ni invadir la zona baja.
- El texto claro sobre fondo claro debe conservar contraste.
- Ninguna gráfica debe quedar por debajo de 2.5 s en pantalla.
- El badge del día debe corresponder al día del que se está hablando.
- Las capturas de pantalla, si se usan, deben leerse a la escala en que se
  muestran; una captura densa de tablero se vuelve ilegible en vertical.

## 4. Revisar el audio

```
ffmpeg -hide_banner -i salida.mp4 -af volumedetect -f null /dev/null 2>&1 | grep volume
```

El pico no debe rebasar los -1 dB. La media suele quedar baja porque incluye
los silencios; lo que importa es que no haya recorte.

## 5. Reportar antes de declarar listo

Al entregar hay que decir cuántos problemas se detectaron, qué se corrigió y
qué quedó pendiente de decisión. Una desviación respecto del plan aprobado se
reporta siempre, aunque haya mejorado el resultado, y se escribe en el
`PLAN_EDICION.md` de esa semana.
