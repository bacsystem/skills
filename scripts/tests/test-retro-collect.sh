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

# Rondas e informes que abren sin `#` ni negrita, como los publica `pr-review`
# en la práctica, y falsos positivos que nombran la QA más adelante.
sin_marcado='[
  {"body": "Code review de `main...feat/x` (`abc1234`): corrección. La QA va aparte.\n\n**Veredicto: APROBADO**"},
  {"body": "Re-revisión del coordinador · `abc..def` (solo docs)."},
  {"body": "Re-revisión 3 de `abc..def` (`def`): corrección."},
  {"body": "## /pr-review · #7 (docs, cambio chico)"},
  {"body": "Code review y QA de `a...b` (`49cc584`): corrección y criterios."},
  {"body": "## Revisión + QA PR #9 (SHA 561185b)"},
  {"body": "**QA #254, SHA `d724521`: APRUEBA.** Chromium real."},
  {"body": "## Re-QA PR #248 - SHA 72f8416: APTO"},
  {"body": "Nota del coordinador sobre el paso pendiente de la QA: corrió en la CI."},
  {"body": "Fix for H1 and H2 (commit da49ab3). Review probe numbers below."},
  {"body": "## Code review de `main...feat/x`: corrección. La QA va aparte."}
]'
igual "rondas sin marcado" 7 "$(contar_primera_linea "$RONDA" <<<"$sin_marcado")"
igual "informes de QA sin marcado, sin falsos positivos" 4 "$(contar_primera_linea "$QA" <<<"$sin_marcado")"

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
esc=$'\x1b'
vitest_log="checks (lint, unit)${tab}Run pnpm test${tab}2026-11-20T06:00:19.2959374Z ${esc}[41m${esc}[1m FAIL ${esc}[22m${esc}[49m src/a.test.tsx${esc}[2m > ${esc}[22mLogin${esc}[2m > ${esc}[22mpide esperar"
igual "falla de Vitest con colores ANSI" "checks: src/a.test.tsx > Login > pide esperar" "$(primer_test_fallido <<<"$vitest_log")"
# Así lo escribe `gh run view --log-failed`: el ESC como el texto «^[».
vitest_gh="checks (lint, unit)${tab}Run pnpm test${tab}2026-11-20T06:00:19.2959374Z ^[[41m^[[1m FAIL ^[[22m^[[49m src/a.test.tsx^[[2m > ^[[22mLogin"
igual "falla de Vitest con «^[» literal" "checks: src/a.test.tsx > Login" "$(primer_test_fallido <<<"$vitest_gh")"
jobs='{"jobs": [
  {"name": "web (lint)", "conclusion": "success", "steps": [{"name": "lint", "conclusion": "success"}]},
  {"name": "api (gofmt, vet, test)", "conclusion": "failure", "steps": [
    {"name": "go test", "conclusion": "success"},
    {"name": "OpenAPI lint", "conclusion": "failure"},
    {"name": "build", "conclusion": "skipped"}]}
]}'
igual "paso que falló, sin test reconocido" "api: paso «OpenAPI lint»" "$(paso_fallido <<<"$jobs")"
igual "sin job fallido" "" "$(paso_fallido <<<'{"jobs": []}')"
jobs_pipe='{"jobs": [{"name": "ci (a)", "conclusion": "failure", "steps": [{"name": "lint | build\nfinal", "conclusion": "failure"}]}]}'
igual "paso con «|» y salto de línea, en una celda" "ci: paso «lint / build final»" "$(paso_fallido <<<"$jobs_pipe")"

[ "$fallos" -eq 0 ] && echo "All tests passed." || { echo "$fallos fallo(s)."; exit 1; }
