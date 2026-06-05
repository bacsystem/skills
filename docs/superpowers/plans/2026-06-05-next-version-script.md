# next-version.sh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a pure Bash helper that computes the next SemVer version from a current version and a Conventional Commit type, encapsulating the pre-1.0 rule, with a zero-dependency test runner.

**Architecture:** Two scripts under `git-flow/scripts/`: `next-version.sh` (the pure function) and `test-next-version.sh` (a plain-Bash test runner that shells out to it). TDD: the test runner is written first and must fail before the script exists. The skill prose (`SKILL.md` step 6, README Files list) is then pointed at the script.

**Tech Stack:** Bash (3.2+ compatible for macOS), no external dependencies.

**Spec:** `docs/superpowers/specs/2026-06-05-next-version-script-design.md`

---

## File Structure

- `git-flow/scripts/next-version.sh` — pure bump function: `(version, type) → version`. Stdout only; errors to stderr, exit 2.
- `git-flow/scripts/test-next-version.sh` — test runner: a table of cases + error cases, prints PASS/FAIL, exits non-zero on any failure.
- `git-flow/SKILL.md` — step 6 mentions the script (modify).
- `git-flow/README.md` — Files list gains both scripts (modify).

---

## Task 1: Test runner (failing first)

**Files:**
- Create: `git-flow/scripts/test-next-version.sh`

- [ ] **Step 1: Write the test runner with all cases**

```bash
#!/usr/bin/env bash
# Zero-dependency test runner for next-version.sh. Prints PASS/FAIL per case,
# exits non-zero if any case fails.
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
SUT="$here/next-version.sh"
fail=0

# check <desc> <expected> <args...>
check() {
  local desc="$1" expected="$2"; shift 2
  local got
  got="$("$SUT" "$@" 2>/dev/null)"
  if [ "$got" = "$expected" ]; then
    echo "PASS: $desc"
  else
    echo "FAIL: $desc — expected '$expected', got '$got'"
    fail=1
  fi
}

# check_err <desc> <args...> — expects exit code 2
check_err() {
  local desc="$1"; shift
  if "$SUT" "$@" >/dev/null 2>&1; then
    echo "FAIL: $desc — expected exit 2, got 0"
    fail=1
  else
    local code=$?
    if [ "$code" -eq 2 ]; then
      echo "PASS: $desc"
    else
      echo "FAIL: $desc — expected exit 2, got $code"
      fail=1
    fi
  fi
}

# Pre-1.0
check "0.2.2 fix"      0.2.3  0.2.2 fix
check "0.2.2 feat"     0.2.3  0.2.2 feat
check "0.2.2 breaking" 0.3.0  0.2.2 breaking
check "0.2.2 feat!"    0.3.0  0.2.2 feat!
check "0.9.9 chore"    0.9.10 0.9.9 chore

# >= 1.0
check "1.4.0 fix"      1.4.1  1.4.0 fix
check "1.4.0 feat"     1.5.0  1.4.0 feat
check "1.4.0 breaking" 2.0.0  1.4.0 breaking
check "1.4.0 major"    2.0.0  1.4.0 major
check "v1.0.0 chore"   1.0.1  v1.0.0 chore

# Errors (exit 2)
check_err "malformed 1.2"     1.2 fix
check_err "malformed abc"     abc fix
check_err "unknown type frob" 1.2.3 frob
check_err "missing args"      1.2.3

echo
if [ "$fail" -eq 0 ]; then
  echo "All tests passed."
else
  echo "Some tests FAILED."
fi
exit "$fail"
```

- [ ] **Step 2: Make it executable and run it (verify it fails)**

Run:
```bash
chmod +x git-flow/scripts/test-next-version.sh
git-flow/scripts/test-next-version.sh; echo "exit=$?"
```
Expected: every `check` line FAILs (SUT missing → empty output), error cases may pass/fail, and `exit=1`. The point: the runner works and is red.

- [ ] **Step 3: Commit the failing test**

```bash
git add git-flow/scripts/test-next-version.sh
git commit -m "test(git-flow): add failing tests for next-version.sh"
```

---

## Task 2: Implement `next-version.sh`

**Files:**
- Create: `git-flow/scripts/next-version.sh`
- Test: `git-flow/scripts/test-next-version.sh`

- [ ] **Step 1: Write the script**

