# git-flow

A Claude Code skill that takes changes from the working tree to a pull request,
following consistent conventions: branch naming, code review, Conventional
Commits, automatic SemVer, and a PR template. It is **guided, not blind** — it
pauses for your confirmation at the review, doc-update, and PR steps.

## How to use it

There are three ways to trigger the skill:

**1. Explicit slash command** — most direct:

```
/git-flow
```

**2. Natural language** — Claude activates it from the skill description:

```
ship this
commit and open a PR
create the PR for these changes
I'm done with this fix, take it from here
```

**3. By context** — after finishing a feature or fix, just ask Claude to wrap up
the work and it will pick up the workflow (branch → review → commit → version →
PR), pausing for your confirmation at the review, doc-update, and PR steps.

> Prerequisite for the PR step: `gh` installed and authenticated
> (`gh auth status`). Without it, the skill prints the PR body and a compare URL
> instead of creating the PR.

## What it does

1. **Detect context** — changes, version files, push remote, `gh` auth.
2. **Classify** — one Conventional Commit type + SemVer bump.
3. **Create branch** — `type/description` (e.g. `feat/login-form`).
4. **Code review** — bugs, conventions, simplifications.
5. **Verify** — run the project's test/lint command; stop if it fails.
6. **Compute version** — per source precedence, apply the bump.
7. **Update docs** — CHANGELOG, version files, README (shown before staging).
8. **Stage & commit** — Conventional Commit message in English.
9. **Push & PR** — builds the body from the template, asks before creating.
10. **Tag after merge** — `vX.Y.Z` on `main`.

## Conventions

| Aspect | Rule |
|---|---|
| Branch | `type/description`, kebab-case |
| Commit | [Conventional Commits](https://www.conventionalcommits.org/), in English |
| SemVer | `feat` → minor · `fix` → patch · `BREAKING CHANGE` → major |
| Version source | `package.json` → `VERSION` → `git tag` → `CHANGELOG.md` |
| PR | Via `gh`, asks before creating |

## Tagging

This repository ships an [`auto-tag` workflow](../.github/workflows/auto-tag.yml)
that reads the latest version from `CHANGELOG.md` and creates the matching
`vX.Y.Z` tag when changes land on `main`.

> **Heads-up:** the workflow only runs where GitHub Actions is enabled. While
> Actions is unavailable (e.g. an org with billing disabled), the tag is **not**
> created automatically — tag manually after merge:
>
> ```bash
> git tag -a vX.Y.Z -m "vX.Y.Z" && git push <remote> vX.Y.Z
> ```

## Files

- [`SKILL.md`](./SKILL.md) — the full skill definition (the authoritative spec).
- [`references/pr-template.md`](./references/pr-template.md) — PR body template.
- [`references/verify-commands.md`](./references/verify-commands.md) — per-ecosystem test/lint commands for the Verify step.
- [`scripts/next-version.sh`](./scripts/next-version.sh) — pure SemVer bump helper (version + type → next version).
- [`scripts/test-next-version.sh`](./scripts/test-next-version.sh) — zero-dependency tests for the bump helper.

## Installation

Symlink the skill into your personal skills directory so repo edits apply
immediately:

```bash
ln -snf "$(pwd)/git-flow" ~/.claude/skills/git-flow
```

Then start a new Claude Code session and use `/git-flow`.
