#!/usr/bin/env bash
# Contrasta los docs que afirman un estado con GitHub: cada #N de una línea que
# dice «hecho» o «pendiente» contra el estado real de la issue o el PR, cada
# vX.Y.Z mencionada contra los tags, y los archivos de versión contra el último tag.
# Uso: docs-sync/scripts/check.sh <owner/repo> <archivo.md> [<archivo.md>...]
# Correr desde la raíz del repo (los archivos de versión se buscan ahí).
# Solo lee (gh api). Salida: un desvío por línea, «archivo:línea: …».
# Exit: 0 sin desvíos · 1 con desvíos · 2 uso incorrecto o gh/jq que falla.
# Un fallo nunca pasa por limpio: si gh falla, aborta con 2.
#
# Variables:
#   DOCS_SYNC_DONE_WORDS      palabras extra de «hecho», separadas por | (regex)
#   DOCS_SYNC_PENDING_WORDS   palabras extra de «pendiente», separadas por | (regex)
#   DOCS_SYNC_VERSION_FILES   archivos de versión (por defecto: «package.json VERSION»)
#   DOCS_SYNC_MAX_DISTANCE    palabras como máximo entre la palabra de estado y el #N (6)
#   DOCS_SYNC_STRICT_VERSIONS 1 = también marca las versiones mayores que el último tag
#   DOCS_SYNC_STATUS_WORDS    marcadores extra de «párrafo de estado», separados por | (regex)
#
# Párrafos de estado: un párrafo (líneas hasta una en blanco) que empieza con
# «Estado:»/«Status:»/«State:» o dice «todavía», «aún no», «currently» o «not yet»
# describe el presente. Si cita versiones y ninguna es el último tag, es un desvío:
# lo más probable es que el texto se haya quedado en una versión anterior.
#
# Escape: `<!-- docs-sync: ignore -->` en la línea, o en la anterior, la saltea.
set -euo pipefail

DONE='\b(?:hecho|done|cerrad\w*|completad\w*|merged)\b|✅'
# «todo» en minúsculas es «all» en español: solo cuenta TODO en mayúsculas (aparte).
PENDING='\b(?:pendiente\w*|por hacer|bloquead\w*|open|en curso)\b'
IGNORE='<!--\s*docs-sync:\s*ignore\s*-->'

die() { echo "docs-sync: $*" >&2; exit 2; }

