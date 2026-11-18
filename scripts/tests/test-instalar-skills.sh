#!/usr/bin/env bash
# Prueba scripts/instalar-skills.sh en una carpeta temporal (nunca toca ~/.claude ni ~/.gemini).
# Uso: scripts/tests/test-instalar-skills.sh [ruta/al/instalar-skills.sh]
set -euo pipefail

script="${1:-$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)/instalar-skills.sh}"
# El script resuelve las skills desde su propia carpeta: <script>/../..
repo="$(CDPATH= cd -- "$(dirname "$script")/.." && pwd -P)"
skill="$(cd "$repo" && ls -d */SKILL.md | head -1 | cut -d/ -f1)"  # primera skill del repo
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
export HOME="$T/home"; mkdir -p "$HOME"

fail() { echo "FALLO: $*" >&2; exit 1; }
check() { local d="$1"; shift; "$@" || fail "$d"; echo "ok - $d"; }
apunta_al_repo() { [ -L "$1" ] && [ "$(cd "$1" && pwd -P)" = "$repo/$skill" ]; }
run() { bash "$script" "$@" 2>&1; }

d="$T/skills"; r="$d-respaldo"

# 1 y 8: enlaza, y la segunda corrida no cambia nada
run "$d" >/dev/null
check "enlaza la skill al repo" apunta_al_repo "$d/$skill"
out="$(run "$d")"
check "segunda corrida: Ya enlazado" grep -q "Ya enlazado.*$skill" <<<"$out"
check "segunda corrida: sin respaldo" test ! -e "$r"

# 2: un enlace a otra ruta se reemplaza y su destino queda intacto
mkdir -p "$T/otra"; echo x > "$T/otra/dato"
rm "$d/$skill"; ln -s "$T/otra" "$d/$skill"
run "$d" >/dev/null
check "enlace ajeno reemplazado" apunta_al_repo "$d/$skill"
check "carpeta del enlace ajeno intacta" test -f "$T/otra/dato"
check "enlace ajeno sin respaldo" test ! -e "$r"

# 3: carpeta real -> <destino>-respaldo/<skill>-<fecha>
rm "$d/$skill"; mkdir "$d/$skill"; echo y > "$d/$skill/mio"
run "$d" >/dev/null
check "carpeta real enlazada" apunta_al_repo "$d/$skill"
check "carpeta real respaldada" test -f "$(ls -d "$r/$skill"-* | head -1)/mio"

# 4: <skill>.respaldo-* dentro del destino (carpeta real y enlace) salen
mkdir "$d/$skill.respaldo-1"; ln -s "$T/otra" "$d/$skill.respaldo-2"
ln -s "$T/nada" "$d/$skill.respaldo-3"   # enlace roto
run "$d" >/dev/null
check "respaldo viejo roto movido" test -L "$r/$skill.respaldo-3"
check "respaldo viejo (carpeta) movido" test -d "$r/$skill.respaldo-1"
check "respaldo viejo (enlace) movido" test -L "$r/$skill.respaldo-2"
check "nada .respaldo-* dentro del destino" test -z "$(ls -d "$d"/*.respaldo-* 2>/dev/null)"

# 5: destino relativo "." -> el respaldo cae al lado, no dentro
mkdir -p "$T/rel"; rm -rf "$T/rel-respaldo"
(cd "$T/rel" && mkdir "$skill" && bash "$script" . >/dev/null 2>&1)
check "destino '.' : respaldo fuera" test -d "$T/rel-respaldo"
check "destino '.' : nada dentro" test -z "$(ls -d "$T"/rel/*respaldo* 2>/dev/null)"

# 5b: destino relativo bajo CDPATH
mkdir -p "$T/decoy/rel2" "$T/w"
(cd "$T/w" && CDPATH="$T/decoy" bash "$script" rel2 >/dev/null 2>&1) || true
check "destino relativo con CDPATH" apunta_al_repo "$T/w/rel2/$skill"

# 6: destino con .git -> aviso
mkdir -p "$T/clon/.git"
out="$(run "$T/clon")"
check "aviso si el destino es un clon git" grep -q "Aviso.*clon de git" <<<"$out"

# 7: CDPATH no desvía la ruta del repo (decoy/scripts/.. sería otro directorio)
mkdir -p "$T/decoy/scripts"
(cd "$repo" && CDPATH="$T/decoy" bash "scripts/$(basename "$script")" "$T/cdp" >/dev/null 2>&1) || true
check "CDPATH ignorado" apunta_al_repo "$T/cdp/$skill"

echo "OK: instalar-skills.sh pasa todas las pruebas (reglas 1-8)"
