#!/usr/bin/env bash
# Enlaza la carpeta agents/ de este repositorio a las carpetas globales de agentes:
# - Claude Code: ~/.claude/agents
# - Gemini / Antigravity: ~/.gemini/agents
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

target="${1:---all}"

case "$target" in
  --claude)
    enlazar_a "$HOME/.claude/agents" "Claude Code"
    echo "Abre una sesión nueva de Claude Code para cargar los agentes."
    ;;
  --gemini)
    enlazar_a "$HOME/.gemini/agents" "Gemini / Antigravity"
    echo "Abre una sesión nueva de Gemini CLI o Antigravity para cargar los agentes."
    ;;
  --all)
    enlazar_a "$HOME/.claude/agents" "Claude Code"
    enlazar_a "$HOME/.gemini/agents" "Gemini / Antigravity"
    echo "Abre una sesión nueva de Claude Code o Gemini/Antigravity para cargar los agentes."
    ;;
  *)
    # Destino personalizado
    enlazar_a "$target" "Personalizado"
    echo "Enlace completado en destino personalizado."
    ;;
esac