# Analiza un archivo (stdin) y escribe por stdout, una por línea:
#   <línea>\tR\t<N>\t<done|pending|mixed>   por cada #N que una palabra de estado juzga
#   <línea>\tV\t<vX.Y.Z>                    por cada versión mencionada
# Cada #N se juzga solo por una palabra de estado de su misma cláusula (se corta en
# . ; | y « — »; en «:» también, salvo que un lado sea una etiqueta corta sin #N,
# como «Pendiente: #4» o «(#4): hecho») y a DOCS_SYNC_MAX_DISTANCE palabras o menos.
# Cada palabra se aplica solo al #N más cercano. Se saltan los bloques de código
# (``` o ~~~) y las líneas con el escape. Un #N pegado a & / # o a una palabra no
# cuenta (entidades HTML, anclas de URL); una versión pegada a # @ / no cuenta (es
# de otro paquete: `repo#v1.2.3`, `pkg@v1.2.3`).
analizar() {
  local done_re="$DONE" pend_re="$PENDING"
  [ -z "${DOCS_SYNC_DONE_WORDS:-}" ] || done_re="$done_re|\\b(?:$DOCS_SYNC_DONE_WORDS)\\b"
  [ -z "${DOCS_SYNC_PENDING_WORDS:-}" ] || pend_re="$pend_re|\\b(?:$DOCS_SYNC_PENDING_WORDS)\\b"
  jq -nRr --arg d "$done_re" --arg p "$pend_re" --arg ign "$IGNORE" \
     --argjson max "${DOCS_SYNC_MAX_DISTANCE:-6}" '
    def palabras: [splits("\\s+") | select(length > 0)] | length;
    def tiene_ref: test("(?<![&\\w/#])#[0-9]");
    # Índice de palabra de la posición $o dentro de $s.
    def indice($s; $o): [$s[:$o] | sub("^\\s+"; "") | match("\\s+"; "g")] | length;
    # Une las partes separadas por «:» cuando un lado es una etiqueta corta sin #N.
    def unir_dos_puntos:
      reduce .[] as $x ([];
        if length == 0 then [$x]
        elif (.[-1] | (tiene_ref | not) and palabras <= 2) then .[:-1] + [.[-1] + ":" + $x]
        elif ($x | (tiene_ref | not) and palabras <= 3) then .[:-1] + [.[-1] + ":" + $x]
        else . + [$x] end);
    def clausulas: [splits("[.;|]|\\s—\\s")] | map([splits(":")] | unir_dos_puntos | .[]);
    # Por cada palabra de estado, el #N más cercano a $max palabras o menos.
    def juicios:
      . as $c
      | [match("(?<![&\\w/#])#([0-9]+)\\b"; "g") | {n: .captures[0].string, w: indice($c; .offset)}] as $refs
      | ([match($d; "gi") | {k: "done", w: indice($c; .offset)}]
         + [match($p; "gi") | {k: "pending", w: indice($c; .offset)}]
         + [match("\\bTODO\\b"; "g") | {k: "pending", w: indice($c; .offset)}])[]
      | . as $s
      | [$refs[] | {n, dist: ((.w - $s.w) | fabs)} | select(.dist <= $max)]
      | select(length > 0) | min_by(.dist) | {n, k: $s.k};
    foreach inputs as $l ({n: 0, code: false, fence: false, prev: ""};
      .n += 1
      | .fence = ($l | test("^\\s*(```|~~~)"))
      | .skip = (($l | test($ign)) or (.prev | test($ign)))
      | .prev = $l
      | if .fence then .code = (.code | not) else . end;
      select((.fence or .code or .skip) | not)
      | .n as $n
      | ( [$l | clausulas[] | juicios] | group_by(.n)[]
          | {n: .[0].n, k: (map(.k) | unique | if length > 1 then "mixed" else .[0] end)}
          | "\($n)\tR\t\(.n)\t\(.k)" )
      , ($l | [scan("(?<![\\w#@/.-])(v[0-9]+\\.[0-9]+\\.[0-9]+)\\b") | .[0]] | unique | .[] | "\($n)\tV\t\(.)")
    )'
}

# Versión más alta de una lista X.Y.Z (stdin, una por línea).
mayor() { sort -t. -k1,1n -k2,2n -k3,3n | tail -n 1; }

