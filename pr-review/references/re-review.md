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
   evidence. A finding whose closure depends on a mutation or a run (the test
   now goes red, the bound now holds) stays **open** until that run happens:
   "resolved in the code, verification pending" is open, and a mutation
   *reasoned* to go red does not close it. When the environment cannot run it
   (Docker down, no credentials), the finding stays open and the report says
   what is waiting on what; reasoning about a mutation is exactly how a test
   seeded with the code's own constant survives.
2. **Review the new commits** (`git log <last-reviewed-sha>..HEAD`, or the
   commits since the previous review comment). A fix is new code: check it
   against the five axes like any other change. A fix that introduces a new
   defect — a misleading doc line, a weaker test, a regression elsewhere — is
   a new finding with its own ID. If the new commits include a merge of the
   base, read that merge's diff too (*Merges of the base* in `SKILL.md`).
   Before approving, recheck step 0 on the new head: no conflict, and the
   checks ran green on that SHA.
3. **Don't repeat the previous "done well"** unless the new commits changed
   it. Praise only what the new commits did well.
4. Findings that were deliberately left out (the author argued against them,
   or they moved to a follow-up) are listed as such in the table, with the
   reason — not silently dropped and not re-reported as new.
