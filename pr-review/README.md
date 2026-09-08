# pr-review

A Claude Code skill that reviews a pull request — **yours or someone else's** —
against **Clean Code, SOLID, DRY and development best practices**, and reports
what is done well and what must be fixed, ending in an explicit verdict.
Optionally posts the review as a comment on the GitHub PR.

It reviews and reports. It never edits files, commits, or merges.

## How to use it

**1. Explicit slash command:**

```
/pr-review 42
/pr-review https://github.com/org/repo/pull/42
/pr-review 42 --en
/pr-review 42 --comment
/pr-review 42 --en --comment
```

**2. Natural language** — Claude activates it from the skill description:

```
review this PR
revisá el PR 42
code review de estos cambios
is this branch ready to merge?
```

If no target is given, the skill asks which PR or branch to review.

### Flags

| Flag | Effect |
|---|---|
| `--es` / `-es` | Report in Spanish. **Default** when no language flag is given. |
| `--en` / `-en` | Report in English. |
| `--comment` | After showing the report, offer to post it on the GitHub PR. |

Without `--comment` the report stays in the terminal — nothing is posted.
With it, the skill shows you the exact comment body and the target PR
(repo, number, title, author) and **asks before posting**. It posts one plain
comment; it never opens a GitHub review with approve/request-changes — the
verdict is text, and approving a PR stays your call.

> Prerequisite for reviewing a GitHub PR: `gh` installed and authenticated
> (`gh auth status`). For a local branch or uncommitted work, plain `git` is
> enough.

## What it evaluates

| Axis | What it checks |
|---|---|
| **Clean Code** | Intent-revealing names, single-purpose functions, nesting, comments that explain *why*, explicit error handling, dead code |
| **SOLID** | One reason to change, extension over modification, contract-honoring implementations, cohesive interfaces, depending on abstractions across layers |
| **DRY** | Real duplication that must be extracted — distinguished from coincidental similarity |
| **Best practices** | Test coverage of the change, hardcoded values, secrets, security at trust boundaries, consistency with existing repo patterns |

## Output

```
## ✅ Lo que está bien
- [archivo:línea] — qué decisión concreta está bien resuelta y por qué

## ⚠️ Debe corregirse
- [BLOQUEANTE] [archivo:línea] — el defecto, su consecuencia, y el cambio que lo resuelve
- [IMPORTANTE] [archivo:línea] — ídem
- [MENOR] [archivo:línea] — ídem

## Veredicto
APROBADO | APROBADO CON CAMBIOS | REQUIERE CORRECCIONES
```

With `--en`, the same three sections come back as *What's done well* /
*Must be fixed* / *Verdict*.

| `--es` | `--en` | Meaning | Verdict |
|---|---|---|---|
| `BLOQUEANTE` | `BLOCKER` | Breaks correctness, security, or data integrity | `REQUIERE CORRECCIONES` / `CHANGES REQUIRED` |
| `IMPORTANTE` | `IMPORTANT` | Real defect or design problem | `APROBADO CON CAMBIOS` / `APPROVED WITH CHANGES` |
| `MENOR` | `MINOR` | Worth improving, does not block | `APROBADO` / `APPROVED` |

## Design rules

- **Every finding cites `file:line` and a concrete consequence.** A finding that
  cannot be grounded that way is not reported.
- **Zero findings is a valid result** — the skill never invents defects to fill
  the corrections section.
- **"Lo que está bien" cites real decisions from the diff**, never generic
  praise. If there is nothing notable, it says so.
- **Uncertain findings are marked `[POSIBLE]` / `[POSSIBLE]`** with what could
  not be verified.
- **Same standard regardless of authorship** — your own PR gets the same
  scrutiny as a stranger's, and a third party's gets the same fairness as
  yours. Comments address the change, never the person.
- **Nothing is published without `--comment` and your explicit confirmation.**

## Files

- [`SKILL.md`](./SKILL.md) — the full skill definition (the authoritative spec).

## Installation

Symlink the skill into your personal skills directory so repo edits apply
immediately:

```bash
ln -snf "$(pwd)/pr-review" ~/.claude/skills/pr-review
```

Then start a new Claude Code session and use `/pr-review`.