main() {
  [ $# -ge 2 ] || { echo "uso: $0 <owner/repo> <archivo.md> [<archivo.md>...]" >&2; exit 2; }
  local repo=$1; shift
  case "$repo" in */*) ;; *) die "repo inválido: $repo (se espera owner/repo)";; esac
  command -v gh >/dev/null || die "falta gh"
  command -v jq >/dev/null || die "falta jq"
  local f
  for f in "$@"; do [ -f "$f" ] || die "no existe: $f"; done

  # Global (no local): el trap corre al salir, cuando las locales ya no existen.
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  : > "$tmp/refs"

  # 1. Referencias y versiones de cada archivo.
  local out
  for f in "$@"; do
    out="$(analizar < "$f")" || die "jq no pudo leer $f"
    [ -z "$out" ] || awk -v f="$f" '{ print f "\t" $0 }' <<<"$out" >> "$tmp/refs"
  done

  # 2. Estado de cada #N, una consulta por número. Sin sustitución de proceso:
  #    un fallo de gh (rate limit, sesión vencida, #N inexistente) aborta.
  : > "$tmp/states"
  local n json state
  for n in $(awk -F'\t' '$3 == "R" { print $4 }' "$tmp/refs" | sort -un); do
    json="$(gh api "repos/$repo/issues/$n" 2>"$tmp/err")" || die "gh falló al consultar #$n: $(cat "$tmp/err")"
    state="$(jq -r '.state // empty' <<<"$json")" || die "respuesta ilegible de gh para #$n"
    [ -n "$state" ] || die "gh no devolvió el estado de #$n"
    printf '%s\t%s\n' "$n" "$state" >> "$tmp/states"
  done

  # 3. Tags, solo si hacen falta (versiones mencionadas o archivos de versión).
  local vfiles="${DOCS_SYNC_VERSION_FILES-package.json VERSION}" vf hay_vf=0
  for vf in $vfiles; do [ -f "$vf" ] && hay_vf=1; done
  : > "$tmp/tags"
  if [ "$hay_vf" = 1 ] || awk -F'\t' '$3 == "V" { found = 1 } END { exit !found }' "$tmp/refs"; then
    json="$(gh api --paginate "repos/$repo/tags?per_page=100" 2>"$tmp/err")" || die "gh falló al listar los tags: $(cat "$tmp/err")"
    jq -rs 'add // [] | .[].name' <<<"$json" > "$tmp/tags" || die "respuesta ilegible de gh para los tags"
  fi

  # 4. Desvíos de #N y de versiones.
  local desvios=0
  local ultimo
  ultimo="$(sed -n 's/^v\{0,1\}\([0-9]*\.[0-9]*\.[0-9]*\)$/\1/p' "$tmp/tags" | mayor)"
  # Una versión mayor que el último tag (o sin tags) es de otro paquete o del
  # futuro: no se marca, salvo con DOCS_SYNC_STRICT_VERSIONS=1.
  out="$(awk -F'\t' -v ultimo="$ultimo" -v estricto="${DOCS_SYNC_STRICT_VERSIONS:-0}" '
    function mayor_que(a, b,   x, y, i) {
      sub(/^v/, "", a); split(a, x, "."); split(b, y, ".")
      for (i = 1; i <= 3; i++) { if (x[i] + 0 != y[i] + 0) return x[i] + 0 > y[i] + 0 }
      return 0
    }
    FILENAME == ARGV[1] { st[$1] = $2; next }
    # Con o sin el prefijo v: un repo con tags «1.2.3» también reconoce «v1.2.3».
    FILENAME == ARGV[2] { t = $1; sub(/^v/, "", t); tag[t] = 1; next }
    $3 == "R" && $5 == "pending" && st[$4] == "closed" { print $1 ":" $2 ": #" $4 " está cerrado, pero la línea lo da por pendiente" }
    $3 == "R" && $5 == "done" && st[$4] == "open"      { print $1 ":" $2 ": #" $4 " está abierto, pero la línea lo da por hecho" }
    $3 == "V" && !(substr($4, 2) in tag) && (estricto == "1" || (ultimo != "" && !mayor_que($4, ultimo))) { print $1 ":" $2 ": " $4 " no existe como tag" }
  ' "$tmp/states" "$tmp/tags" "$tmp/refs")"
  if [ -n "$out" ]; then echo "$out"; desvios=$(wc -l <<<"$out" | tr -d ' '); fi

  # 4b. Párrafos de estado que solo citan versiones anteriores al último tag.
  #     Un párrafo termina en una línea en blanco, un encabezado, un ítem de lista o
  #     una fila de tabla (cada ítem y cada fila se juzga solo). El CHANGELOG no
  #     cuenta: sus secciones publicadas citan versiones viejas a propósito.
  local est_files=() g
  for g in "$@"; do case "$(basename "$g")" in CHANGELOG*|changelog*) ;; *) est_files+=("$g") ;; esac; done
  if [ -n "$ultimo" ] && [ "${#est_files[@]}" -gt 0 ]; then
    out="$(awk -v ultimo="$ultimo" -v extra="${DOCS_SYNC_STATUS_WORDS:-}" '
      function mayor_que(a, b,   x, y, i) {
        sub(/^v/, "", a); split(a, x, "."); split(b, y, ".")
        for (i = 1; i <= 3; i++) { if (x[i] + 0 != y[i] + 0) return x[i] + 0 > y[i] + 0 }
        return 0
      }
      function cierra(   t) {
        # Las frases se buscan en el texto del párrafo con los saltos de línea como
        # espacios: «not» al final de una línea y «yet» al principio de la otra cuentan.
        t = " " txt " "
        if (t ~ /todav(i|í|Í)a|a(u|ú|Ú)n[[:space:]]+no|not[[:space:]]+yet/ \
            || t ~ /[^a-z]currently[^a-z]/ \
            || (extra != "" && t ~ extra)) estado = 1
        if (estado && !ign && nv > 0 && !actual)
          print archivo ":" ini ": párrafo de estado que cita " vs " y no el último tag v" ultimo "; revisa si sigue vigente"
        estado = 0; ign = 0; nv = 0; actual = 0; vs = ""; ini = 0; txt = ""
      }
      FNR == 1 { if (NR > 1) cierra(); archivo = FILENAME; codigo = 0 }
      # Bloques de código: una valla de 3 o más ` o ~ abre; cierra solo una valla del
      # mismo carácter, de igual o mayor largo y sin texto después.
      codigo {
        if (match($0, /^[[:space:]]*(`+|~+)[[:space:]]*$/)) {
          f = $0; gsub(/[[:space:]]/, "", f)
          if (substr(f, 1, 1) == valla_c && length(f) >= valla_n) codigo = 0
        }
        next
      }
      match($0, /^[[:space:]]*(```+|~~~+)/) {
        f = substr($0, RSTART, RLENGTH); gsub(/[[:space:]]/, "", f)
        cierra(); codigo = 1; valla_c = substr(f, 1, 1); valla_n = length(f); next
      }
      /^[[:space:]]*$/ { cierra(); next }
      # Encabezado, ítem de lista o fila de tabla: empieza un párrafo propio.
      /^[[:space:]]*(#|[-*+][[:space:]]|[0-9]+[.)][[:space:]]|\|)/ { cierra() }
      {
        if (!ini) ini = FNR
        l = tolower($0)
        txt = txt " " l
        # Acentos como alternativas, no como clase: [ií] son bytes sueltos en UTF-8
        # y no coinciden en mawk ni con LC_ALL=C. Las frases se buscan en cierra().
        if (l ~ /^[[:space:]]*[-*+>#|]*[[:space:]]*(estado|status|state)[[:space:]]*:/) estado = 1
        if ($0 ~ /<!--[[:space:]]*docs-sync:[[:space:]]*ignore[[:space:]]*-->/) ign = 1
        r = $0; pre = ""
        while (match(r, /v[0-9]+\.[0-9]+\.[0-9]+/)) {
          antes = (RSTART > 1 ? substr(r, RSTART - 1, 1) : substr(pre, length(pre), 1))
          v = substr(r, RSTART, RLENGTH); pre = substr(r, 1, RSTART + RLENGTH - 1); r = substr(r, RSTART + RLENGTH)
          # Igual que el paso 1: no cuentan las versiones de otro paquete o repo
          # (pkg@v…, repo#v…, ruta/v…) ni las mayores que el último tag.
          if (antes ~ /[[:alnum:]_#@\/.-]/) continue
          if (mayor_que(v, ultimo)) continue
          nv++
          if (substr(v, 2) == ultimo) actual = 1
          else if (index(" " vs ",", " " v ",") == 0) vs = (vs == "" ? v : vs ", " v)
        }
      }
      END { cierra() }
    ' "${est_files[@]}")"
    if [ -n "$out" ]; then echo "$out"; desvios=$((desvios + $(wc -l <<<"$out" | tr -d ' '))); fi
  fi

  # Líneas con palabras de los dos tipos: no se juzgan, se avisan.
  awk -F'\t' '$3 == "R" && $5 == "mixed" && !seen[$1 FS $2]++ { print "nota: " $1 ":" $2 ": la línea dice «hecho» y «pendiente» a la vez; revísala a mano" }' "$tmp/refs" >&2

  # 5. Archivos de versión contra el último tag X.Y.Z.
  local v
  if [ -n "$ultimo" ]; then
    for vf in $vfiles; do
      [ -f "$vf" ] || continue
      case "$(basename "$vf")" in
        *.json) v="$(jq -r '.version // empty' "$vf")" || die "no se pudo leer $vf" ;;
        *) v="$(head -n 1 "$vf" | tr -d '[:space:]')"; v="${v#v}" ;;
      esac
      [ -n "$v" ] || continue
      if [ "$v" != "$ultimo" ] && [ "$(printf '%s\n%s\n' "$v" "$ultimo" | mayor)" = "$ultimo" ]; then
        echo "$vf: versión $v menor que el último tag v$ultimo"
        desvios=$((desvios + 1))
      fi
    done
  fi

  if [ "$desvios" -gt 0 ]; then
    echo "$desvios desvío(s) en $repo."
    exit 1
  fi
  echo "Sin desvíos en $# archivo(s) contra $repo."
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then main "$@"; fi
