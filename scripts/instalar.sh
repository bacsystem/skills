#!/usr/bin/env bash
# Instala tanto agentes como skills de este repositorio:
# - Claude Code: ~/.claude/agents y ~/.claude/skills/
# - Gemini / Antigravity: ~/.gemini/config/agents y ~/.gemini/skills/
#
# Uso:
#   scripts/instalar.sh [--all | --claude | --gemini]
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd -P)"
target="${1:---all}"

echo "=== Instalando agentes ==="
"$script_dir/instalar-agentes.sh" "$target"

echo ""
echo "=== Instalando skills ==="
"$script_dir/instalar-skills.sh" "$target"

echo ""
echo "¡Instalación completada exitosamente!"
