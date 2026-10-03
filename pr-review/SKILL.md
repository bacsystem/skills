---
name: pr-review
description: Use when reviewing a pull request or a set of changes — your own or someone else's — for correctness (logic, edge cases, data types and validation) and against Clean Code, SOLID, DRY and development best practices, and you want an explicit verdict showing what is done well and what must be fixed. Supports --es/--en for the report language and --comment to post it on the GitHub PR. Also handles re-reviews after fixes, closing the previous findings by ID. Triggers include "review this PR", "revisá el PR", "code review", "what's wrong with these changes", or asking whether a branch is ready to merge.
---

# pr-review

## Overview

A code review that evaluates a pull request against five axes — correctness, Clean Code,
SOLID, DRY, and development best practices — and reports **what is done well**
and **what must be fixed**, ending in an explicit verdict.

It reviews and reports. It never edits files, commits, or merges.

## When to Use

- A PR is open and needs review before merging.
- The user asks "review this", "revisá el PR", "is this ready to merge?".
- A branch is finished and its quality needs assessing.

Skip when: the user wants the fixes *applied* — that is a separate task
requiring their explicit go-ahead after this review.

Works the same for the user's own PRs and for someone else's — authorship
never softens or sharpens a finding.

## Invocation

```
/pr-review <target> [--es|--en] [--comment]
```

| Flag | Effect |
|---|---|
| `--es` / `-es` | Report in Spanish. **Default when no language flag is given.** |
| `--en` / `-en` | Report in English. |
| `--comment` | After showing the report, offer to post it on the GitHub PR. |

Without `--comment` the report stays in the terminal — nothing is posted.

The section headers and verdict values are fixed per language (see **Output
format**); the flag switches which set is used, for both the terminal output
and the posted comment.

## Before reading the diff

1. **Read the repository's own conventions** — `CLAUDE.md`, `AGENTS.md`,
   `CONTRIBUTING.md`, and any QA/testing doc the repo points to. Judge the PR
   against what this repo established (branch targets, test bar, commit
   style, layering rules), not against a generic ideal. A PR that breaks a
   documented repo rule is a finding; one that ignores a rule the repo never
   adopted is not.
2. **Check whether this is a re-review.** If this PR was already reviewed —
   earlier in the conversation, or in a previous review comment on the PR
   (`gh pr view <n> --comments`) — use **Re-review mode** (below) instead of
   starting from zero.
3. **Read the linked issue, if there is one** — `gh pr view <n> --json
   closingIssuesReferences,body` for "Closes/Cierra/Fixes #N" or a plain
   "Refs #N", then `gh issue view <N>`. Its acceptance criteria are the
   definition of done for this PR. Check each one against the diff (met, not
   met, or not applicable) and report them in the **Issue criteria** section.
   Also flag scope creep: changes the issue never asked for that make the PR
   harder to review or revert.

## Getting the diff

Ask which target if none was given. Never guess.

| Target | Command |
|---|---|
| GitHub PR number | `gh pr diff <n>` |
| GitHub PR URL | `gh pr diff <url>` |
| Local branch | `git diff <base>...HEAD` |
| Uncommitted work | `git diff` (plus `git status` for new files) |

Read the **full diff** before judging anything. For files where the diff alone
is ambiguous (a changed function whose callers are off-diff, a new abstraction
whose purpose depends on existing code), open the surrounding file — a finding
based on a misread of partial context is a false positive, and false positives
cost more trust than a missed nitpick.

**Large diffs** (roughly 15+ files): group the files by layer or module and
review one group at a time, so no file is skimmed because it came late. End
the report with one line listing how many files were reviewed out of how many
changed — a file left unread must be visible, not silently skipped.

## Re-review mode

A second or third pass on the same PR, after its author applied fixes. The
point is to close the loop, not to re-judge everything from scratch:

1. **Previous findings first.** Open the report with a table of every finding
   from the last review, by its ID: resolved, partially resolved, or not
   resolved — each with the evidence (the commit, the `file:line`, the test
   that now covers it). "Resolved" needs evidence; the author saying so is not
   evidence.
2. **Review the new commits** (`git log <last-reviewed-sha>..HEAD`, or the
   commits since the previous review comment). A fix is new code: check it
   against the five axes like any other change. A fix that introduces a new
   defect — a misleading doc line, a weaker test, a regression elsewhere — is
   a new finding with its own ID.
3. **Don't repeat the previous "done well"** unless the new commits changed
   it. Praise only what the new commits did well.
