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
check "1.4.0 feat!"    2.0.0  1.4.0 feat!

# Errors (exit 2)
check_err "malformed 1.2"     1.2 fix
check_err "malformed abc"     abc fix
check_err "unknown type frob" 1.2.3 frob
check_err "too few args"      1.2.3
check_err "too many args"     1.2.3 fix extra

echo
if [ "$fail" -eq 0 ]; then
  echo "All tests passed."
else
  echo "Some tests FAILED."
fi
exit "$fail"
