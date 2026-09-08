---
name: pr-review
description: Use when reviewing a pull request or a set of changes — your own or someone else's — against Clean Code, SOLID, DRY and development best practices, and you want an explicit verdict showing what is done well and what must be fixed. Supports --es/--en for the report language and --comment to post it on the GitHub PR. Triggers include "review this PR", "revisá el PR", "code review", "what's wrong with these changes", or asking whether a branch is ready to merge.
---

# pr-review

## Overview

A code review that evaluates a pull request against four axes — Clean Code,
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

## The evidence rule

**Every finding MUST cite `file:line` and state a concrete consequence** — the
input that produces the wrong output, or the specific maintenance cost. A
finding you cannot ground that way is not reported. Verify before asserting:
if a claim is checkable (run the test, read the caller, execute the snippet),
check it rather than asserting from pattern-matching.

Uncertain but plausible findings are allowed — mark them `[POSIBLE]` and say
what you could not verify. Never present a guess as a confirmed defect.

## Evaluation axes

Review against all four. Judge the code as changed by this PR, not the whole
repository.

### 1. Clean Code

- Names reveal intent — a reader should not need the implementation to know
  what a symbol does.
- Functions do one thing, at one level of abstraction.
- Nesting depth stays readable; guard clauses over nested conditionals.
- Comments explain **why**, not **what**. A comment restating the code is
  noise; a comment explaining a non-obvious decision is valuable.
- Errors are handled explicitly — no silent catch, no ignored return value.
- No dead code, commented-out blocks, or leftover debug output.

### 2. SOLID

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

### 3. DRY

- Duplicated logic or markup that should be extracted.
- **Distinguish real duplication from coincidental similarity.** Two pieces of
  code that look alike but change for different reasons are not duplication —
  merging them couples what should stay independent. Only report duplication
  where a single future change would have to be made in both places.

### 4. Development best practices

- Tests cover the change: new behavior has a test, fixed bugs have a
  regression test. Tests assert real outcomes, not that the mock was called.
- No hardcoded values that belong in configuration — style values (colors,
  spacing, typography), URLs, timeouts, magic numbers.
- **No secrets in the diff** — keys, tokens, connection strings, credentials.
  This is always the blocking severity. Name the file and line, never quote
  the secret's value — the report may end up in a public PR comment.
- Security: input validation at trust boundaries, authorization checks not
  bypassable, no injection-prone string building.
- Consistency with the repository's existing patterns — a PR that invents a
  parallel convention alongside an established one adds cost.

## Severity

| `--es` | `--en` | Meaning |
|---|---|---|
| `BLOQUEANTE` | `BLOCKER` | Breaks correctness, security, or data integrity. Must not merge. |
| `IMPORTANTE` | `IMPORTANT` | Real defect or design problem. Should be fixed in this PR. |
| `MENOR` | `MINOR` | Worth improving, does not block the merge. |

An unverified but plausible finding is marked `[POSIBLE]` / `[POSSIBLE]`.

## Output format

Always these three sections, in this order. Use the wording matching the
language flag (`--es` is the default).

**Spanish (`--es`):**

```
## ✅ Lo que está bien
- [archivo:línea] — qué decisión concreta del diff está bien resuelta y por qué

## ⚠️ Debe corregirse
- [BLOQUEANTE] [archivo:línea] — el defecto, su consecuencia concreta, y el cambio que lo resuelve
- [IMPORTANTE] [archivo:línea] — ídem
- [MENOR] [archivo:línea] — ídem

## Veredicto
APROBADO | APROBADO CON CAMBIOS | REQUIERE CORRECCIONES
```

**English (`--en`):**

```
## ✅ What's done well
- [file:line] — which concrete decision in the diff is well resolved, and why

## ⚠️ Must be fixed
- [BLOCKER] [file:line] — the defect, its concrete consequence, and the change that resolves it
- [IMPORTANT] [file:line] — same
- [MINOR] [file:line] — same

## Verdict
APPROVED | APPROVED WITH CHANGES | CHANGES REQUIRED
```

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

The posted comment is the same three sections, prefixed with one line naming
what was reviewed:

```
Code review de `<base>...<head>` — Clean Code, SOLID, DRY y buenas prácticas.
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

## Common Mistakes

- **Padding "lo que está bien"** with generic praise so the section is not empty.
- **Reporting style preferences as defects** — if a linter or formatter would not
  flag it and it does not affect readability, it is not a finding.
- **Flagging duplication that is coincidental** — see the DRY axis.
- **Judging on a partial diff** — read the surrounding file when the change's
  correctness depends on off-diff context.
- **Findings without `file:line`** or without a concrete consequence.
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
