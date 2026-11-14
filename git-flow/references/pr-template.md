<!-- PR template for the git-flow skill. Fill in and use as the `gh pr create` body. Written in English. -->

## Summary

<!-- One or two sentences: what this PR does and why. -->

## Type of change

<!-- Mark the relevant one. -->
- [ ] feat — new feature
- [ ] fix — bug fix
- [ ] docs — documentation only
- [ ] refactor — code change that neither fixes a bug nor adds a feature
- [ ] perf — performance improvement
- [ ] test — adding or fixing tests
- [ ] build / ci — build system or CI changes
- [ ] chore — other changes that don't modify src or tests
- [ ] BREAKING CHANGE — incompatible API change

## Main changes

<!-- Bullet list of the key changes. -->
-

## Verification

<!-- Commands actually run, with their counts (e.g. `./gradlew test` → 812
passed, BUILD SUCCESSFUL). Mark each "passes locally" or "verified against
<environment>". Anything not run: "not run: <reason>". The reviewer checks
these numbers. -->
-

## Linked issue

<!-- `Closes #N` only if every acceptance criterion is met; otherwise `Refs #N`
and which criteria remain open. Into `develop`, neither closes the issue on
merge. -->

## Deploy & rollback

<!-- Only when the PR has a migration, a contract artifact (OpenAPI, schema) or
a new/renamed environment variable. Deploy order; whether the migration can be
undone and what happens if the release is reverted; new variables with their
default; the contract artifact regenerated in this same PR. Delete otherwise. -->

## Breaking changes

<!-- Only for a BREAKING CHANGE: what broke and what a consumer has to do to
migrate. Delete this section otherwise. -->

## Version

<!-- SemVer bump and new version, e.g. minor → v1.2.0 -->
- Bump: <!-- major | minor | patch -->
- New version: <!-- vX.Y.Z -->

## Checklist

- [ ] Code reviewed (bugs, conventions, simplifications)
- [ ] CHANGELOG.md updated
- [ ] Version updated in the relevant file(s)
- [ ] README updated (if applicable)
- [ ] Tests pass (if applicable), read from the full output
- [ ] No secrets or credential files in the diff
- [ ] Merges cleanly into the base branch
