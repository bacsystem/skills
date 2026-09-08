# pr-review

A Claude Code skill that reviews a pull request against **Clean Code, SOLID,
DRY and development best practices**, and reports what is done well and what
must be fixed — ending in an explicit verdict.

It reviews and reports. It never edits files, commits, or merges.

## How to use it

**1. Explicit slash command:**

```
/pr-review 42
/pr-review https://github.com/org/repo/pull/42
```

**2. Natural language** — Claude activates it from the skill description:

```
review this PR
revisá el PR 42
code review de estos cambios
is this branch ready to merge?
```

If no target is given, the skill asks which PR or branch to review.

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

| Severity | Meaning | Effect on verdict |
|---|---|---|
| `BLOQUEANTE` | Breaks correctness, security, or data integrity | `REQUIERE CORRECCIONES` |
| `IMPORTANTE` | Real defect or design problem | `APROBADO CON CAMBIOS` |
| `MENOR` | Worth improving, does not block | `APROBADO` |

## Design rules

- **Every finding cites `file:line` and a concrete consequence.** A finding that
  cannot be grounded that way is not reported.
- **Zero findings is a valid result** — the skill never invents defects to fill
  the corrections section.
- **"Lo que está bien" cites real decisions from the diff**, never generic
  praise. If there is nothing notable, it says so.
- **Uncertain findings are marked `[POSIBLE]`** with what could not be verified.

## Files

- [`SKILL.md`](./SKILL.md) — the full skill definition (the authoritative spec).

## Installation

Symlink the skill into your personal skills directory so repo edits apply
immediately:

```bash
ln -snf "$(pwd)/pr-review" ~/.claude/skills/pr-review
```

Then start a new Claude Code session and use `/pr-review`.
