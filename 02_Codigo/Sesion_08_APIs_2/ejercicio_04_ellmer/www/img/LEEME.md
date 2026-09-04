# Imágenes de la app

La app funciona sin imágenes: dibuja un cielo estrellado en SVG y usa los
glifos tipográficos del zodiaco. Si colocas aquí los archivos con estos
nombres exactos, `app.R` los detecta al arrancar y los usa en lugar de los
respaldos. Hay que reiniciar la app después de agregarlos.

| Archivo | Uso | Sugerencia |
|---|---|---|
| `fondo.jpg` | Fondo de toda la página, se repite en mosaico | Cielo nocturno o textura oscura, 1600 × 1000 px aprox., que se pueda repetir sin costura |
| `banner.png` | Ilustración sobre el título principal | Luna, astrolabio o mapa celeste con fondo transparente, máximo 180 px de alto |
| `signos/aries.png` … `signos/piscis.png` | Ícono de cada signo en la franja superior y al centro de la rueda | PNG cuadrado con fondo transparente, 200 × 200 px o más |

Nombres válidos para la carpeta `signos/` (sin acentos, en minúsculas):

```
aries, tauro, geminis, cancer, leo, virgo,
libra, escorpio, sagitario, capricornio, acuario, piscis
```

Si solo colocas algunos íconos, los demás signos seguirán usando su glifo.
