---
name: git-flow
description: Use when changes are ready to ship and you need to go from working tree to pull request — staging, reviewing, conventional commit, version bump, and PR. Triggers include "commit and open a PR", "ship this", "create the PR", finishing a feature/fix, or preparing a release.
---

# git-flow

## Overview

A guided workflow that takes changes from the working tree to a pull request,
following consistent conventions: branch naming, code review, Conventional
Commits, automatic SemVer, and a PR template. **Guided, not blind** — confirm
with the user at the review, doc-update, and PR steps.

## When to Use

- Changes are done and ready to be committed and shared.
- User says "ship this", "commit and open a PR", "create the PR".
- A feature or fix is finished and needs a branch + commit + PR.

Skip when: the user only wants a quick local commit with no review/PR.

## Conventions

| Aspect | Rule |
|---|---|
| Branch | `type/description`, kebab-case (e.g. `feat/login-form`) |
| Commit | [Conventional Commits](https://www.conventionalcommits.org/), in **English** |
| Types | `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore` |
| SemVer | `feat` → minor · `fix` → patch · `BREAKING CHANGE` (or `!`) → major |
| Other types | `docs`/`style`/`refactor`/`perf`/`test`/`build`/`ci`/`chore` → patch |
| Tag | Created **after** the PR merges to `main`, not on the branch |
| PR | Via `gh`, **ask before creating** |

## Rules & tie-breakers

- **One authoritative type.** Classify the change ONCE (step 2). That type drives
  the branch name, the commit, and the SemVer bump. They must agree.
- **Mixed changes:** pick the highest-impact type for the version
  (`BREAKING` > `feat` > `fix` > everything else). If the diff contains clearly
  separate logical changes, make separate commits; otherwise one commit.
- **Branch description:** kebab-case derived from the commit subject, ≤ 5 words
  (e.g. subject "add token refresh on 401" → `feat/token-refresh`).
- **Version source precedence:** `package.json` → `VERSION` → latest `git tag`
  → `CHANGELOG.md`. Strip a leading `v`. If two sources disagree, use the highest.
  If no source records a version, start from `0.1.0` and create `CHANGELOG.md`.
- **Staging:** only stage the reviewed files plus the docs you updated. Never
  `git add -A` / `git add .` blindly.
- **"Changes" = ** tracked modifications (staged or unstaged) and/or new files.
  Whitespace-only or no changes → stop.

## Workflow

Run in order. Stop and report if a precondition fails.

1. **Detect context** — `git status` / `git diff`; stop if no changes. Detect
   version files (`package.json`, `VERSION`, `CHANGELOG.md`, `README.md`).
   Check `gh auth status`.
2. **Classify** — pick the one Conventional Commit type and the SemVer bump
   (see Conventions + tie-breakers).
3. **Create branch** — if on `main`/`master`, `git switch -c type/description`.
   If already on a work branch, keep it.
4. **Code review** — review the diff for bugs, convention issues, and
   simplifications. Show findings; continue after the user's OK.
5. **Compute version** — read current version per precedence, apply the bump.
6. **Validate & update docs** — list the files to update and **show the user
   before staging**:
   - `CHANGELOG.md`: add `## [X.Y.Z] - YYYY-MM-DD` with the right section
     (`Added`/`Changed`/`Fixed`/etc.); replace an `[Unreleased]` block if present.
   - Version in `package.json` / `VERSION` if they exist.
   - `README.md` only if the change affects documented behavior.
   Apply after confirmation.
7. **Stage & commit** — `git add` the relevant files; Conventional Commit message
   in English. Scope optional (derive from path only if obvious).
8. **Push & PR (ask first)** — `git push -u origin <branch>`. Build the PR body
   from `references/pr-template.md` (if missing, use a minimal Summary/Changes/
   Version body). PR base `main`, title = commit subject. **Show the body and ask
   before creating.** On confirmation: `gh pr create`. If `gh` is unavailable,
   output the body and the compare URL instead.
9. **Tag after merge** — once the PR is merged to `main`:
   `git tag -a vX.Y.Z -m "vX.Y.Z"` and `git push origin vX.Y.Z`. Skip if the tag
   already exists.

## Common Mistakes

- **Tagging on the feature branch** — the tag goes on `main` after merge (step 9).
- **Committing on `main`** — branch first (step 3) unless already on a work branch.
- **Assuming `package.json`** — follow the version-source precedence; detect first.
- **`git add -A`** — stage only reviewed + updated files.
- **Spanish commit/PR text** — commits and PR are English; only the chat is Spanish.
- **Staging before showing doc updates** — show changes in step 6 before `git add`.

## PR Template

See `references/pr-template.md`.
