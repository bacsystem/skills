#!/usr/bin/env bash
# Prueba el parseo de retro/scripts/collect.sh sin red: carga sus funciones con
# `source` y las alimenta con comentarios, commits y logs de ejemplo.
# Uso: scripts/tests/test-retro-collect.sh [ruta a collect.sh]
set -u
script="${1:-$(cd "$(dirname "$0")/../.." && pwd)/retro/scripts/collect.sh}"
# shellcheck source=/dev/null
source "$script"
set +e
fallos=0
igual() { # $1 = nombre, $2 = esperado, $3 = obtenido
  if [ "$2" = "$3" ]; then echo "PASS: $1"; else echo "FALLA: $1 (esperado «$2», obtenido «$3»)"; fallos=$((fallos + 1)); fi
}

# Dos revisiones (veredicto en la primera línea y re-revisión), un cierre, un
# informe de QA cuyo veredicto está en la tercera línea, y un comentario con
# «Veredicto» repetido dentro de una tabla, que no es una ronda.
comentarios='[
  {"body": "**Veredicto: APROBADO CON CAMBIOS** · 0 bloqueantes\n\n| H1 | Veredicto |\n| Veredicto | x |"},
  {"body": "## Re-revisión · `abc..def`\n\nVeredicto: APROBADO\nVerdict: APPROVED"},
  {"body": "## Cierre de la revisión\n\n**Veredicto:** APROBADO"},
  {"body": "# QA del PR #1\n\n**Veredicto: APROBADO**"},
  {"body": "Gracias, corrijo H1.\nVeredicto pendiente"},
  {"body": "**Verdict: APPROVED** · 0 blockers"},
  {"body": "## 🧪 QA del PR #1\n\nVeredicto: APROBADO"},
  {"body": "## Informe de QA\n\nVeredicto: APROBADO"},
  {"body": "Sin QA todavía"}
]'
igual "rondas por comentario" 4 "$(contar_primera_linea "$RONDA" <<<"$comentarios")"
igual "informes de QA (con o sin emoji)" 3 "$(contar_primera_linea "$QA" <<<"$comentarios")"
igual "sin comentarios" 0 "$(contar_primera_linea "$RONDA" <<<'[]')"

commits='[
  {"commit": {"committer": {"date": "2026-11-19T09:00:00Z"}}, "parents": [{}]},
  {"commit": {"committer": {"date": "2026-11-19T11:00:00Z"}}, "parents": [{}]},
  {"commit": {"committer": {"date": "2026-11-19T12:00:00Z"}}, "parents": [{}, {}]},
  {"commit": {"committer": {"date": "2026-11-19T13:00:00Z"}}, "parents": [{}]}
]'
igual "commits de trabajo y merges tras abrir" "2 1" "$(contar_commits 2026-11-19T10:00:00Z <<<"$commits")"

igual "minutos" "42 min" "$(tiempo_entre 2026-11-19T10:00:00Z 2026-11-19T10:42:30Z)"
igual "horas con un decimal" "1.5 h" "$(tiempo_entre 2026-11-19T10:00:00Z 2026-11-19T11:31:00Z)"

tab=$'\t'
go_log="api (gofmt, vet, test)${tab}go test${tab}2026-11-19T15:17:50.7457684Z --- FAIL: TestConcurrentRecords (1.65s)"
igual "falla de Go" "api: TestConcurrentRecords" "$(primer_test_fallido <<<"$go_log")"
pw_log="e2e (playwright)${tab}UNKNOWN STEP${tab}2026-11-19T02:14:02.5934890Z   ✘   93 [desktop] › e2e/a.spec.ts:3:5 › agenda: abre el cajón (7.2s)"
igual "falla de Playwright" "e2e: [desktop] › e2e/a.spec.ts:3:5 › agenda: abre el cajón" "$(primer_test_fallido <<<"$pw_log")"
igual "log sin test reconocido" "" "$(primer_test_fallido <<<"build${tab}step${tab}2026-11-19T00:00:00Z Error: exit 1")"

[ "$fallos" -eq 0 ] && echo "All tests passed." || { echo "$fallos fallo(s)."; exit 1; }
