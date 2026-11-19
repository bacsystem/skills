#!/usr/bin/env bash
# Prueba docs-sync/scripts/check.sh sin red: pone un `gh` falso primero en el PATH
# que responde con issues y tags de ejemplo, y corre el script sobre docs de prueba.
# Uso: scripts/tests/test-docs-sync-check.sh [ruta a check.sh]
set -u
script="${1:-$(cd "$(dirname "$0")/../.." && pwd)/docs-sync/scripts/check.sh}"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
fallos=0
igual() { # $1 = nombre, $2 = esperado, $3 = obtenido
  if [ "$2" = "$3" ]; then echo "PASS: $1"; else echo "FALLA: $1 (esperado «$2», obtenido «$3»)"; fallos=$((fallos + 1)); fi
}
contiene() { # $1 = nombre, $2 = texto buscado, $3 = salida
  if grep -qF -- "$2" <<<"$3"; then echo "PASS: $1"; else echo "FALLA: $1 (no aparece «$2» en:"; sed 's/^/    /' <<<"$3"; echo "  )"; fallos=$((fallos + 1)); fi
}

# gh falso: #1 y #3 cerrados, #2 abierto; tags v0.1.0 y v0.2.0 en dos páginas.
# GH_FALLA=1 simula un fallo (rate limit, sesión vencida).
mkdir -p "$T/bin"
cat > "$T/bin/gh" <<'EOF'
#!/usr/bin/env bash
[ "${GH_FALLA:-0}" = 1 ] && { echo "gh: HTTP 403 rate limit exceeded" >&2; exit 1; }
[ "$1" = api ] || { echo "gh falso: comando no soportado: $*" >&2; exit 1; }
shift; [ "$1" = --paginate ] && shift
case "$1" in
  repos/o/r/issues/1) echo '{"number":1,"state":"closed"}' ;;
  repos/o/r/issues/2) echo '{"number":2,"state":"open"}' ;;
  repos/o/r/issues/3) echo '{"number":3,"state":"closed"}' ;;
  repos/o/r/tags*)    echo '[{"name":"v0.1.0"}]'; echo '[{"name":"v0.2.0"}]' ;;
  *) echo "gh: Not Found (HTTP 404) $1" >&2; exit 1 ;;
esac
EOF
chmod +x "$T/bin/gh"
export PATH="$T/bin:$PATH"

corre() { # corre el script desde $T (sin archivos de versión salvo que el caso los cree)
  (cd "$T" && bash "$script" "$@" 2>&1); echo "exit=$?"
}

# 1. #1 cerrado en una línea «pendiente» → desvío
printf '# Roadmap\n\n- Épica kernel (#1): pendiente\n' > "$T/a.md"
out="$(corre o/r a.md)"
contiene "cerrado en línea pendiente: archivo:línea" "a.md:3:" "$out"
contiene "cerrado en línea pendiente: nombra el #N" "#1" "$out"
contiene "cerrado en línea pendiente: exit 1" "exit=1" "$out"

# 2. #2 abierto en una línea «hecho» → desvío
printf 'Estado: ✅ auth (#2)\n' > "$T/b.md"
out="$(corre o/r b.md)"
contiene "abierto en línea hecho: archivo:línea" "b.md:1:" "$out"
contiene "abierto en línea hecho: exit 1" "exit=1" "$out"

# 3. líneas coherentes → nada, exit 0 (palabras en inglés y en mayúsculas incluidas)
printf -- '- #1 Done\n- #2 en curso\n- #3 cerrada\n- v0.2.0 publicada\n' > "$T/c.md"
out="$(corre o/r c.md)"
contiene "líneas coherentes: exit 0" "exit=0" "$out"
igual "líneas coherentes: ningún desvío" 0 "$(grep -c '^c.md:' <<<"$out")"

# 3b. un #N dentro de un bloque de código y una entidad HTML no cuentan
printf '```\n#1 pendiente\n```\n&#2; hecho\n' > "$T/d.md"
out="$(corre o/r d.md)"
contiene "bloque de código y entidad HTML: exit 0" "exit=0" "$out"

# 3c. la lista de palabras se amplía con una variable
printf -- '- #1 wip\n' > "$T/e.md"
out="$(cd "$T" && DOCS_SYNC_PENDING_WORDS='wip' bash "$script" o/r e.md 2>&1; echo "exit=$?")"
contiene "palabra extra de pendiente: desvío" "e.md:1:" "$out"

# 4. una versión mencionada que no existe como tag
printf 'Publicado en v0.3.0 y v0.2.0\n' > "$T/f.md"
out="$(corre o/r f.md)"
contiene "tag inexistente: archivo:línea y versión" "f.md:1: v0.3.0" "$out"
igual "tag existente: no se reporta" 0 "$(grep -c 'v0.2.0' <<<"$out")"
contiene "tag inexistente: exit 1" "exit=1" "$out"

# 5. archivo de versión por debajo del último tag (v0.2.0)
printf '{"name":"x","version":"0.1.5"}\n' > "$T/package.json"
printf 'nada que revisar\n' > "$T/g.md"
out="$(corre o/r g.md)"
contiene "package.json menor que el último tag" "package.json: versión 0.1.5 menor que el último tag v0.2.0" "$out"
contiene "package.json menor: exit 1" "exit=1" "$out"
printf '{"name":"x","version":"0.2.0"}\n' > "$T/package.json"
out="$(corre o/r g.md)"
contiene "package.json al día: exit 0" "exit=0" "$out"
rm "$T/package.json"

# 6. gh que falla → exit distinto de 0 y nunca «sin desvíos»
out="$(cd "$T" && GH_FALLA=1 bash "$script" o/r a.md 2>&1; echo "exit=$?")"
igual "gh falla: no sale limpio" 0 "$(grep -c '^exit=0$' <<<"$out")"
igual "gh falla: no dice sin desvíos" 0 "$(grep -ci 'sin desvíos' <<<"$out")"
contiene "gh falla: exit 2" "exit=2" "$out"

# 6b. un #N que no existe hace fallar a gh: también aborta
printf -- '- #99 pendiente\n' > "$T/h.md"
out="$(corre o/r h.md)"
contiene "#N inexistente: exit 2" "exit=2" "$out"

# 7. uso incorrecto y archivo que no existe
out="$(corre o/r)"
contiene "sin archivos: exit 2" "exit=2" "$out"
out="$(corre o/r no-existe.md)"
contiene "archivo inexistente: exit 2" "exit=2" "$out"

[ "$fallos" -eq 0 ] && echo "All tests passed." || { echo "$fallos fallo(s)."; exit 1; }
