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
| SemVer (≥ 1.0) | `feat` → minor · `fix` → patch · `BREAKING CHANGE` (or `!`) → major |
| Other types | `docs`/`style`/`refactor`/`perf`/`test`/`build`/`ci`/`chore` → patch |
| SemVer (`0.x`) | `BREAKING` → minor (`0.y`→`0.(y+1)`, resets patch) · everything else → patch |
| PR base | `develop` if that branch exists (local or on the remote), else `main` |
| Tag | Created **after** the PR merges, and only if that merge's base was `main` — a merge into `develop` is not a release, see step 10 |
| PR | Via `gh`, **ask before creating** |

## Rules & tie-breakers

- **One authoritative type.** Classify the change ONCE (step 2). That type drives
  the branch name, the commit, and the SemVer bump. They must agree.
- **Mixed changes:** pick the highest-impact type for the version
  (`BREAKING` > `feat` > `fix` > everything else). If the diff contains clearly
  separate logical changes, make separate commits; otherwise one commit.
- **Pre-1.0 (`0.x.y`):** SemVer is still unstable, so the normal table does NOT
  apply. A `BREAKING CHANGE`/`!` bumps the *minor* (`0.2.3` → `0.3.0`); `feat`,
  `fix`, and every other type bump the *patch* (`0.2.3` → `0.2.4`). Use the
  ≥ 1.0 rules only once the project actually reaches `1.0.0`.
- **Branch description:** kebab-case derived from the commit subject, ≤ 5 words
  (e.g. subject "add token refresh on 401" → `feat/token-refresh`).
- **Version source precedence:** `package.json` → `VERSION` → latest `git tag`
  → `CHANGELOG.md`. Strip a leading `v`. If two sources disagree, use the highest.
  If no source records a version, start from `0.1.0` and create `CHANGELOG.md`.
- **Staging:** only stage the reviewed files plus the docs you updated. Never
  `git add -A` / `git add .` blindly.
- **Remote:** never hardcode `origin`. Resolve the push remote from
  `git remote -v` — prefer the current branch's upstream if one is set, else the
  sole remote, else ask which to use. Some repos push through an SSH-alias remote
  (e.g. `git@host-alias:org/repo.git`) whose name is not `origin`. Use the
  resolved remote name for the push (step 9) and the post-merge tag (step 10).
- **Changes** = tracked modifications (staged or unstaged) and/or new files.
  Whitespace-only or no changes → stop.

## Workflow

Run in order. Stop and report if a precondition fails.

1. **Detect context** — `git status` / `git diff`; stop if no changes. Detect
   version files (`package.json`, `VERSION`, `CHANGELOG.md`, `README.md`).
   Resolve the push remote (`git remote -v`; see the Remote rule). Detect
   whether a `develop` branch exists (`git show-ref --verify --quiet
   refs/heads/develop` or `refs/remotes/<remote>/develop`) — if so, it's the
   PR base for this run (GitFlow repo); otherwise the base is `main`. Check
   `gh auth status`.
2. **Classify** — pick the one Conventional Commit type and the SemVer bump
   (see Conventions + tie-breakers).
3. **Create branch** — if on `main`/`master`, `git switch -c type/description`.
   If already on a work branch, keep it.
4. **Code review** — review the diff for bugs, convention issues, and
   simplifications. Show findings; continue after the user's OK.
5. **Verify** — detect the project's test/lint command and run it (see
   `references/verify-commands.md` for the per-ecosystem mapping). Prefer a
   command the repo already defines (scripts, `Makefile` targets, CI) over a
   generic guess. **Stop and report if it fails;** continue once green. If the
   project has no test/lint setup, say so and move on — don't fabricate a command.
6. **Compute version** — read current version per precedence, then apply the
   bump with `scripts/next-version.sh <current> <type>` (the canonical, tested
   implementation of the SemVer table, including the `0.x` rule). The
   Conventions table stays the human-readable reference.
7. **Validate & update docs** — list the files to update and **show the user
   before staging**:
   - `CHANGELOG.md`: add `## [X.Y.Z] - YYYY-MM-DD` with the right section
     (`Added`/`Changed`/`Fixed`/etc.); replace an `[Unreleased]` block if present.
   - Version in `package.json` / `VERSION` if they exist.
   - `README.md` only if the change affects documented behavior.
   Apply after confirmation.
8. **Stage & commit** — `git add` the relevant files; Conventional Commit message
   in English. Scope optional (derive from path only if obvious).
9. **Push & PR (ask first)** — `git push -u <remote> <branch>` (the remote
   resolved in step 1). Build the PR body from `references/pr-template.md` (if
   missing, use a minimal Summary/Changes/Version body). PR base is the branch
   resolved in step 1 (`develop` if it exists, else `main`), title = commit
   subject. **Show the body and ask before creating.** On confirmation:
   `gh pr create --base <resolved base>`. If `gh` is unavailable, output the
   body and the compare URL instead.
10. **Tag after merge** — once the PR is merged, tag **only if its base was
    `main`**: `git tag -a vX.Y.Z -m "vX.Y.Z"` and `git push <remote> vX.Y.Z`.
    Skip if the tag already exists. If the base was `develop`, don't tag here —
    that merge is an integration step, not a release; the tag happens later
    when `develop` is promoted to `main` (release/hotfix branch), which is
    outside this skill's scope.

## Common Mistakes

- **Tagging on the feature branch** — the tag goes on `main` after merge (step 10).
- **Tagging a `develop` merge** — only tag when the PR's base was `main`; a merge into
  `develop` is an integration step, not a release.
- **Hardcoding PR base to `main`** — detect a `develop` branch first (step 1); GitFlow
  repos merge feature branches into `develop`, not `main`.
- **Committing on `main`** — branch first (step 3) unless already on a work branch.
- **Assuming `package.json`** — follow the version-source precedence; detect first.
- **Hardcoding `origin`** — resolve the real remote (step 1); some repos use an SSH-alias remote.
- **Over-bumping a `0.x` project** — pre-1.0, `feat` is a patch and a breaking change is a minor.
- **Skipping tests** — run the project's test/lint command (step 5) before committing.
- **`git add -A`** — stage only reviewed + updated files.
- **Spanish commit/PR text** — commits and PR are English; only the chat is Spanish.
- **Staging before showing doc updates** — show changes in step 7 before `git add`.

## PR Template

See `references/pr-template.md`.
