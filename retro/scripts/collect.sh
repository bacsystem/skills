#!/usr/bin/env bash
# Junta las métricas de un lote de PR para la retrospectiva: rondas de revisión,
# informes de QA, hallazgos por severidad, commits de trabajo y merges recibidos,
# tiempo hasta el merge y fallos (con su causa) y duración de la CI.
# Uso: retro/scripts/collect.sh <owner/repo> <PR> [<PR>...]
# Solo lee (gh api, gh run view). Escribe Markdown por stdout.
# Con `source` solo define las funciones (las prueba scripts/tests/test-retro-collect.sh).
set -euo pipefail

# Una ronda es un comentario cuya primera línea abre una revisión, una re-revisión
# o el cierre de la revisión (el formato de `pr-review`). Las líneas «Veredicto»
# de dentro de un comentario (tablas de cierre, informes de QA) no cuentan.
# La primera línea se compara sin el marcado del principio (`#`, `**`, emojis,
# espacios): «Code review de …», «## Re-revisión 3 · …» y «**QA #12, SHA …» abren
# igual que un encabezado.
RONDA='^(Veredicto|Verdict|Re-revisión|Re-review|Revisión|Review|Code review|pr-review|Cierre|Closing)\b'
# Un informe de QA abre con «QA»/«Re-QA», o es una revisión que también es QA
# («Revisión y QA …», «Code review y QA …», con la QA en las primeras palabras:
# «Code review de …: … La QA va aparte» no lo es), o un encabezado que nombra la QA.
QA='^(Re-)?QA\b|^(Re-revisión|Re-review|Revisión|Review|Code review)\b[^.:·(`]{0,20}\b(re-)?QA\b|^#+ .*\bQA\b'

# Cuenta los comentarios (JSON de la API de issues, por stdin) cuya primera línea
# cumple la regex $1, sin el marcado del principio o tal cual (para los
# encabezados de la regex QA).
contar_primera_linea() {
  jq --arg r "$1" '[.[] | (.body | split("\n")[0]) as $l
    | select(($l | sub("^[^\\p{L}]+"; "") | test($r)) or ($l | test($r)))] | length'
}

# Commits subidos después de abrir el PR ($1 = created_at), JSON por stdin.
# Imprime «trabajo merges»: un merge es un commit con dos padres, venga de la base
# o de otra rama (en una rama apilada, también los de la rama de abajo).
contar_commits() {
  jq -r --arg c "$1" '[.[] | select(.commit.committer.date > $c) | (.parents | length > 1)]
    | "\(map(select(. == false)) | length) \(map(select(. == true)) | length)"'
}

# Tiempo entre dos instantes ISO 8601: minutos por debajo de una hora; si no,
# horas con un decimal.
tiempo_entre() {
  jq -rn --arg a "$1" --arg b "$2" '
    ((($b|fromdate) - ($a|fromdate)) / 60) as $m
    | if $m < 60 then "\($m | floor) min" else "\(($m / 6 | round) / 10) h" end'
}

