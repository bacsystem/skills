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

### The type and the mock repeat the same wrong assumption

**Axis:** Best practices (tests, contracts)

**Watch for:** A client-side type declares a field as `T | null` (or as
required) and the mock or fixture that feeds the tests produces exactly that,
while the real service *omits the key* when the value is empty (a serializer
configured to skip nulls). The type, the mock and the tests all agree with one
another and none of them with the server, so the suite is green and the code
that tests the field against `null` is wrong in production.

**Verify:** Call the real service once, or read its serializer configuration,
and compare the response with what the mock sends: is the key omitted or
`null`, how is it cased, what status does the error path return? Reading the
mock against the type proves nothing — they were written together.

**Example:** A lookup endpoint returns an address only when the record has
one. The client type says `address: string | null` and the mock always sends
`address: null` for records without one; the real response has no `address`
key at all. Code written as `address === null` passes every test and never
matches in production. The fix is the optional type (`address?: string | null`)
and a mock that omits the key.

---

### An acceptance criterion names a variant no test exercises

**Axis:** Best practices (tests) / issue criteria

**Watch for:** A criterion that lists kinds — "invoice, receipt or credit
note", "web and mobile", "every user type" — while the tests exercise one or
two of them because today they share a code path. The unexercised variants are
guarded by the sharing, not by a test, and the day one of them is split off
nothing fails.

**Verify:** For each variant the criterion names, find the test that goes
through *that variant's* entry point. If only the shared path is covered, it is
a MINOR finding with the test to add; it is not a defect today, so say so.

**Example:** A criterion says the notice must appear after issuing an invoice,
a receipt or a note. The tests cover the invoice and the note form; the receipt
form is the same component with a different prop. A later refactor that gives
the receipt its own submit handler would drop the notice and keep the suite
green.

---

### Reviewing your own work shares your blind spots

**Axis:** Cross-cutting

**Watch for:** A review of a PR that the same session implemented, where every
piece of evidence — the tests, the mutation results, the numbers in the PR
body — was produced by the author-reviewer. They agree with each other because
they share one set of assumptions.

**Verify:** Before approving, run one check that was not part of the
implementation: reproduce an acceptance criterion against the real system, or
repeat one mutation by hand. Disclose in the report that the reviewer is also
the author.

**Example:** An author-reviewer reads "the form opens when the setting is
true" in its own PR. Starting the real container with the setting and
requesting the page shows the page opens, but a request to the form's submit
route is still refused by a second service that never received the setting —
a path none of the PR's tests exercised.

---

### A schema-valid document is not an accepted one

**Axis:** Best practices

**Watch for:** A diff that changes what is sent to a system that validates it
(an XML for a tax authority, a gateway payload, an import file) and proves it
with a local schema check and unit tests, while its own plan leaves "try it in
the receiver's sandbox" pending. Also a code or format chosen from a dated
announcement when the repo's own notes on that system say otherwise.

**Verify:** Open the receiver's rules for the fields the diff touches, and
run the repo's sandbox harness if there is one. A field the rules never list
is not "allowed by the schema": it is unspecified, and the receiver may
reject the amounts that go with it.

**Example:** Two merged changes reordered the elements of a credit and a debit
note so they passed the local schema, and a third changed which code a daily
summary uses for free items. The sandbox then rejected all three: the notes'
rules contain no discount or charge field at all and require line value =
unit value × quantity, and the summary's catalog accepted neither the old nor
the new code (it accepted the summary with the item left out). Each PR had
listed the sandbox run as pending and merged on green unit tests.

---

### A state save that is conditional only for the states the author thought of

**Axis:** Correctness (concurrency, state machines)

**Watch for:** A `save`/`update` of an entity with a lifecycle where the
`WHERE estado IN (…)` guard exists for *some* target states (the ones a past
bug taught) and is absent for the others — typically the terminal ones
(`ACCEPTED`, `REJECTED`, `EXPIRED`). Also the step before it: an operation that
calls an external system (a tax authority, a payment gateway) without first
*reserving* the entity (`UPDATE … SET estado = 'SENDING' WHERE estado IN
('READY','FAILED')`), so two callers — an API request and a background worker,
or two retries — can both make the call.

