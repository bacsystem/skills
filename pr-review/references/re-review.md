# Re-review mode

Read from `SKILL.md` (step 2 of *Before reading the diff*) when this PR was
already reviewed — earlier in the conversation, or in a previous review
comment on the PR. The report template (`🔁 Hallazgos anteriores`) and the
finding-ID rule stay in `SKILL.md`.

A second or third pass on the same PR, after its author applied fixes. The
point is to close the loop, not to re-judge everything from scratch:

1. **Previous findings first.** Open the report with a table of every finding
   from the last review, by its ID: resolved, partially resolved, or not
   resolved — each with the evidence (the commit, the `file:line`, the test
   that now covers it). "Resolved" needs evidence; the author saying so is not
   evidence.
2. **Review the new commits** (`git log <last-reviewed-sha>..HEAD`, or the
   commits since the previous review comment). A fix is new code: check it
   against the five axes like any other change. A fix that introduces a new
   defect — a misleading doc line, a weaker test, a regression elsewhere — is
   a new finding with its own ID.
3. **Don't repeat the previous "done well"** unless the new commits changed
   it. Praise only what the new commits did well.
4. Findings that were deliberately left out (the author argued against them,
   or they moved to a follow-up) are listed as such in the table, with the
   reason — not silently dropped and not re-reported as new.