4. Findings that were deliberately left out (the author argued against them,
   or they moved to a follow-up) are listed as such in the table, with the
   reason — not silently dropped and not re-reported as new.

## The evidence rule

**Every finding MUST cite `file:line` and state a concrete consequence** — the
input that produces the wrong output, or the specific maintenance cost. A
finding you cannot ground that way is not reported. Verify before asserting:
if a claim is checkable (run the test, read the caller, execute the snippet),
check it rather than asserting from pattern-matching.

Uncertain but plausible findings are allowed — mark them `[POSIBLE]` and say
what you could not verify. Never present a guess as a confirmed defect.

## Evaluation axes

Review against all five, correctness first — clean code that does the wrong
thing is still wrong. Judge the code as changed by this PR, not the whole
repository. Also check these references — they supplement, never replace,
the five axes below:

- `references/case-studies.md` — cross-cutting finding patterns learned
  from real reviews (how to catch a defect shape, regardless of language).
- `references/language-idioms.md` — known pitfalls specific to a language
  or framework. Check the section for the language actually in the diff, if
  one exists.
- `references/code-smells.md` — a catalog of smells, each with when it *is*
  a finding and when it is only taste.
- `references/production-readiness.md` — what breaks after the merge:
  migrations, API/config compatibility, operability, performance, frontend
  states and accessibility, new dependencies.

A checklist is where to look, not what to report. Every finding from any
axis or reference still needs `file:line` and a concrete consequence.

### 1. Correctness

The axis that catches bugs. Don't read the change and judge whether it
"looks right" — run inputs through it.

- **Trace the edge cases.** For each changed function or endpoint, follow
  these inputs through the code: empty / null / missing; zero, negative, the
  maximum and one past it (off-by-one); text with separators, quotes,
  newlines, unicode or leading/trailing spaces; a duplicate of something that
  already exists; the same request twice (retry after a timeout); two
  requests at the same time. Report the first input that produces a wrong
  result, a crash or corrupted data.
- **Error paths, not just the happy path.** What happens when the second of
  three writes fails — is anything left half-done? Is a failure swallowed,
  turned into a misleading success, or reported with a code the caller can't
  act on? Does a retry duplicate the effect?
- **Concurrency and ordering.** Shared state, read-then-write without a lock
  or a unique constraint, check-then-act races, caches that outlive what they
  cache, assumptions about the order of events or async callbacks.
- **Logic.** Inverted or incomplete conditions, a branch that can't be
  reached, a `switch`/`match` without the new enum value, boolean expressions
  that mean something other than their name, a loop that skips or repeats an
  element, a value used before it's set.
- **Time, money and units.** Time zones and DST, date-only vs instant,
  inclusive vs exclusive ranges; floating point for money, rounding mode and
  scale; mixed units. These are wrong silently, not loudly.
- **Data types and validation.** The type says what the value can be: a
  money amount in a decimal type, a closed set of values in an enum rather
  than a magic string, nullability explicit, IDs of different entities not
  interchangeable. Untrusted input is parsed once at the boundary into a
  validated value, and the inner layers trust it. The same rule (length,
  format, range) agrees across every layer it lives in — form, request DTO,
  domain, database column; a limit that exists in one layer and not the next
  turns a validation error into a 500 or a silent truncation.

### 2. Clean Code

- Names reveal intent — a reader should not need the implementation to know
  what a symbol does.
- Functions do one thing, at one level of abstraction.
- Nesting depth stays readable; guard clauses over nested conditionals.
- **Cognitive complexity.** Signals that a unit is harder to understand than
  it needs to be: more than 3 levels of nesting, a condition with more than 3
  operators, a function longer than ~40 lines, more than 4 parameters, a
  boolean parameter that switches behavior, the same variable reassigned
  across distant branches. These numbers tell you where to look; the finding
  is the concrete cost (a branch nobody can tell is reachable, a change that
  needs reading 80 lines first), never the number alone.
- **Code smells** (primitive obsession, feature envy, shotgun surgery,
  temporal coupling, god class, flag arguments…) — see
  `references/code-smells.md` for when each one is a finding.
- Comments explain **why**, not **what**. A comment restating the code is
  noise; a comment explaining a non-obvious decision is valuable.