**Verify:** List every transition the diff can persist and ask, for each one,
"what is the origin state this transition assumes, and does the SQL check it?"
Then play the race: caller A gets the external system's acceptance, caller B
gets its "already registered" error — whichever writes last wins. If a sibling
flow in the same repo already reserves (a second document type that sets
`SENDING` first), the asymmetry itself is the finding: the safe pattern exists
and the diff didn't use it.

**Example:** A document is sent to an external registry by a manual endpoint
and by a retry worker. The save guards `ERROR` and `SENT` against overwriting a
terminal state, but `REJECTED` is saved unconditionally. The worker's second
call gets "duplicate" from the registry, maps it to `REJECTED`, and overwrites
the `ACCEPTED` the first call had just persisted. The user re-issues the
document, which the registry now holds twice.

---

### An exception after the point of no return

**Axis:** Correctness (error paths)

**Watch for:** A `try` around a call with an irreversible external effect
(money moved, a document registered, an email sent) that catches a *list* of
expected exception types, with the persistence of the resulting state placed
*after* the `try` block. Anything not on the list — a client-side exception of
the storage SDK, a parser that throws on an unexpected response, a `Base64`
decoding error — escapes before the state is written. The mirror in workers:
a `catch (Exception)` that reschedules without going through the retry cap.

**Verify:** Walk the lines between the external call and the persisting
write and list what each can throw. For each exception type not caught, ask
"what does the database say after this?" If the answer is "the state from
before the call", the entity is orphaned (nobody retries it, or everybody
retries it forever). Check the SDK's exception hierarchy: catching the
server-side exception often misses its client-side sibling.

**Example:** The registry accepts the document; uploading the receipt to object
storage times out with the SDK's client exception, which the `try` does not
catch. The request returns 500 with the document still `READY` in the
database and no retry row. A client without an idempotency key sends it
again: two registered documents.

---

### A precision that narrows somewhere along the path of a signed value

**Axis:** Correctness (money, units)

**Watch for:** A diff that widens what the domain accepts (10 decimals on a
quantity, 1 500 characters on a name) or that formats a value for an outbound
document, without following the value through every place it passes: the
request DTO, the domain type, the template that renders it, the database
column, and the code that rehydrates it. Each place can have its own scale,
format or length. Two shapes are especially silent: a column narrower than the
domain (the engine rounds or truncates on insert, or fails *after* a sequence
number was consumed), and a rehydration that *recomputes* totals from the
rounded parts instead of reading the totals that were persisted.

**Verify:** Pick the widest value the domain allows and trace it: what does
the template print (`?string["0.####"]`-style formats round), what does the
column store, what does the object look like after reading it back, and what
does a document derived from the stored object (a copy, a credit note, a
report) compute. Any step where the value changes is a finding, because the
document that was signed or sent no longer matches what the system shows.

**Example:** The domain accepts a unit price with ten decimals and the signed
XML carries the exact line total. The column is `NUMERIC(14,4)`, so the price
is rounded on insert; reading the invoice back recalculates its totals from
the rounded items. The detail view, the export and the credit note that copies
the lines all show a total that differs from the signed one by a few cents,
and the credit note is rejected for exceeding the original.

---

### A whole-row save of a partially edited aggregate

**Axis:** Correctness (concurrency)

**Watch for:** `INSERT … ON CONFLICT DO UPDATE SET every_column = EXCLUDED…`
(or an ORM `save(entity)`) fed by an object that was read *outside* the
transaction, in a service that only meant to change one section (the
address, the logo, one credential). Every other column travels along with the
stale values the object was read with. The lost update is invisible: no error,
no log, the row just reverts.

**Verify:** List every writer of the table. If any of them is a narrow,
conditional `UPDATE` of a single column (an environment switch, a credential
rotation, a deactivation) and another is a whole-row upsert, the wide one can
undo the narrow one. The fix is per-section writes (the narrow pattern the
repo already has) or a `SELECT … FOR UPDATE` plus re-read inside the
transaction, or optimistic versioning.

**Example:** An operator switches a company from sandbox to production with a
one-column `UPDATE`. In the same seconds a user saves the company's fiscal
address; that service read the company before the switch and upserts the
whole row, environment included. The company is back in sandbox with no
audit entry, and its real invoices go to the test endpoint.

---

