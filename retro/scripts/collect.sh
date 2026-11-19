#!/usr/bin/env bash
# Junta las métricas de un lote de PR para la retrospectiva: rondas de revisión,
# informes de QA, hallazgos por severidad, commits de trabajo y merges de la base,
# tiempo hasta el merge y fallos (con su causa) y duración de la CI.
# Uso: retro/scripts/collect.sh <owner/repo> <PR> [<PR>...]
# Solo lee (gh api, gh run view). Escribe Markdown por stdout.
set -euo pipefail
[ $# -ge 2 ] || { echo "uso: $0 <owner/repo> <PR> [<PR>...]" >&2; exit 2; }
repo=$1; shift
command -v gh >/dev/null || { echo "falta gh" >&2; exit 2; }
command -v jq >/dev/null || { echo "falta jq" >&2; exit 2; }

# Una ronda es un comentario cuya primera línea abre una revisión, una re-revisión
# o el cierre de la revisión (el formato de `pr-review`). Las líneas «Veredicto»
# de dentro de un comentario (tablas de cierre, informes de QA) no cuentan.
ronda='^(\*\*)?(Veredicto|Verdict)|^#+ (Re-revisión|Re-review|Revisión|Review|Code review|Cierre|Closing)'
qa='^#+ QA'

# Primer test que falló en el log de un run, con el job: Go (`--- FAIL:`),
# Playwright (`✘`) o Vitest/Jest (`FAIL`). Vacío si no hay log o no se reconoce.
causa() {
  { gh run view "$1" --repo "$repo" --log-failed 2>/dev/null || true; } | awk -F'\t' '
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

echo "| PR | Título | Rondas de revisión | Informes de QA | Bloq. | Imp. | Men. | Commits de trabajo | Merges de la base | Hasta el merge | CI fallida | Causa de la falla | Minutos de CI |"
echo "|---|---|---|---|---|---|---|---|---|---|---|---|---|"
for pr in "$@"; do
  case "$pr" in *[!0-9]*) echo "PR inválido: $pr" >&2; exit 2;; esac
  meta=$(gh api "repos/$repo/pulls/$pr")
  title=$(jq -r '.title' <<<"$meta" | cut -c1-60 | tr '|' '/')
  created=$(jq -r '.created_at' <<<"$meta")
  merged=$(jq -r '.merged_at // empty' <<<"$meta")
  comments=$(gh api --paginate "repos/$repo/issues/$pr/comments" | jq -s 'add // []')
  rounds=$(jq --arg r "$ronda" '[.[] | select(.body | split("\n")[0] | test($r))] | length' <<<"$comments")
  qas=$(jq --arg r "$qa" '[.[] | select(.body | split("\n")[0] | test($r))] | length' <<<"$comments")
  bodies=$(jq -r '.[].body' <<<"$comments")
  blk=$({ grep -o -E '\[(BLOQUEANTE|BLOCKER)\]' <<<"$bodies" || true; } | wc -l | tr -d ' ')
  imp=$({ grep -o -E '\[(IMPORTANTE|IMPORTANT)\]' <<<"$bodies" || true; } | wc -l | tr -d ' ')
  min=$({ grep -o -E '\[(MENOR|MINOR)\]' <<<"$bodies" || true; } | wc -l | tr -d ' ')
  # Commits subidos después de abrir el PR: los de trabajo y los merges de la base
  # (un commit con dos padres) van en columnas separadas.
  commits=$(gh api --paginate "repos/$repo/pulls/$pr/commits" | jq -s --arg c "$created" \
    '[add // [] | .[] | select(.commit.committer.date > $c) | (.parents | length > 1)]')
  work=$(jq '[.[] | select(. == false)] | length' <<<"$commits")
  merges=$(jq '[.[] | select(. == true)] | length' <<<"$commits")
  elapsed="-"
  if [ -n "$merged" ]; then
    elapsed=$(jq -rn --arg a "$created" --arg b "$merged" '
      ((($b|fromdate) - ($a|fromdate)) / 60) as $m
      | if $m < 60 then "\($m | floor) min" else "\(($m / 6 | round) / 10) h" end')
  fi
  runs=$(gh api "repos/$repo/actions/runs?branch=$(jq -r '.head.ref' <<<"$meta")&per_page=100" --jq '.workflow_runs')
  failed=$(jq '[.[] | select(.conclusion=="failure")] | length' <<<"$runs")
  minutes=$(jq '[.[] | select(.conclusion=="success" or .conclusion=="failure") | ((.updated_at|fromdate)-(.run_started_at|fromdate))] | add // 0 | ./60 | floor' <<<"$runs")
  causes="-"
  if [ "$failed" -gt 0 ]; then
    causes=""
    for id in $(jq -r '.[] | select(.conclusion=="failure") | .id' <<<"$runs"); do
      c=$(causa "$id")
      causes="${causes:+$causes; }${c:-sin test reconocido (run $id)}"
    done
  fi
  echo "| #$pr | $title | $rounds | $qas | $blk | $imp | $min | $work | $merges | $elapsed | $failed | $causes | $minutes |"
done
echo
echo "_Cuentas aproximadas: las rondas son los comentarios que empiezan con el veredicto, una re-revisión o el cierre del skill \`pr-review\`; los hallazgos salen de sus etiquetas de severidad en todos los comentarios. La causa de la falla es el primer test que falló en el log del run (\`gh run view --log-failed\`), si el log sigue disponible. Revisa a mano los valores que no cuadren._"
