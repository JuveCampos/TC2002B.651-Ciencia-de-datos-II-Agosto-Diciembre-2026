# Servidor MCP de INEGI en R

Un mismo servidor, cuatro agentes. Lo único que cambia es dónde se registra.
Sustituye `/ruta/absoluta/servidor_inegi.R` por la ruta real en tu máquina.
Los formatos de configuración cambian seguido: si algo falla, revisa la
documentación del agente antes de tocar el código R.

## Antes de empezar

```r
install.packages(c("mcptools", "ellmer", "tidyverse", "inegiR"))
```

En `~/.Renviron` (`usethis::edit_r_environ()` lo abre):

```
INEGI_TOKEN=tu_token_aquí
```

Comprueba que `Rscript` responde desde la terminal (no desde RStudio):

```bash
Rscript --version
```

Prueba primero sin agente, desde R, que las funciones responden. Comenta la
llamada a `mcp_server()` al final del script antes de hacer `source()`, porque
esa línea bloquea la sesión:

```r
source("servidor_inegi.R")
consultar_inegi("746097", "Oaxaca")
comparar("738545", c("Nuevo León", "Jalisco", "Chiapas"))
```

En todos los bloques de abajo, `args` (o `command`) apunta al archivo **`.R`**,
no al archivo de configuración. Si el agente reporta un error de R como
`unexpected ','`, casi seguro le pasaste el JSON en lugar del script.

## Claude Code

```bash
claude mcp add inegi -- Rscript /ruta/absoluta/servidor_inegi.R
```

o en `.mcp.json` del proyecto:

```json
{
  "mcpServers": {
    "inegi": {
      "command": "Rscript",
      "args": ["/ruta/absoluta/servidor_inegi.R"]
    }
  }
}
```

## Codex

En `~/.codex/config.toml`:

```toml
[mcp_servers.inegi]
command = "Rscript"
args = ["/ruta/absoluta/servidor_inegi.R"]
```

## OpenCode

OpenCode no crea ningún archivo de configuración por sí mismo: lo busca, y si
no existe usa valores por defecto. **Tienes que crearlo tú.** Dos opciones:

- Para un solo proyecto: crea `opencode.json` en la raíz de la carpeta del
  proyecto (desde la terminal, `touch opencode.json`, o como archivo nuevo en
  RStudio con ese nombre exacto).
- Para todos los proyectos: crea la carpeta y el archivo con
  `mkdir -p ~/.config/opencode && touch ~/.config/opencode/opencode.json`.

A diferencia de los demás agentes, la sección se llama `mcp` (no
`mcpServers`) y el ejecutable y sus argumentos van juntos en una sola lista
bajo `command`. Pega esto dentro del archivo:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "inegi": {
      "type": "local",
      "command": ["Rscript", "/ruta/absoluta/servidor_inegi.R"],
      "enabled": true
    }
  }
}
```

`"type": "local"` indica que OpenCode lanza el proceso y le habla por stdio;
`"remote"` con una `url` sería para servidores que ya están corriendo.

Guarda el archivo y reinicia `opencode` desde la carpeta del proyecto: la
configuración se lee solo al arrancar. En el inicio muestra qué servidores
MCP cargó; si `inegi` no aparece, revisa que el JSON no tenga comas de más y
que la ruta a `servidor_inegi.R` sea absoluta.

## Antigravity CLI (`agy`)

Google retiró Gemini CLI en junio de 2026; su sucesor es Antigravity CLI
(`agy`). A diferencia de Gemini CLI, los servidores MCP van en un archivo
dedicado, no en `settings.json`.

Configuración global, en `~/.gemini/config/mcp_config.json`
(instalaciones anteriores a la migración usan
`~/.gemini/antigravity-cli/mcp_config.json`):

```json
{
  "mcpServers": {
    "inegi": {
      "command": "Rscript",
      "args": ["/ruta/absoluta/servidor_inegi.R"]
    }
  }
}
```

Para alcance de proyecto, el mismo bloque en `.agents/mcp_config.json`
dentro de la carpeta de trabajo. Reinicia `agy` después de editar y usa
`/mcp` dentro de la sesión para ver si el servidor cargó.

## En Windows

Si `Rscript` no está en el PATH, sustituye `"Rscript"` por la ruta completa,
por ejemplo `"C:\\Program Files\\R\\R-4.5.1\\bin\\Rscript.exe"`.

## Prompts de prueba, del simple al compuesto

1. "¿Qué indicadores de INEGI tienes disponibles?"
   (una llamada: `listar_indicadores`)
2. "¿Cuál es el PIB de Oaxaca?"
   (dos llamadas: primero lista, luego consulta)
3. "Compara la actividad industrial entre Nuevo León, Jalisco y Chiapas y dime cuál va peor."
   (lista + comparar, y el modelo interpreta)
4. "¿Qué estado del norte recauda más impuestos?"
   (el modelo decide qué estados son 'del norte' antes de llamar)
5. "¿Es comparable el dato de PIB con el de actividad industrial?"
   (obliga al modelo a leer la periodicidad: anual contra mensual)

## Qué observar en clase

- Corran el mismo prompt en dos agentes distintos y comparen qué tools
  eligieron y en qué orden.
- Borren la descripción de una tool y repitan. El agente deja de usarla
  bien: la descripción es parte del código.
- Cambien una tool en el script sin reiniciar el agente. No la va a ver:
  la lista de tools se pide una sola vez al arrancar.
- Pregunten algo fuera del catálogo ("¿cuánta gente vive en Yucatán?") y
  vean cómo reacciona cada agente al no tener la tool.