# Primer test que falló en un log de `gh run view --log-failed` (stdin), con el
# job: Go (`--- FAIL:`), Playwright (`✘`) o Vitest/Jest (`FAIL`). Los códigos de
# color ANSI se quitan antes (Vitest pinta `FAIL`), tanto el byte ESC como el texto
# `^[` con que `gh run view --log-failed` los escribe. Vacío si no se reconoce.
primer_test_fallido() {
  sed -e $'s/\x1b\\[[0-9;]*[A-Za-z]//g' -e 's/\^\[\[[0-9;]*[A-Za-z]//g' | awk -F'\t' '
    {
      msg = $NF; sub(/^[0-9T:.-]+Z /, "", msg)
      if (match(msg, /--- FAIL: [^ ]+/))   { t = substr(msg, RSTART + 10, RLENGTH - 10) }
      else if (match(msg, /✘ +[0-9]+ .*/)) { t = substr(msg, RSTART, RLENGTH); sub(/^✘ +[0-9]+ +/, "", t); sub(/ \([0-9.]+m?s\)$/, "", t) }
      else if (match(msg, /^ *FAIL +[^ ].*/)) { t = msg; sub(/^ *FAIL +/, "", t) }
      else next
      job = $1; sub(/ \(.*/, "", job)
      print job ": " substr(t, 1, 80); exit
    }' | tr '|' '/'
}

# Sin test reconocido: el job y el primer paso que fallaron, del JSON de
# `gh run view --json jobs` (stdin). Vacío si no hay ninguno.
paso_fallido() {
  jq -r '[.jobs[] | select(.conclusion == "failure")
    | "\(.name | sub(" \\(.*"; "")): paso «\([.steps[] | select(.conclusion == "failure") | .name][0] // "?")»"][0] // empty'
}

# $1 = repo, $2 = id del run. Nunca falla: sin log, imprime vacío.
causa() {
  local t
  t=$({ gh run view "$2" --repo "$1" --log-failed 2>/dev/null || true; } | primer_test_fallido)
  [ -n "$t" ] || t=$({ gh run view "$2" --repo "$1" --json jobs 2>/dev/null || echo '{"jobs":[]}'; } | paso_fallido)
  printf '%s' "$t"
}

main() {
  [ $# -ge 2 ] || { echo "uso: $0 <owner/repo> <PR> [<PR>...]" >&2; exit 2; }
  local repo=$1; shift
  command -v gh >/dev/null || { echo "falta gh" >&2; exit 2; }
  command -v jq >/dev/null || { echo "falta jq" >&2; exit 2; }

  echo "| PR | Título | Rondas de revisión | Informes de QA | Bloq. | Imp. | Men. | Commits de trabajo | Merges | Hasta el merge | CI fallida | Causa de la falla | Minutos de CI |"
  echo "|---|---|---|---|---|---|---|---|---|---|---|---|---|"
  local pr meta title created merged comments rounds qas bodies blk imp min work merges elapsed branch runs failed minutes causes id c
  for pr in "$@"; do
    case "$pr" in *[!0-9]*) echo "PR inválido: $pr" >&2; exit 2;; esac
    meta=$(gh api "repos/$repo/pulls/$pr")
    title=$(jq -r '.title' <<<"$meta" | cut -c1-60 | tr '|' '/')
    created=$(jq -r '.created_at' <<<"$meta")
    merged=$(jq -r '.merged_at // empty' <<<"$meta")
    comments=$(gh api --paginate "repos/$repo/issues/$pr/comments" | jq -s 'add // []')
    rounds=$(contar_primera_linea "$RONDA" <<<"$comments")
    qas=$(contar_primera_linea "$QA" <<<"$comments")
    bodies=$(jq -r '.[].body' <<<"$comments")
    blk=$({ grep -o -E '\[(BLOQUEANTE|BLOCKER)\]' <<<"$bodies" || true; } | wc -l | tr -d ' ')
    imp=$({ grep -o -E '\[(IMPORTANTE|IMPORTANT)\]' <<<"$bodies" || true; } | wc -l | tr -d ' ')
    min=$({ grep -o -E '\[(MENOR|MINOR)\]' <<<"$bodies" || true; } | wc -l | tr -d ' ')
    # Sin sustitución de proceso: un fallo de gh (rate limit, red) tiene que abortar
    # y no convertirse en «0 commits, 0 merges».
    commits_json=$(gh api --paginate "repos/$repo/pulls/$pr/commits" | jq -s 'add // []')
    read -r work merges <<<"$(contar_commits "$created" <<<"$commits_json")"
    elapsed="-"
    [ -z "$merged" ] || elapsed=$(tiempo_entre "$created" "$merged")
    branch=$(jq -r '.head.ref | @uri' <<<"$meta")
    runs=$(gh api "repos/$repo/actions/runs?branch=$branch&per_page=100" --jq '.workflow_runs')
    failed=$(jq '[.[] | select(.conclusion=="failure")] | length' <<<"$runs")
    minutes=$(jq '[.[] | select(.conclusion=="success" or .conclusion=="failure") | ((.updated_at|fromdate)-(.run_started_at|fromdate))] | add // 0 | ./60 | floor' <<<"$runs")
    causes="-"
    if [ "$failed" -gt 0 ]; then
      causes=""
      for id in $(jq -r '.[] | select(.conclusion=="failure") | .id' <<<"$runs"); do
        c=$(causa "$repo" "$id")
        causes="${causes:+$causes; }${c:-sin test reconocido (run $id)}"
      done
    fi
    echo "| #$pr | $title | $rounds | $qas | $blk | $imp | $min | $work | $merges | $elapsed | $failed | $causes | $minutes |"
  done
  echo
  echo "_Cuentas aproximadas: las rondas son los comentarios que empiezan con el veredicto, una re-revisión o el cierre del skill \`pr-review\`; los hallazgos salen de sus etiquetas de severidad en todos los comentarios. «Merges» cuenta los commits con dos padres subidos tras abrir el PR: los de la base y, en una rama apilada, los de la rama de abajo. La causa de la falla es el primer test que falló en el log del run (\`gh run view --log-failed\`), si el log sigue disponible; si no reconoce ningún test, el job y el paso que fallaron. Revisa a mano los valores que no cuadren._"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then main "$@"; fi