```bash
#!/usr/bin/env bash
# Compute the next SemVer version from a current version and a Conventional
# Commit type. Pure: no files, no network, no state. Stdout = new version.
# Spec: docs/superpowers/specs/2026-06-05-next-version-script-design.md
set -euo pipefail

usage() {
  {
    echo "usage: next-version.sh <current-version> <type>"
    echo "  <current-version>  X.Y.Z (a leading 'v' is allowed)"
    echo "  <type>             feat|fix|docs|style|refactor|perf|test|build|ci|chore,"
    echo "                     or 'breaking'/'major', or any type with a trailing '!'"
  } >&2
  exit 2
}

[ "$#" -eq 2 ] || usage

raw_version="$1"
raw_type="$2"
version="${raw_version#v}"

if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "error: malformed version '$raw_version' (expected X.Y.Z)" >&2
  exit 2
fi

IFS='.' read -r major minor patch <<<"$version"

# Detect breaking: trailing '!', or the literal 'breaking'/'major'.
breaking=0
type="$raw_type"
case "$type" in
  *'!') breaking=1; type="${type%!}" ;;
esac
if [ "$type" = "breaking" ] || [ "$type" = "major" ]; then
  breaking=1
  type=""   # pure breaking keyword: no bare type to validate
fi

# Validate the bare type (when present).
if [ -n "$type" ]; then
  case " feat fix docs style refactor perf test build ci chore " in
    *" $type "*) : ;;
    *) echo "error: unknown type '$raw_type'" >&2; exit 2 ;;
  esac
fi

if [ "$major" -eq 0 ]; then
  # Pre-1.0: breaking bumps minor, everything else bumps patch.
  if [ "$breaking" -eq 1 ]; then
    minor=$((minor + 1)); patch=0
  else
    patch=$((patch + 1))
  fi
else
  # >= 1.0: standard SemVer.
  if [ "$breaking" -eq 1 ]; then
    major=$((major + 1)); minor=0; patch=0
  elif [ "$type" = "feat" ]; then
    minor=$((minor + 1)); patch=0
  else
    patch=$((patch + 1))
  fi
fi

echo "$major.$minor.$patch"
```

- [ ] **Step 2: Make it executable and run the tests (verify they pass)**

Run:
```bash
chmod +x git-flow/scripts/next-version.sh
git-flow/scripts/test-next-version.sh; echo "exit=$?"
```
Expected: all 14 lines `PASS`, final `All tests passed.`, `exit=0`.

- [ ] **Step 3: Lint with shellcheck if available (optional, non-blocking)**

Run:
```bash
command -v shellcheck >/dev/null && shellcheck git-flow/scripts/*.sh || echo "shellcheck not installed — skipped"
```
Expected: no warnings, or skipped. Fix any warning that changes behavior.

- [ ] **Step 4: Commit the implementation**

```bash
git add git-flow/scripts/next-version.sh
git commit -m "feat(git-flow): add next-version.sh bump helper"
```

---

## Task 3: Wire the script into the skill docs

**Files:**
- Modify: `git-flow/SKILL.md` (step 6, "Compute version")
- Modify: `git-flow/README.md` (Files list)

- [ ] **Step 1: Update SKILL.md step 6**

Replace the current step 6 line:
```
6. **Compute version** — read current version per precedence, apply the bump.
```
with:
```
6. **Compute version** — read current version per precedence, then apply the
   bump with `scripts/next-version.sh <current> <type>` (the canonical, tested
   implementation of the SemVer table, including the `0.x` rule). The
   Conventions table stays the human-readable reference.
```

- [ ] **Step 2: Update README.md Files list**

After the `verify-commands.md` line, add:
```
- [`scripts/next-version.sh`](./scripts/next-version.sh) — pure SemVer bump helper (version + type → next version).
- [`scripts/test-next-version.sh`](./scripts/test-next-version.sh) — zero-dependency tests for the bump helper.
```

- [ ] **Step 3: Re-run tests (sanity, docs-only change shouldn't break them)**

Run:
```bash
git-flow/scripts/test-next-version.sh; echo "exit=$?"
```
Expected: `exit=0`.

- [ ] **Step 4: Commit the docs wiring**

```bash
git add git-flow/SKILL.md git-flow/README.md
git commit -m "docs(git-flow): point compute-version step at next-version.sh"
```

---

## Shipping (after the plan)

Do NOT hand-roll the release. Run the `/git-flow` skill on this branch to:
classify (`feat` → pre-1.0 patch → `v0.2.3`), update `CHANGELOG.md`, push, and
open the PR. Tag `v0.2.3` manually after merge (auto-tag still blocked by the
org Actions billing).
