---
name: docs-sync
description: Use after every merge, when an epic or batch closes, when a decision is taken, and before answering any status question ("¿está cerrado X?", "¿qué falta?", "estado del proyecto", "what's left", "is X done") — whenever docs that assert a status (roadmap, "Estado:" lines, done/pending lists, versions, issue links) may have drifted from GitHub issues, PRs, tags, the Project board, version files or the code.
---

# docs-sync

## Resumen

La documentación que **afirma un estado** (roadmap, líneas «Estado:», qué está hecho o pendiente, versiones, enlaces a issues) se desfasa en cuanto se mergea algo. Un doc desfasado le da al dueño un falso positivo o una respuesta falsa cuando pregunta por el estado. Ejemplo típico: una épica se cierra, pero los docs siguen diciendo «todavía no hay backend», y en el tablero la épica figura «Por hacer» y las que bloqueaba, «Bloqueado».

**Principio:** el estado sale de las fuentes en vivo (GitHub, los archivos de versión, el código). Los docs y la memoria son copias. Cuando difieren, manda la fuente y el doc se corrige en el mismo momento, no «después».

## Cuándo se usa

- Después de cada merge.
- Al cerrar una épica o un lote.
- Al tomar una decisión que cambia qué está hecho, pendiente o bloqueado.
- **Antes de responder una pregunta de estado.** Ver «Pregunta de estado».

## Fuentes de verdad

| Qué | Dónde se mira |
|---|---|
| Issue o PR abierto o cerrado | `gh issue view N --json state,title` / `gh pr view N --json state,mergedAt` |
| Hijas de una épica | `gh api repos/<owner>/<repo>/issues/N/sub_issues --jq '.[] \| "#\(.number) \(.state)"'` y la checklist del cuerpo |
| Columna del tablero (Project) | `gh issue view N --json projectItems --jq '.projectItems[] \| "\(.title): \(.status.name)"'` |
| Versiones publicadas | `gh api repos/<owner>/<repo>/tags --jq '.[].name'` y el CHANGELOG |
| Versión declarada | `package.json`, `VERSION` u otro archivo de versión del proyecto |
| Qué existe de verdad | el código (`git ls-files`, la carpeta del módulo) |

## Flujo

1. **Docs de estado.** Los nombra el archivo de contexto del proyecto (`CLAUDE.md`, `GEMINI.md` o `AGENTS.md`). Si no los nombra, propón la lista (roadmap, README con estado, docs de proceso o de arquitectura con «Estado:», CHANGELOG) buscando con `grep -rlE 'Estado:|Status:|pendiente|por hacer|#[0-9]+' --include='*.md'`. Agrégala al archivo de contexto, en el que el proyecto declara como fuente si hay varios, dentro del mismo PR del paso 3.
2. **Chequeo.** Desde la raíz del repo, corre `bash <carpeta-de-este-skill>/scripts/check.sh "$(gh repo view --json nameWithOwner -q .nameWithOwner)" <doc.md>...` (el script viene con el skill, en `docs-sync/scripts/check.sh`). Es de solo lectura (`gh` y `jq`) y reporta `archivo:línea` por cada:
   - `#N` cerrado en una línea que dice «pendiente», o abierto en una que dice «hecho»;
   - `vX.Y.Z` mencionada que no existe como tag;
   - archivo de versión (`package.json`, `VERSION`) por debajo del último tag.

   Exit 0 sin desvíos, 1 con desvíos, 2 si no pudo correr (`gh` falló, sesión vencida, rate limit, `#N` inexistente). **Un exit 2 no es «limpio»:** arregla la causa y vuelve a correrlo, o reporta que no se pudo verificar.
3. **Lo que el script no ve**, a mano, sobre los mismos docs:
   - frases sin `#N` que contradicen la fuente («todavía no hay backend», «falta la auth»);
   - épicas: el estado de sus hijas y su columna en el tablero. Si una épica está cerrada y sigue «Por hacer», o las que dependían de ella siguen «Bloqueado», es un desvío;
   - las notas `nota: … revísala a mano` del script (líneas que dicen «hecho» y «pendiente» a la vez).
4. **Corrige cada desvío en un PR con el skill `git-flow`**, con una entrada `docs` en el CHANGELOG si el proyecto la lleva. En el PR va el doc que cambia y la evidencia de la fuente (`#N cerrado el …`, `tag vX.Y.Z`). El tablero se corrige con `gh project item-edit` solo si el dueño lo aprobó; si no, se lista en el reporte. Prefiere que el doc enlace al issue en vez de copiar su estado: así no se vuelve a desfasar.
5. **Reporta** en pocas líneas: cuántos desvíos, cuáles se corrigieron y en qué PR, y qué falta (tablero, frases dudosas, un exit 2).

## Pregunta de estado

Antes de contestar «¿está cerrado X?», «¿qué falta?», «¿en qué versión vamos?»:

1. Consulta la fuente en vivo: el estado del issue, sus hijas, su columna en el tablero, los PR abiertos que lo cierran y el último tag. Lanza las consultas en paralelo: son segundos.
2. Responde con lo que dice la fuente y nómbrala («según GitHub, ahora: #40 cerrado; #42 abierto, en revisión en el PR #57»).
3. Si un doc o la memoria dicen otra cosa, **dilo en la respuesta** («el roadmap todavía lo da por pendiente») y corrígelo en esa misma tarea (paso 4 del flujo). Eso no se pospone a «cuando haya tiempo».
4. Si una consulta falla, la respuesta es «no pude verificarlo», no el estado que dicen los docs.

## Errores comunes

| Error | Qué hacer |
|---|---|
| Responder desde el roadmap o la memoria porque «hay apuro» | La consulta tarda segundos; el apuro no cambia la fuente de verdad |
| Mirar solo los `#N` que el doc nombra | Una épica tiene hijas y columna en el tablero: revísalas también |
| Corregir solo el doc que motivó la pregunta | Corre el chequeo sobre todos los docs de estado del proyecto |
| Dejar la corrección «para después» | Va en un PR ya, con `git-flow`; si no se puede, queda en el reporte como pendiente con dueño |
| Tomar un exit 2 como «sin desvíos» | No se verificó nada: arregla `gh` y repítelo |
| Copiar el estado de una issue en el doc | Enlaza el issue; el estado copiado es el que se desfasa |

## Ajustes del chequeo

- `DOCS_SYNC_DONE_WORDS` y `DOCS_SYNC_PENDING_WORDS`: palabras extra (regex, separadas por `|`) que se suman a las de serie. Hecho: `hecho`, `done`, `cerrad…`, `completad…`, `merged`, `✅`. Pendiente: `pendiente`, `por hacer`, `bloquead…`, `todo`, `open`, `en curso`.
- `DOCS_SYNC_VERSION_FILES`: archivos de versión a comparar con el último tag (por defecto `package.json VERSION`; en un monorepo, por ejemplo `apps/web/package.json`).
- No cuentan los bloques de código, las entidades HTML (`&#123;`), las anclas de URL ni las versiones de otros paquetes (`repo#v1.2.3`, `pkg@v1.2.3`).
