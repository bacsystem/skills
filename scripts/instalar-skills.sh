#!/usr/bin/env bash
# Enlaza las skills de este repositorio a las carpetas globales de skills:
# - Claude Code: ~/.claude/skills/<nombre-skill>
# - Gemini / Antigravity: ~/.gemini/skills/<nombre-skill>
#
# Uso:
#   scripts/instalar-skills.sh [--all | --claude | --gemini]
#   scripts/instalar-skills.sh [carpeta_destino]
#
# Si no se pasa argumento, por defecto instala para ambos (--all).
#
# Si el destino de una skill ya existe:
# - un enlace a otra ruta se reemplaza (borrar un enlace no pierde nada);
# - una carpeta o archivo real se mueve a <carpeta_destino>-respaldo/<skill>-<fecha>,
#   fuera de la carpeta de skills: un respaldo dentro de ella se cargaría como
#   una skill más con el mismo nombre.
set -euo pipefail

case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*)
    echo "En Windows ejecuta: powershell -ExecutionPolicy Bypass -File scripts/instalar-skills.ps1" >&2
    exit 1
    ;;
esac

repo_root="$(cd "$(dirname "$0")/.." && pwd -P)"

enlazar_skills_en() {
  local base_destino="$1"
  local nombre_entorno="$2"

  while [ "$base_destino" != "/" ] && [ "${base_destino%/}" != "$base_destino" ]; do
    base_destino="${base_destino%/}"
  done

  mkdir -p "$base_destino"

  if [ -e "$base_destino/.git" ]; then
    echo "Aviso ($nombre_entorno): $base_destino es un clon de git. Un pull o checkout ahí" >&2
    echo "  puede devolver copias viejas de las skills que pisen estos enlaces." >&2
    echo "  Conviértela en una carpeta normal (saca .git y los archivos del repo)." >&2
  fi

  for dir in "$repo_root"/*; do
    if [ -d "$dir" ] && [ -f "$dir/SKILL.md" ]; then
      local skill_name
      skill_name="$(basename "$dir")"
      local destino="$base_destino/$skill_name"

      if [ -L "$destino" ] && [ "$(cd "$destino" 2>/dev/null && pwd -P)" = "$dir" ]; then
        echo "Ya enlazado ($nombre_entorno): $destino -> $dir"
        continue
      fi

      if [ -L "$destino" ]; then
        rm "$destino"
        echo "Reemplazado ($nombre_entorno): enlace anterior $destino"
      elif [ -e "$destino" ]; then
        local carpeta_respaldo="$base_destino-respaldo"
        local respaldo="$carpeta_respaldo/$skill_name-$(date +%Y%m%d%H%M%S)"
        mkdir -p "$carpeta_respaldo"
        mv "$destino" "$respaldo"
        echo "Respaldado ($nombre_entorno): $destino -> $respaldo"
      fi

      ln -s "$dir" "$destino"
      echo "Enlazado ($nombre_entorno): $destino -> $dir"
    fi
  done
}

target="${1:---all}"

case "$target" in
  --claude)
    enlazar_skills_en "$HOME/.claude/skills" "Claude Code"
    echo "Skills disponibles en Claude Code. Abre una sesión nueva para usarlas."
    ;;
  --gemini)
    enlazar_skills_en "$HOME/.gemini/skills" "Gemini / Antigravity"
    echo "Skills disponibles en Gemini CLI / Antigravity. Abre una sesión nueva para usarlas."
    ;;
  --all)
    enlazar_skills_en "$HOME/.claude/skills" "Claude Code"
    enlazar_skills_en "$HOME/.gemini/skills" "Gemini / Antigravity"
    echo "Skills disponibles en Claude Code y Gemini / Antigravity. Abre una sesión nueva para usarlas."
    ;;
  *)
    enlazar_skills_en "$target" "Personalizado"
    echo "Skills enlazadas en destino personalizado."
    ;;
esac
