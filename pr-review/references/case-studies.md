# Case studies

Concrete finding patterns learned from real reviews, kept separate from
`SKILL.md` so the main skill stays short. These supplement the four axes —
they don't replace them. Check new PRs against these in addition to the
checklist in `SKILL.md`.

Each entry: **Axis** it extends, **Watch for** (the generalized signal),
**Verify** (how to confirm it's real, not a guess), **Example** (abstracted,
not tied to the original project).

---

### A comment asserts a fix that isn't actually verified

**Axis:** Clean Code (comments) / evidence rule

**Watch for:** A comment claiming a piece of code "fixes", "solves",
"prevents", "makes X instant/converge/stop", especially near a
workaround, polyfill, or performance mitigation. These read as confident
statements of fact, which makes them easy to accept at face value instead
of checking.

**Verify:** Cross-check the claim against other evidence in the *same*
diff — a co-located test that still needs an inflated timeout, a
benchmark, another file's own documentation of the same issue. If nothing
in the diff substantiates the claim, or another part of the same diff
contradicts it, that's a finding: the comment overstates what was actually
verified, and a future reader will trust it and skip investigating further.

**Example:** A test-setup file adds a polyfill with a comment saying "this
makes the async operation resolve instantly," while a test file changed in
the *same PR* still carries a 40-second timeout for that same operation,
with its own comment documenting that the polyfill didn't fix the slowness.
The two comments contradict each other — only one is true, and nothing
flags the discrepancy without reading both files together.

---

<!--
Template for the next entry — copy this block, fill it in, generalize away
project-specific names/paths, delete this comment's contents when adding
the first real entry after this one.

### <short pattern name>

**Axis:** <Clean Code | SOLID | DRY | Best practices | Cross-cutting>

**Watch for:** <the generalized signal — what to notice in a diff>

**Verify:** <the concrete step that confirms it's real, not assumed>

**Example:** <one abstracted example, no project/PR-specific names>
-->
