# Fix mode

Entered when the user asks to apply findings ("fix H2", "CORRIGE", "corrige
todo") or when the project's `CLAUDE.md` or memory grants standing
authorization to correct findings before merge. Without one of the two, ask;
never start fixing on your own after a review.

1. **Scope.** Only the findings named, by ID. "Fix everything" means every
   finding under *must be fixed*; follow-ups are not included.
2. **Red first.** For each finding, write or run the test that fails while the
   defect exists (the report's "Proven by"), watch it fail, then fix. When no
   automated test can show it (a misleading doc line, a name), say what you
   checked instead.
3. **Verify.** Run the suites the change can affect. For a test you added or
   changed, break the code once on purpose and watch it go red (commit first;
   mutate committed files only).
4. **Commit and update.** Commit on the PR's branch with the finding ID in the
   message and correct the PR body wherever a number or claim it states
   changed (test counts, mutations, what was not run). **Push only to a branch
   that is the user's own, or when its owner has said you may.** On someone
   else's PR — or when you cannot tell — leave the commits local (or offer the
   patch) and say so: a standing authorization to *correct* findings is not
   permission to write to a third party's branch, which is public and can only
   be undone with a force-push.
5. **Report as a re-review table**: each ID resolved with its evidence
   (commit, `file:line`, test), and anything left out with the reason.

Never make a finding go away by weakening a test or widening an allowance.
Merging stays the user's call, and so does closing issues afterwards.
