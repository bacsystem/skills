#!/usr/bin/env bash
# Enlaza o instala la carpeta agents/ de este repositorio en las carpetas globales de agentes:
# - Claude Code: ~/.claude/agents (enlace simbólico directo)
# - Gemini / Antigravity: ~/.gemini/config/agents/<nombre>/agent.md (frontmatter adaptado)
# En Windows usa scripts/instalar-agentes.ps1: Git Bash no crea enlaces simbólicos reales.
#
# Uso:
#   scripts/instalar-agentes.sh [--all | --claude | --gemini]
#   scripts/instalar-agentes.sh [destino_personalizado]
#
# Si no se pasa argumento, por defecto instala para ambos (--all).
# Si el destino ya existe y no es este enlace, se renombra a <destino>.respaldo-<fecha>
# antes de enlazar: nada se borra.
set -euo pipefail

case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*)
    echo "En Windows ejecuta: powershell -ExecutionPolicy Bypass -File scripts/instalar-agentes.ps1" >&2
    exit 1
    ;;
esac

origen="$(cd "$(dirname "$0")/.." && pwd -P)/agents"
if [ ! -d "$origen" ]; then
  echo "No se encontró $origen" >&2
  exit 1
fi

enlazar_a() {
  local destino="$1"
  local nombre="$2"

  while [ "$destino" != "/" ] && [ "${destino%/}" != "$destino" ]; do
    destino="${destino%/}"
  done

  if [ -L "$destino" ] && [ "$(cd "$destino" 2>/dev/null && pwd -P)" = "$origen" ]; then
    echo "Ya enlazado ($nombre): $destino -> $origen"
    return 0
  fi

  if [ -e "$destino" ] || [ -L "$destino" ]; then
    local respaldo="$destino.respaldo-$(date +%Y%m%d%H%M%S)"
    mv "$destino" "$respaldo"
    echo "Respaldado ($nombre): $destino -> $respaldo"
  fi

  mkdir -p "$(dirname "$destino")"
  ln -s "$origen" "$destino"
  echo "Enlazado ($nombre): $destino -> $origen"
}

instalar_gemini() {
  local base_destino="$1"
  local nombre_entorno="$2"

  while [ "$base_destino" != "/" ] && [ "${base_destino%/}" != "$base_destino" ]; do
    base_destino="${base_destino%/}"
  done

  if [ -L "$base_destino" ] || { [ -e "$base_destino" ] && [ ! -d "$base_destino" ]; }; then
    local respaldo="$base_destino.respaldo-$(date +%Y%m%d%H%M%S)"
    mv "$base_destino" "$respaldo"
    echo "Respaldado ($nombre_entorno): $base_destino -> $respaldo"
  fi

  mkdir -p "$base_destino"

  local count=0
  for src in "$origen"/*.md; do
    [ -f "$src" ] || continue
    local filename
    filename="$(basename "$src")"
    [ "$filename" = "README.md" ] && continue

    local agent_name="${filename%.md}"
    local dest_dir="$base_destino/$agent_name"
    local dest_file="$dest_dir/agent.md"

    mkdir -p "$dest_dir"
    awk '
      BEGIN { fm = 0 }
      /^---[[:space:]]*$/ && fm < 2 {
        fm++
        print
        next
      }
      fm == 1 {
        if ($0 ~ /^effort:[[:space:]]*/) next
        if ($0 ~ /^tools:[[:space:]]*/) {
          line = $0
          sub(/^tools:[[:space:]]*/, "", line)
          n = split(line, raw, /,[[:space:]]*/)
          out = ""
          delete seen
          for (i = 1; i <= n; i++) {
            t = raw[i]
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", t)
            mapped = ""
            if (t == "Read" || t == "Grep" || t == "Glob") mapped = "read_file"
            else if (t == "Edit" || t == "MultiEdit") mapped = "edit_file"
            else if (t == "Write") mapped = "write_file"
            else if (t == "Bash") mapped = "run_command, manage_task"
            else if (t == "WebSearch" || t == "WebFetch") mapped = "search_web"
            else if (t == "SendMessage") mapped = "send_message"
            if (mapped != "") {
              m = split(mapped, parts, /, /)
              for (j = 1; j <= m; j++) {
                p = parts[j]
                if (!(p in seen)) {
                  seen[p] = 1
                  out = (out == "" ? p : out ", " p)
                }
              }
            }
          }
          if (out != "") print "tools: [" out "]"
          next
        }
        if ($0 ~ /^model:[[:space:]]*opus[[:space:]]*$/) { print "model: pro"; next }
        if ($0 ~ /^model:[[:space:]]*sonnet[[:space:]]*$/) { print "model: flash"; next }
        if ($0 ~ /^model:[[:space:]]*haiku[[:space:]]*$/) { print "model: flash_lite"; next }
      }
      { print }
    ' "$src" > "$dest_file"

    count=$((count + 1))
  done

  echo "Instalados $count agentes ($nombre_entorno): $base_destino/<nombre>/agent.md"
}

target="${1:---all}"

case "$target" in
  --claude)
    enlazar_a "$HOME/.claude/agents" "Claude Code"
    echo "Abre una sesión nueva de Claude Code para cargar los agentes."
    ;;
  --gemini)
    instalar_gemini "$HOME/.gemini/config/agents" "Gemini / Antigravity"
    echo "Abre una sesión nueva de Gemini CLI o Antigravity para cargar los agentes."
    ;;
  --all)
    enlazar_a "$HOME/.claude/agents" "Claude Code"
    instalar_gemini "$HOME/.gemini/config/agents" "Gemini / Antigravity"
    echo "Abre una sesión nueva de Claude Code o Gemini/Antigravity para cargar los agentes."
    ;;
  *)
    # Destino personalizado
    enlazar_a "$target" "Personalizado"
    echo "Enlace completado en destino personalizado."
    ;;
esac