### A rule the code states for one endpoint and omits for its siblings

**Axis:** Best practices (security, authorization)

**Watch for:** A comment or a guard that explains a security rule ("a leaked
API key must not be able to create other keys", "only a human session may do
this") applied to one or two handlers of a controller, while siblings in the
same file with the same or higher blast radius (replace the signing
certificate, change credentials, change the fiscal address) accept the
weaker credential. The rule is right; its coverage was decided by which bug
came first.

**Verify:** `grep` the guard (`requireSession`, `requireRole`, `isHuman`) and
list every mutating endpoint of the same resource that lacks it. For each,
ask what the weaker credential could do if leaked, in the terms the existing
comment uses. The same shape applies to a static operations key accepted by a
shared filter: every *new* admin endpoint inherits that acceptance by
default, so each one should decide explicitly whether an identity-less key
may perform it (creating administrators, mass mailing, suspending accounts).

**Example:** Key management requires a portal session, with a comment saying
why. Uploading the signing certificate and the SOL credentials, on the same
controller, accept an API key. A leaked key cannot mint keys but can replace
the certificate with a self-signed one and stop every emission of the tenant.

---

### A revocation path that depends on the credential being revoked

**Axis:** Correctness (sessions) / Best practices (security)

**Watch for:** A logout, "revoke all sessions", "disable account" or "rotate
secret" flow that is gated by a short-lived credential (the access token)
while the thing it revokes is long-lived (the refresh token, the session
family). When the short-lived one has expired, the gate rejects the request
and the long-lived one survives — exactly when the user most needs the
revocation to work. The sibling shape: a refresh-token rotation that rejects
a reused token with 401 but does not revoke its family, with a test that
asserts the 401 and nothing else.

**Verify:** Call the revocation with the short-lived credential expired (or
absent) and read the database: is the long-lived one revoked? For reuse
detection, replay a rotated refresh token past the grace period and check the
sibling tokens, not just the response code. A test that only asserts the
rejection does not protect the side effect.

**Example:** The browser-side logout clears its cookies and calls the API's
logout with the access token it has. Fifteen minutes into a page the access
token is expired, the API answers 401, the BFF swallows it, and the 30-day
refresh token stays valid in the sessions table for anyone who copied it.

---

### A dependency whose default sends your data to the vendor

**Axis:** Best practices (dependencies, data protection)

**Watch for:** An embedded third-party UI component or SDK (an interactive API
reference, a chat widget, analytics, an error reporter, a font loader)
configured with a *real* credential or real user data, without reading what
the component does by default with the network: many route "try it" requests
through the vendor's proxy, load fonts or scripts from the vendor's CDN, or
phone home. The option that disables it (`proxyUrl`, `telemetry`,
`withDefaultFonts`) is usually one line, and nobody set it.

**Verify:** `grep` the installed bundle (`node_modules/<pkg>/dist`) for
external hostnames and read the config defaults near them; then check whether
the diff passes anything sensitive into the component (a key, a token, a
customer record). The development environment often exempts `localhost`, so
the behavior only shows in production — do not conclude from a local run.

**Example:** An API reference page generates a real API key for the tenant
and passes it to the embedded reference widget so "Test request" works. The
widget's default, when `proxyUrl` is undefined, is to send every test request
through the vendor's public proxy — key, headers and body included.

---

### A limit on the compressed form

**Axis:** Correctness (input validation) / Best practices (availability)

**Watch for:** An upload or inbound payload validated by byte size and magic
number and then decoded in full: an image whose decoded raster is width ×
height × 4 bytes, an archive expanded with `readAllBytes`, a JSON array
materialized before the domain counts its elements. The limit protects the
transport, not the memory the decode needs.

**Verify:** Compute the decoded size for the largest input the limit allows
(a uniform 8 000 × 8 000 PNG compresses to under 200 KB and decodes to
256 MB). If the decode happens per request or per preview, two or three
concurrent requests exhaust the process for every tenant. Look for a
pre-check that reads dimensions or entry counts *before* decoding, or a
bounded stream.

**Example:** A 200 KB cap and a PNG header check guard a logo upload; the PDF
generator then decodes the full image to measure it and the preview endpoint
decodes it again on every call. A crafted logo under the cap takes the
instance down with authenticated requests.

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
