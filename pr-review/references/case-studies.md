# Case studies

Concrete finding patterns learned from real reviews, kept separate from
`SKILL.md` so the main skill stays short. These supplement the five axes —
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

The same shape appears outside code comments: a PR description or a QA doc
stating test counts, "N/N mutations killed" or "verified in Docker". Treat
those numbers as claims to check against the reports and the test diff, not
as context.

---

### A test that passes — or fails — for the wrong reason

**Axis:** Best practices (tests)

**Watch for:** A test whose name promises a guarantee (isolation, rollback,
"never leaks X") but whose assertions would hold even if the guarantee broke:
it asserts on a value the change doesn't control, the setup already makes the
outcome inevitable, or a guard earlier in the test short-circuits before the
interesting path. The mirror image matters too: when a deliberately broken
build makes the suite go red, check *which* test went red. If only unrelated
tests failed, the test named after the guarantee did not catch anything.

**Verify:** Name the production change that should make the test fail, then
make it (or reason through it line by line) and see which assertion breaks.
If the guarded test stays green, it does not protect what its name says.

**Example:** A suite is said to verify that an endpoint rejects unauthorized
callers. Removing the endpoint's auth check makes the suite fail — but only
the happy-path tests fail (the change also broke the credential that
legitimate callers rely on), while the isolation test stays green because a
second layer still rejects the request. The isolation test was never tested
by that change.

---

### Defense in depth hides a single-layer regression

**Axis:** Best practices (security) / tests

**Watch for:** A security property enforced in two places (a filter and the
handler, a gateway and the service, a constraint in code and in the
database). Behavior-level tests can't tell when one layer silently stops
working, because the other still holds.

**Verify:** Don't conclude "covered" from a green suite. Check that each
layer is either tested on its own (a unit test that calls it without the
other layer in front) or deliberately documented as redundant. When
verifying by breaking code, break both layers together for the behavior
test, and each layer alone for its own unit test.

**Example:** An authorization filter and a "fail closed" lookup of the
caller's identity both reject anonymous requests. Disabling the filter alone
changes nothing observable for an anonymous request, so the end-to-end
isolation test cannot notice it — the filter needs its own test.

---

### The same value is stored in two spellings depending on the path

**Axis:** Best practices (data integrity)

**Watch for:** A value that reaches storage through more than one route —
direct connection vs. through a proxy, API vs. UI, import vs. form — where
each route formats it differently: compressed vs. expanded IPv6, upper vs.
lower case emails, phone numbers with and without country prefix, trailing
slashes in URLs, timezone-shifted timestamps. Every query or comparison on
that column silently misses the rows written by the other route.

**Verify:** List the routes into the column and what each one produces for
the same logical value. If two of them differ, ask where the normalization
happens; it should be one place every route passes through (the domain
object's constructor, a single repository method), with a test per spelling.

**Example:** An audit log records the caller's IP. Direct requests are logged
in the runtime's expanded IPv6 form; requests through the web tier arrive in
the compressed form. Searching the log for one address returns half its
entries.

---

### A shared fake that one test writes into

**Axis:** Best practices (tests)

**Watch for:** An in-memory mock server, fake repository or seeded fixture
shared by tests that run in parallel (or in any order), where a new test or a
new mock handler *writes* to it. Other tests that count rows, list pages or
assume a fixed seed start failing intermittently, and tests that create the
same entity collide with each other.

**Verify:** Check whether the fake is reset per test or only per run, and
whether the runner is parallel. If state is shared, a writing handler needs
per-test isolation, unique data per test, or to not persist at all — and the
property it can no longer show (e.g. "the new record appears in the list")
must be covered somewhere real, such as an integration test.

**Example:** A new "create" handler in a shared mock appends to the list
another spec counts exactly; that spec turns red only when both run in the
same batch, and two tests creating the same email get a duplicate error.

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