- A comment's claim about what the code does or fixes must be verified, not
  assumed true — cross-check it against other evidence in the diff (a test,
  another file's comment). See `references/case-studies.md`.
- Errors are handled explicitly — no silent catch, no ignored return value.
- No dead code, commented-out blocks, or leftover debug output.

### 3. SOLID

- **S** — one reason to change per unit. A module doing HTTP, parsing, and
  formatting has three.
- **O** — behavior extends through parameters, composition, or new
  implementations rather than editing existing branching logic.
- **L** — a subtype/implementation honors its interface's contract; no
  overrides that throw or silently no-op where callers expect work.
- **I** — interfaces stay cohesive; consumers do not depend on members they
  never call.
- **D** — code crossing a layer boundary depends on an abstraction, not a
  concrete implementation.

### 4. DRY

- Duplicated logic or markup that should be extracted.
- **Distinguish real duplication from coincidental similarity.** Two pieces of
  code that look alike but change for different reasons are not duplication —
  merging them couples what should stay independent. Only report duplication
  where a single future change would have to be made in both places.

### 5. Development best practices

- Tests cover the change: new behavior has a test, fixed bugs have a
  regression test. Tests assert real outcomes, not that the mock was called.
- **Tests discriminate.** Coverage is not enough: a test can run the new code
  and still pass with it broken. Pick the one or two tests that guard the
  riskiest part of the change (authorization, money, data integrity, the
  bug being fixed) and name the production change that would make each one
  fail. If you can't name one — the test asserts something the change doesn't
  control, passes for an unrelated reason, or only checks that a call
  happened — that is a finding. When you can run the tests, break the code
  on purpose and watch the test go red instead of reasoning about it.
- **Fakes, mocks and clients match the real contract.** When the diff adds or
  changes a mock, a fake repository, an API client or a fixture, compare it
  with the real thing it stands for (the endpoint, the schema, the sibling
  PR that implements it): field names and casing, error codes, what is
  persisted and what is not. A mock that accepts what the real service
  rejects makes the tests green on a path that fails in production.
- **Claims in the PR description and docs are verified.** Test counts,
  "N/N mutations", "tested in Docker", "no behavior change" — cross-check
  them against the reports, the test diff or the commands shown. A number
  nobody can reproduce from the evidence is a finding.
- No hardcoded values that belong in configuration — style values (colors,
  spacing, typography), URLs, timeouts, magic numbers.
- **No secrets in the diff** — keys, tokens, connection strings, credentials.
  This is always the blocking severity. Name the file and line, never quote
  the secret's value — the report may end up in a public PR comment.
- Security: input validation at trust boundaries, authorization checks not
  bypassable, no injection-prone string building.
- Consistency with the repository's existing patterns — a PR that invents a
  parallel convention alongside an established one adds cost.
- **What breaks after the merge** — check the parts of
  `references/production-readiness.md` that the diff touches:
  - *Migrations*: safe to run on a live table (locks, `NOT NULL` without a
    default, backfills inside one transaction), and what happens on rollback.
  - *Compatibility*: a renamed field, changed error code or changed default
    breaks existing clients, integrators or stored data.
  - *Configuration*: new environment variables documented, with a safe
    default and a clear failure when they are missing or invalid.
  - *Operability*: a failure leaves enough trace to diagnose it; no swallowed
    error without a log, metric or user-visible signal.
  - *Performance visible in a diff*: N+1 queries, unbounded result sets,
    missing index for a new filter, slow work while holding a lock.
  - *Frontend*: loading, empty and error states, double submit, accessibility
    (roles, labels, focus), sensitive data reaching the browser or a cache.
  - *Dependencies*: a new one is justified, maintained, license-compatible and
    pinned.

## Severity

| `--es` | `--en` | Meaning |
|---|---|---|
| `BLOQUEANTE` | `BLOCKER` | Breaks correctness, security, or data integrity. Must not merge. |
| `IMPORTANTE` | `IMPORTANT` | Real defect or design problem. Should be fixed in this PR. |
| `MENOR` | `MINOR` | Worth improving, does not block the merge. |

An unverified but plausible finding is marked `[POSIBLE]` / `[POSSIBLE]`.

## Output format

Always the three core sections — done well, must be fixed, verdict — in this
order. Optional sections frame them: **previous findings** (only in re-review
mode, first), **issue criteria** (only when the PR links an issue, next) and
**follow-ups** (only when there is a real one, after the corrections). Use the
wording matching the language flag (`--es` is the default).

**Issue criteria and the verdict.** A PR that says it *closes* an issue while
a criterion is not met gets a finding (`IMPORTANTE` / `IMPORTANT`): either
meet the criterion or change "Closes" to "Refs" and say what is left. A PR
that only references the issue can leave criteria open, as long as it says so.

**Every finding gets an ID** (`H1`, `H2`… in Spanish, `F1`, `F2`… in English),
numbered in report order and kept across re-reviews: the user asks to fix
"H2", and the next review reports H2 as resolved. A new finding in a later
pass takes the next free number, never a reused one.

**Each finding says how to prove it**: the test (existing or to write) that
fails while the defect is there. That gives the fix a red test to start from.
If no automated test can show it (a misleading doc line, a naming issue), say
what to check instead.

**Spanish (`--es`):**

```
## 🔁 Hallazgos anteriores          ← solo en re-revisión
| ID | Estado | Evidencia |
|---|---|---|
| H1 | ✅ Resuelto | commit abc123, `archivo:línea`, test `nombreDelTest` |
| H2 | ⚠️ Parcial | qué falta |
| H3 | ➖ Descartado | por qué se dejó fuera (argumento del autor o pasó a seguimiento) |

## 🎯 Criterios del issue #N          ← solo si la PR enlaza un issue
| Criterio | Estado | Dónde |
|---|---|---|
| texto del criterio | ✅ Cumplido / ❌ No cumplido / ➖ No aplica | `archivo:línea` o test |

## ✅ Lo que está bien
- [archivo:línea] — qué decisión concreta del diff está bien resuelta y por qué

## ⚠️ Debe corregirse
- **H1** [BLOQUEANTE] [archivo:línea] — el defecto, su consecuencia concreta, y el cambio que lo resuelve. *Lo demuestra:* el test que falla mientras exista.
- **H2** [IMPORTANTE] [archivo:línea] — ídem
- **H3** [MENOR] [archivo:línea] — ídem

## 📌 Seguimiento                    ← opcional
- [archivo:línea] — mejora real pero fuera del alcance de esta PR; no se corrige aquí y no cuenta para el veredicto.

## Veredicto
APROBADO | APROBADO CON CAMBIOS | REQUIERE CORRECCIONES
Archivos revisados: N/N             ← en diffs grandes
```

**English (`--en`):**

```
## 🔁 Previous findings              ← re-review only
| ID | Status | Evidence |
|---|---|---|
| F1 | ✅ Resolved | commit abc123, `file:line`, test `testName` |
| F2 | ⚠️ Partial | what is still missing |
| F3 | ➖ Dropped | why it was left out (author's argument, or moved to follow-up) |

## 🎯 Issue #N criteria               ← only when the PR links an issue
| Criterion | Status | Where |
|---|---|---|
| the criterion's text | ✅ Met / ❌ Not met / ➖ N/A | `file:line` or test |

## ✅ What's done well
- [file:line] — which concrete decision in the diff is well resolved, and why

## ⚠️ Must be fixed
- **F1** [BLOCKER] [file:line] — the defect, its concrete consequence, and the change that resolves it. *Proven by:* the test that fails while it exists.
- **F2** [IMPORTANT] [file:line] — same
- **F3** [MINOR] [file:line] — same

## 📌 Follow-ups                     ← optional
- [file:line] — a real improvement outside this PR's scope; not fixed here and not counted in the verdict.

## Verdict
APPROVED | APPROVED WITH CHANGES | CHANGES REQUIRED
Files reviewed: N/N                 ← on large diffs
```

**Follow-ups are not a softer severity.** Use them for something worth doing
that does not belong in this change — a refactor that needs a second
consumer to justify it, an issue the PR exposes but doesn't cause. When the
user says "fix the findings", follow-ups are not included. Uncertain findings
still go in *must be fixed* marked `[POSIBLE]`; a follow-up is certain but
out of scope.

Verdict rules (identical in both languages):

- Any blocker → `REQUIERE CORRECCIONES` / `CHANGES REQUIRED`.
- Any important, no blockers → `APROBADO CON CAMBIOS` / `APPROVED WITH CHANGES`.
- Only minor findings, or none → `APROBADO` / `APPROVED`.

Order findings most severe first.

## Posting to the PR (`--comment`)

Only when `--comment` was passed. Without it, the report stays in the terminal
and nothing is posted.

1. **Confirm the target before posting.** Run `gh pr view <target> --json
   number,title,url,author` and show the user the repo, PR number, title and
   author you are about to comment on. A comment on a public PR — especially
   someone else's — cannot be cleanly unpublished.
2. **Show the exact comment body** and ask for explicit confirmation. A bare
   "yes" to the review itself is not consent to post it.
3. On confirmation, post it as a single issue comment:
   `gh pr comment <target> --body-file <path>`
   Write the body to a temp file rather than inlining it — review bodies
   contain backticks, quotes and newlines that break shell escaping.
4. Report the resulting comment URL from `gh`'s output.
5. If `gh` is unavailable or unauthenticated, say so and print the body for
   the user to paste manually. Never fail silently.

The posted comment is the same sections, prefixed with one line naming
what was reviewed:

```
Code review de `<base>...<head>` — corrección, Clean Code, SOLID, DRY y buenas prácticas.
```

Post **one** comment per review. Never open a GitHub *review* with
approve/request-changes state — the verdict is text in the comment, not a
GitHub approval. Approving a PR is the human's call.

## Rules

- **"Lo que está bien" is not filler.** Cite real decisions from the diff —
  a well-drawn boundary, a test that pins the actual edge case, a name that
  removed the need for a comment. Generic praise ("clean code", "good
  structure") is worse than saying there is nothing notable. If there is
  nothing notable, say so in one line.
- **Never invent findings to fill the corrections section.** Zero findings is a
  valid result and reporting it honestly is the point of the review.
- **Never edit, commit, push, or merge.** If the user wants the fixes applied,
  that is a new task and needs their explicit go-ahead.
- **Never post without `--comment` and an explicit confirmation.** Publishing
  to a PR is outward-facing and, on someone else's PR, public.
- **Same standard regardless of authorship.** The user's own PR gets the same
  scrutiny as a stranger's; a third party's PR gets the same fairness as the
  user's. When commenting on someone else's PR, address the change, never the
  person.
- Works regardless of the repository's programming language — the axes are
  language-neutral, the idioms are not. Judge against the conventions of the
  language and framework actually in the diff.

## Growing this skill

After a real review surfaces something worth keeping, add it to the file
that matches its shape — don't add findings that are project-specific,
one-off, or already covered by an existing entry or axis bullet:

- **A finding technique or defect shape that applies across languages**
  (e.g. "verify a comment's claim against other evidence in the same
  diff") → `references/case-studies.md`. Short, generalized entry: pattern
  name, axis, what to watch for, how to verify it, one abstracted example
  — no project/PR-specific names.
- **A pitfall specific to one language or framework** (e.g. "Go: ignored
  error from `os.Create`", "Next.js: function prop crossing the
  Server→Client boundary") → `references/language-idioms.md`, under that
  language's heading (add the heading if it's the first entry for that
  language). Short bullet: pattern name, what to look for, the concrete
  consequence.
- **A smell that turned out to be a real defect** → `references/code-smells.md`,
  with the signal that separated it from taste.
- **Something that broke after a merge** (a migration, a config default, a
  client that depended on a field) → `references/production-readiness.md`.

The reference files grow over time — skim them during every review, not just
after writing to them.

## Common Mistakes

- **Padding "lo que está bien"** with generic praise so the section is not empty.
- **Reporting style preferences as defects** — if a linter or formatter would not
  flag it and it does not affect readability, it is not a finding.
- **Flagging duplication that is coincidental** — see the DRY axis.
- **Judging on a partial diff** — read the surrounding file when the change's
  correctness depends on off-diff context.
- **Findings without `file:line`** or without a concrete consequence.
- **Reviewing only the shape of the code** — names, SOLID and DRY on a change
  that returns the wrong result for an empty list. Correctness comes first.
- **Reporting a metric instead of a cost** — "this function has 6 parameters"
  is a signal to look; the finding is what it makes hard or wrong.
- **Turning the checklists into findings** — walking every bullet of every
  reference and reporting each one that "could apply". A reference is where
  to look; only what the diff actually gets wrong is reported.
- **Ignoring the linked issue** — approving a PR that says it closes an issue
  while one of its acceptance criteria is not met.
- **Applying fixes mid-review** — this skill reports only.
- **Reviewing the whole repository** instead of the change.
- **Posting without `--comment`**, or posting on a bare "yes" that only
  approved the review, not its publication.
- **Mixing languages** — the whole report follows one flag; the default is
  Spanish.
- **Quoting a secret's value** in a finding that may be posted publicly — cite
  the location, not the value.
- **Opening a GitHub review with approve/request-changes** instead of a plain
  comment — the verdict is text, not a GitHub approval.
- **Re-reviewing from scratch** — re-listing the whole PR as if new, instead
  of closing the previous findings by ID and reviewing the new commits.
- **Taking "resolved" on trust** — a previous finding is resolved when the
  evidence shows it, not when the author or the commit message says so.
- **Counting a test as protection because it runs the code** — ask what
  change would make it fail; a test that stays green with the behavior
  broken protects nothing.
- **Parking a real defect in follow-ups** to keep the verdict clean — a
  follow-up is out of scope, not less severe.
