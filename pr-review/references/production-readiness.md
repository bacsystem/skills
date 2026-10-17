# Production readiness

What breaks **after** the merge, checked under the best-practices axis of
`SKILL.md`. Only check the sections the diff actually touches — a PR with no
migration has nothing to report under migrations. Every finding still needs
`file:line` and the concrete consequence in production.

---

## Database migrations

- **Locks on a live table.** Adding a column with a volatile default,
  changing a type, adding a `NOT NULL` without a default, or creating an
  index without the engine's concurrent option can lock a large table for
  the whole migration. Check the table's expected size.
- **Backfills.** A data update over a whole table inside the same
  transaction as the schema change holds locks and can time out the deploy.
  Large backfills belong in batches.
- **Order of deploy.** Code that reads a new column must not run before the
  migration that adds it; code that stops writing a column must ship before
  the migration that drops it. Check whether the PR assumes an order the
  deploy doesn't guarantee.
- **Constraints that existing data violates.** A new `UNIQUE`, `CHECK` or
  `NOT NULL` fails on production data that the test database doesn't have.
- **Rollback.** If the migration can't be undone, the PR should say what
  happens if the release has to be reverted.
- **Edited migrations.** Changing a migration that already ran elsewhere
  breaks checksums or leaves environments in different states. New changes
  go in a new migration.

## API and data compatibility

- **Renamed or removed fields, changed types, new required fields** in a
  request or response break existing clients — the frontend in the same repo,
  mobile apps on old versions, third-party integrators.
- **Changed error codes or status codes** break clients that branch on them.
- **Changed defaults** (a flag that was on is now off, a page size, a sort
  order) change behavior for everyone who relied on the old one without
  saying so.
- **Stored data in an old shape** — serialized JSON, cached values, queued
  messages, tokens already issued — must still be readable by the new code.
- **Casing and serialization**: a naming-strategy change (camelCase ↔
  snake_case) or a documented schema that differs from what is actually
  serialized.

## Documents another system validates

- **Local validation is not acceptance.** A schema check or unit test shows
  the shape; the receiver (tax authority, gateway, partner API) also applies
  business rules the schema never sees. Run its sandbox, or read its rules,
  for every field the diff changes.
- **Unlisted fields.** If the receiver's rules do not mention a field, do not
  assume it is tolerated: the amounts that depend on it may be checked as if
  it were absent.
- **Dated rules.** A change announced for a future date is not a reason to
  switch early or late without checking what the sandbox and production
  accept today; the notes in the repo may already say.
- **A rejection after the number is taken.** If the document consumes a
  sequence number or a quota before the receiver answers, a rejection leaves
  a gap or a stuck record: say what happens next.

## Configuration

- **New environment variables** are documented (README, `.env.example`,
  deploy docs) with what they do.
- **Safe default.** Missing configuration must fail safe: closed, not open;
  disabled, not trusted. A security setting whose default trusts everything
  is a finding.
- **A setting read by several services reaches all of them.** The same
  variable (a registration switch, a feature flag, a base URL) is consumed by
  the backend and the frontend; the orchestration file passes it to one and
  forgets the other, which falls back to its own default — often the closed
  one in a production image. List every consumer (`grep` for the name), check
  each environment definition (compose, platform docs, CI), and confirm in the
  running container's environment.
- **Dark until switched on.** A feature that does nothing until a flag is
  turned on or a data load finishes should say so in the PR: what the user
  sees in the meantime (an error, an empty state, the old behavior), and which
  must be deployed first.
- **Fail loudly at startup** when a required value is missing or invalid,
  not on the first request that needs it.
- **No production values in code**: URLs, credentials, feature flags that
  only make sense in one environment.

## Operability

- **Swallowed errors.** A `catch` that turns a failure into `false`, `null`
  or a default leaves nobody able to tell why it failed. It needs a log, a
  metric or a signal the user can act on — or a comment explaining why
  silence is correct.
- **Logs that leak.** Tokens, passwords, API keys, full card numbers or
  personal data in log lines or error messages returned to clients.
- **Enough context to diagnose.** An error log without the identifier of the
  thing that failed (request, entity, tenant) can't be traced.
- **Retries and timeouts.** Calls to external services have a timeout;
  retries are bounded and safe to repeat (idempotent) or protected against
  duplicates.

## Performance visible in a diff

- **N+1 queries**: a query inside a loop over the results of another query,
  including lazy-loaded relations touched in a loop or a template.
- **Unbounded result sets**: a list endpoint or query without a limit or
  pagination, a "load all then filter in memory".
- **Missing index** for a new filter, sort or join column on a table that
  grows.
- **Work while holding a lock or a transaction**: network calls, file I/O or
  heavy computation inside a transaction that holds row locks.
- **Hot-path waste**: compiling a regex, building a formatter or opening a
  connection on every call in a path that runs per request.

Only report what the diff makes measurably worse; no speculative
micro-optimizations.

## Frontend

- **States**: loading, empty and error states exist and are distinguishable;
  a failed request does not leave a spinner or a disabled button forever.
- **Double submit**: a form that creates something can't be sent twice by a
  double click or a retry.
- **Accessibility**: inputs have labels, errors are announced and tied to
  their field, interactive elements have the right role (a link that
  navigates is a link, a button that acts is a button), focus is visible
  and lands somewhere sensible after a dialog closes.
- **Sensitive data in the browser**: secrets or tokens in client bundles,
  `localStorage`, URLs or responses that a cache can keep (`Cache-Control`).
- **Server/client boundaries** of the framework (see
  `language-idioms.md`).

## Dependencies

- **Justified**: the new dependency does something the platform or an
  existing dependency doesn't already do.
- **Maintained and trusted**: recent releases, known publisher, not a
  typo-squatted name.
- **License** compatible with the project's.
- **Pinned** the way the repo pins its other dependencies, with the lockfile
  updated in the same PR.
- **Size** for frontend dependencies: what it adds to the bundle of the pages
  that import it.

---

<!--
Template for the next entry — add under the section it belongs to, or a new
section if none fits. Keep it generalized: what broke, how to spot it in a
diff, the consequence.

- **<pattern>.** <what to look for and what breaks in production>
-->
