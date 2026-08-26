# AGENTS.md — TC2002B.651 Ciencia de Datos II

## Qué es este repositorio

Materiales del curso **Ciencia de Datos II** (Tecnológico de Monterrey, periodo agosto–diciembre 2026). No es una aplicación desplegable ni un paquete de software: es un repositorio de contenido didáctico (presentaciones, ejercicios de código, bases de datos de ejemplo).

No hay pipeline de CI/CD, tests automatizados ni scripts de build.

---

## Estructura y convenciones

### Directorios principales

- `01_Presentaciones/` — Diapositivas en PDF. Los archivos fuente `.key` (Keynote) están en `.gitignore`; **no subas** los `.key`, solo los PDFs exportados.
- `02_Codigo/` — Sesiones de clase (`Sesion_XX_Nombre/`). Cada sesión contiene carpetas `ejercicio_XX/` con código, datos y enunciados.
- `assets/` — Imágenes del README y del repositorio.

### Archivos `.zip` en `02_Codigo/`

Cada sesión comprimida (`Sesion_XX.zip`) es una **instantánea de distribución** para los alumnos. El directorio descomprimido (`Sesion_XX/`) es la copia de trabajo editable.

- Si modificas archivos dentro de una sesión, **actualiza también el `.zip` correspondiente** (sobrescribir) o documenta en el mensaje de commit que el zip quedó desfasado.
- No crees zips nuevos sin necesidad; el patractual es uno por sesión.

### Datos y artefactos

Los ejercicios incluyen bases de datos reales o de ejemplo:

- CSV, XLSX, GeoJSON, SQLite `.db`, archivos RDS.

**Trátalos como insumos, no como artefactos de build.** No los agregues a `.gitignore` ni los borres a menos que el ejercicio lo indique explícitamente.

### Archivos `SKILL.md`

Algunos ejercicios (p. ej. `simulador-de-calificacion/`) contienen copias locales de definiciones de *skills* de OpenCode. Son especificaciones de comportamiento, no código ejecutable. **No los modifiques** salvo que se te pida explícitamente actualizar el skill.

---

## Lenguajes y estilo

- **R 4.4+** es el lenguaje principal. Estilo tidyverse (`%>%`, `dplyr`, `ggplot2`) como se ve en `00_preparar_insumos.R`.
- Ocasionalmente hay Python (scripts auxiliares) o HTML (ejercicios de vibe-coding).
- No hay configuración de linter ni formateador en el repo. Sigue la consistencia del código existente.

---

## Git

- `.DS_Store` ya está presente en varias carpetas y **no está en `.gitignore`**. No añadas nuevos `.DS_Store`, pero tampoco los borres masivamente para evitar ruido en los diffs.
- `.gitignore` actual solo excluye archivos `.key` específicos de presentaciones. Si agregas nuevas categorías de archivos ignorables (p. ej. `.Rhistory`, `renv/`), actualiza `.gitignore` en el mismo commit.

---

## Verificación manual

Como no hay tests, la forma de validar un cambio es:

1. **R**: correr el script o el chunk de código en RStudio / Positron.
2. **Shiny / Leaflet**: ejecutar la app y revisar visualmente que el mapa o la tabla carguen.
3. **Datos**: si modificas un script que genera insumos (como `00_preparar_insumos.R`), comparar las dimensiones y las primeras filas del output contra la versión anterior.

---

## Referencias

- `README.md` — Temario, criterios de evaluación, política de uso de IA y libros de referencia.
- Archivos `README.md` dentro de ejercicios específicos (p. ej. `ejercicio_04/insumos_alianza_ganadora/README.md`) contienen el diccionario de datos y el enunciado del reto.
