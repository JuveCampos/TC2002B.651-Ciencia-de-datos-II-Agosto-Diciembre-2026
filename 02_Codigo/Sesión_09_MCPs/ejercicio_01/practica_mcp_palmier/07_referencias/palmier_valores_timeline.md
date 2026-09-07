# Armado del timeline en Palmier

Referencia de la Fase 2. Los valores de transformación son coordenadas
normalizadas del lienzo (0 a 1), no píxeles, y están calculados para un
lienzo de 1080x1920.

## Antes de empezar

El MCP de Palmier se registra **por carpeta**, no en el ámbito global, así
que al abrir la carpeta de un video nuevo las herramientas no aparecen
aunque la aplicación esté corriendo:

```
claude mcp add --scope local --transport http palmier-pro http://127.0.0.1:19789/mcp
```

Después hay que reiniciar Claude Code, porque las herramientas MCP se cargan
al arrancar la sesión.

## Trampa del lienzo

`manage_project` con `aspectRatio: "9:16"` y `quality: "1080p"` crea el
proyecto en 1080x1920, pero **al colocar el primer clip Palmier reajusta el
lienzo a la resolución de ese clip** y lo baja a 1280x720. Hay que volver a
fijarlo justo después:

```
set_project_settings(width=1080, height=1920)
```

Conviene verificarlo con `get_timeline` antes de calcular cualquier
transformación, porque todas dependen del tamaño del lienzo.

## Orden de pistas

El índice 0 se dibuja encima. Si se colocan los clips de abajo hacia arriba y
se omite `trackIndex`, Palmier crea cada pista nueva sobre las anteriores y el
orden sale solo:

| Pista | Nombre | Contenido |
|---|---|---|
| V6 | Subtitulos | los cues del SRT |
| V5 | Outro | el clip institucional |
| V4 | Badges | el badge del día |
| V3 | Graficas | las gráficas a pantalla completa |
| V2 | Fondo | copias del video base con desenfoque |
| V1 | Main | el video base recortado |
| A1 | Dialogue | el audio del video base |
| A2 | Extras | los audios duplicados y el del cierre |

Las copias del video base que van a la pista Fondo arrastran su audio
vinculado. Hay que silenciarlo poniendo `volumeDb: -60` a cada `audio.id`
anidado, **no** silenciando la pista entera, porque en esa misma pista de
audio termina cayendo el sonido del clip institucional.

## Transformaciones

**Video base.** El recorte central 9:16 de una toma de 1280x720 se logra con
un solo valor, sin mover el centro:

```
transform: {centerX: 0.5, centerY: 0.5, width: 3.1605, height: 1}
```

Equivale a tomar los 405x720 px centrales y escalarlos 2.67x. Se le aplica
`blur.sharpen` con `amount: 0.35` para compensar la blandura del escalado.

**Fondo desenfocado.** Es el mismo clip con la misma transformación, más
`blur.gaussian` con `radius: 32`. Se coloca solo en los tramos donde hay
gráfica. Conviene unir los tramos contiguos en un solo clip.

**Gráficas 16:9.** A 1000 px de ancho, centradas en y = 910:

```
transform: {centerX: 0.5, centerY: 0.474, width: 0.9259, height: 0.293}
```

Para una imagen que no sea 16:9, se conserva el ancho y se recalcula el alto:
`height = (1000 * alto_original / ancho_original) / 1920`.

**Badges.** Los archivos de calendario no comparten proporción entre sí, así
que se fija el ancho en 360 px y se deja el alto proporcional a cada archivo,
siempre con el borde superior en y = 40:

```
width = 0.3333
centerX = 0.2037
height = (360 * alto / ancho) / 1920
centerY = (40 + (360 * alto / ancho) / 2) / 1920
```

**Subtítulos.** Se colocan con `add_captions` pasando `subtitleMediaRef`, que
toma los tiempos del SRT sin retranscribir. Ese parámetro no admite ningún
otro, así que la posición y el estilo se aplican después con `update_text`:

```
transform: {x: 0.5, y: 0.794}
style: {fontName: "Ubuntu-Regular",
        shadow: {enabled: true, color: "#000000", opacity: 0.65,
                 blur: 12, offset: {x: 0, y: 3}}}
animation: "highlightBlock"
highlightColor: "#6B4FD7"
```

La sombra hace falta porque el blanco liso pierde contraste sobre el fondo
desenfocado claro.

## Fundidos

El fundido de 0.3 s son 9 cuadros a 30 fps, con interpolación `smooth`. Va
solo al entrar y salir de cada **bloque** de gráficas. Entre dos gráficas
contiguas se usa corte seco: si se les pone fundido a todas quedan 0.6 s de
fondo desenfocado sin gráfica y se ve como un error.

Las capas de fondo llevan fundido de entrada y salida siempre, para que el
desenfoque aparezca como disolvencia y no como corte.

El clip de cierre se solapa 0.3 s con la toma a cámara y lleva fundido de
entrada de 9 cuadros, tanto en la imagen como en su audio anidado. Si
arrancara justo donde termina el video base, esos cuadros fundirían desde
negro en vez de cruzar desde la imagen.

## Probar sin tocar el trabajo

Para ensayar un cambio de estilo o una animación conviene duplicar la línea
de tiempo con `create_timeline(from=...)`, probar ahí, volver con
`set_active_timeline` y borrar la copia con `organize_media(deletes=[...])`.
La duplicación renombra todos los identificadores de clip y de pista, así que
hay que releer `get_timeline` después de cambiar de línea de tiempo.
