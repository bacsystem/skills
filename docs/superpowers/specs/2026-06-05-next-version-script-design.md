# Design — `next-version.sh` for the git-flow skill

**Date:** 2026-06-05
**Status:** Approved (pending spec review)
**Scope:** A single, pure helper script that computes the next SemVer version
from a current version and a Conventional Commit type, encapsulating the
pre-1.0 (`0.x`) rule that the skill prose currently relies on the model to
apply correctly.

## Problem

The `git-flow` skill computes the version bump (step 6) from prose rules. The
trickiest rule — pre-1.0 SemVer, where `feat` is a patch and a breaking change
is a minor — is exactly the one a model can forget, which is the bug fixed in
v0.2.2. Moving the *bump arithmetic* into a deterministic script makes that
rule impossible to get wrong, while leaving judgment-heavy steps (detecting the
current version, resolving the remote) as model-guided prose.

## Interface

```
next-version.sh <current-version> <type>
```

- `<current-version>`: `X.Y.Z`. A leading `v` is tolerated and stripped.
  Must match `^v?[0-9]+\.[0-9]+\.[0-9]+$`, else error.
- `<type>`: a Conventional Commit type (`feat`, `fix`, `docs`, `style`,
  `refactor`, `perf`, `test`, `build`, `ci`, `chore`) **or** a breaking marker.
  Breaking is any of: the literal `breaking`, the literal `major`, or any type
  with a trailing `!` (`feat!`, `fix!`, `chore!`, …).
- **stdout:** the new version, bare (no `v`): e.g. `0.2.3`.
- **stderr + exit code:** malformed version or unknown type → message on
  stderr, exit `2`. Wrong argument count → usage on stderr, exit `2`.
- **Purity:** no network, no file reads, no state. Input → output only.

## Bump logic

Normalize: strip leading `v`; detect breaking (trailing `!`, or `breaking`/
`major`); strip the `!` before matching the bare type.

| Change | `X = 0` (pre-1.0) | `X ≥ 1` |
|---|---|---|
| breaking | bump **minor**, reset patch (`0.2.3`→`0.3.0`) | bump **major**, reset minor+patch (`1.4.0`→`2.0.0`) |
| `feat` | bump **patch** (`0.2.3`→`0.2.4`) | bump **minor**, reset patch (`1.4.0`→`1.5.0`) |
| any other type | bump **patch** | bump **patch** |

This mirrors the table already in `SKILL.md` (Conventions + the Pre-1.0
tie-breaker); the script is the executable form of that prose.

## Testing — `test-next-version.sh`

Plain Bash, **zero dependencies** (no `bats`), portable across macOS/Linux. It
runs a table of `input → expected` cases, compares actual stdout, prints
`PASS`/`FAIL` per case, and exits non-zero if any case fails. Cases:

- Pre-1.0: `0.2.2 fix → 0.2.3`, `0.2.2 feat → 0.2.3`, `0.2.2 breaking → 0.3.0`,
  `0.2.2 feat! → 0.3.0`, `0.9.9 chore → 0.9.10`.
- ≥ 1.0: `1.4.0 fix → 1.4.1`, `1.4.0 feat → 1.5.0`, `1.4.0 breaking → 2.0.0`,
  `1.4.0 major → 2.0.0`, `v1.0.0 chore → 1.0.1`.
- Errors (assert exit code `2`): `1.2` (malformed), `abc` (malformed),
  `1.2.3 frob` (unknown type), missing args.

This also gives the repo its first test runner, so the skill's own **Verify**
step (and `references/verify-commands.md`'s "generic / shell" row via
`shellcheck` and a project-defined test) finally has something to run.

## Files

- `git-flow/scripts/next-version.sh` (executable)
- `git-flow/scripts/test-next-version.sh` (executable)

## Skill integration

- `SKILL.md` step 6 (**Compute version**): mention the script as the canonical
  way to compute the bump — `next-version.sh <current> <type>` — keeping the
  prose table as the human-readable reference.
- `README.md`: add both scripts to the Files list.

## Out of scope (YAGNI)

- Auto-detecting the current version (judgment-heavy → stays model-guided).
- Pre-release / build-metadata identifiers (`-rc.1`, `+build`).
- Reading or writing `CHANGELOG.md`/`package.json` (the script only computes).

## Versioning of this change

Adds a new capability to the skill → `feat`. Repo is pre-1.0, so `feat` is a
**patch**: `v0.2.2` → `v0.2.3`.
