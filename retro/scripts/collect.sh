#!/usr/bin/env bash
# Junta las métricas de un lote de PR para la retrospectiva: rondas de revisión,
# hallazgos por severidad, tiempo hasta el merge y duración y fallos de la CI.
# Uso: retro/scripts/collect.sh <owner/repo> <PR> [<PR>...]
# Solo lee (gh api). Escribe Markdown por stdout.
set -euo pipefail
[ $# -ge 2 ] || { echo "uso: $0 <owner/repo> <PR> [<PR>...]" >&2; exit 2; }
repo=$1; shift
command -v gh >/dev/null || { echo "falta gh" >&2; exit 2; }
command -v jq >/dev/null || { echo "falta jq" >&2; exit 2; }

echo "| PR | Título | Rondas de revisión | Bloq. | Imp. | Men. | Commits tras abrir | Horas hasta merge | CI fallida | Minutos de CI |"
echo "|---|---|---|---|---|---|---|---|---|---|"
for pr in "$@"; do
  case "$pr" in *[!0-9]*) echo "PR inválido: $pr" >&2; exit 2;; esac
  meta=$(gh api "repos/$repo/pulls/$pr")
  title=$(jq -r '.title' <<<"$meta" | cut -c1-60 | tr '|' '/')
  created=$(jq -r '.created_at' <<<"$meta")
  merged=$(jq -r '.merged_at // empty' <<<"$meta")
  head=$(jq -r '.head.sha' <<<"$meta")
  comments=$(gh api --paginate "repos/$repo/issues/$pr/comments" --jq '.[].body')
  # Una ronda es un comentario de revisión o re-revisión publicado en el PR.
  rounds=$(grep -c -E '^(## )?(Re-revisión|Revisión|Code review|Re-review)|Veredicto|Verdict' <<<"$comments" || true)
  blk=$({ grep -o -E '\[(BLOQUEANTE|BLOCKER)\]' <<<"$comments" || true; } | wc -l | tr -d ' ')
  imp=$({ grep -o -E '\[(IMPORTANTE|IMPORTANT)\]' <<<"$comments" || true; } | wc -l | tr -d ' ')
  min=$({ grep -o -E '\[(MENOR|MINOR)\]' <<<"$comments" || true; } | wc -l | tr -d ' ')
  commits=$(gh api --paginate "repos/$repo/pulls/$pr/commits" --jq '.[].commit.committer.date' | awk -v c="$created" '$0 > c' | wc -l | tr -d ' ')
  hours="-"
  if [ -n "$merged" ]; then
    hours=$(jq -n --arg a "$created" --arg b "$merged" '(($b|fromdate)-($a|fromdate))/3600 | floor')
  fi
  runs=$(gh api "repos/$repo/actions/runs?branch=$(jq -r '.head.ref' <<<"$meta")&per_page=100" --jq '.workflow_runs')
  failed=$(jq '[.[] | select(.conclusion=="failure")] | length' <<<"$runs")
  minutes=$(jq '[.[] | select(.conclusion=="success" or .conclusion=="failure") | ((.updated_at|fromdate)-(.run_started_at|fromdate))] | add // 0 | ./60 | floor' <<<"$runs")
  echo "| #$pr | $title | $rounds | $blk | $imp | $min | $commits | $hours | $failed | $minutes |"
done
echo
echo "_Cuentas aproximadas: las rondas y los hallazgos salen de los comentarios publicados, buscando las etiquetas de severidad del skill \`pr-review\`. Revisa a mano los valores que no cuadren._"
