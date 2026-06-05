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
