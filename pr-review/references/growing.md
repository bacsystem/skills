# Growing this skill

Read this only when a review surfaced something worth keeping. Add it to the
file that matches its shape — don't add findings that are project-specific,
one-off, or already covered by an existing entry or axis bullet:

- **A finding technique or defect shape that applies across languages**
  (e.g. "verify a comment's claim against other evidence in the same
  diff") → `case-studies.md`. Short, generalized entry: pattern name, axis,
  what to watch for, how to verify it, one abstracted example — no
  project/PR-specific names.
- **A pitfall specific to one language or framework** (e.g. "Go: ignored
  error from `os.Create`", "Next.js: function prop crossing the
  Server→Client boundary") → `language-idioms.md`, under that language's
  heading (add the heading if it's the first entry for that language). Short
  bullet: pattern name, what to look for, the concrete consequence.
- **A smell that turned out to be a real defect** → `code-smells.md`, with the
  signal that separated it from taste.
- **Something that broke after a merge** (a migration, a config default, a
  client that depended on a field) → `production-readiness.md`.

The reference files grow over time. During a review, read the ones whose
trigger in `SKILL.md` (*Which reference to read, and when*) matches the diff —
not only after writing to them.
