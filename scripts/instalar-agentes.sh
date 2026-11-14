#!/usr/bin/env bash
# Enlaza la carpeta agents/ de este repositorio a ~/.claude/agents (macOS y Linux).
# En Windows usa scripts/instalar-agentes.ps1: Git Bash no crea enlaces simbólicos reales.
#
# Uso: scripts/instalar-agentes.sh [destino]     (destino por defecto: ~/.claude/agents)
# Se puede ejecutar desde cualquier carpeta. Si el destino ya existe y no es este
# enlace, se renombra a <destino>.respaldo-<fecha> antes de enlazar: nada se borra.
set -euo pipefail

case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*)
    echo "En Windows ejecuta: powershell -ExecutionPolicy Bypass -File scripts/instalar-agentes.ps1" >&2
    exit 1
    ;;
esac

origen="$(cd "$(dirname "$0")/.." && pwd -P)/agents"
destino="${1:-$HOME/.claude/agents}"

if [ ! -d "$origen" ]; then
  echo "No se encontró $origen" >&2
  exit 1
fi

if [ -L "$destino" ]; then
  if [ "$(cd "$destino" 2>/dev/null && pwd -P)" = "$origen" ]; then
    echo "Ya enlazado: $destino -> $origen"
    exit 0
  fi
  rm "$destino"
elif [ -e "$destino" ]; then
  respaldo="$destino.respaldo-$(date +%Y%m%d%H%M%S)"
  mv "$destino" "$respaldo"
  echo "Respaldado: $destino -> $respaldo"
fi

mkdir -p "$(dirname "$destino")"
ln -s "$origen" "$destino"
echo "Enlazado: $destino -> $origen"
echo "Abre una sesión nueva de Claude Code para cargar los agentes."
