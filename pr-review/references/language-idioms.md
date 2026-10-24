# Language-specific idioms

Known pitfalls and good-vs-bad patterns per language/framework, checked in
addition to the five axes in `SKILL.md`. Not exhaustive — grows every time a
PR in a language gets reviewed and something idiomatic to that language was
the actual defect. **A language missing here is not "skip it"** — apply the
general axes and judgment; add the entry once you've actually seen the
pattern in a real review, not preemptively.

---

## Go

- **Ignored errors** — `_, err := f()` discarding `err`, especially from
  `os.Create`, `os.Open`, `json.Marshal`, `strconv.Atoi`. Go doesn't force
  handling errors; a discarded one stays silent until something downstream
  panics on a nil/zero value, or the function returns a false "success."
  Check every `_ :=` / `_, x :=` for a dropped error. If a sibling function
  in the same file already handles the same call correctly, cite it as the
  pattern to match (DRY + best-practices).
- **Missing `defer <resource>.Close()`** — right after acquiring a file, DB
  connection, or HTTP response body, before any error-prone code runs. An
  early return on error before the `defer` is registered leaks the resource
  on that path specifically — check each early-return branch, not just the
  happy path.
- **Hand-rolled delimited output** (CSV/TSV via string concatenation) —
  breaks the instant a field contains the delimiter, a quote, or a newline.
  Flag it in favor of `encoding/csv` (or the equivalent stdlib writer).

## Python

- **String-interpolated SQL** — an f-string, `%`-format, or `.format()`
  call building a query string before `cursor.execute(query)`, instead of
  passing values as a separate parameter tuple
  (`execute("...= %s", (value,))`). This is the single most common
  SQL-injection shape in Python. Check every `execute(`, `.raw(`, or
  `.extra(` call that touches a string built from a variable.
- **Bare `except:`** (or `except Exception:` swallowing everything without
  re-raising or logging) — hides the real failure and any bug inside the
  `try` block; matches the Clean Code "no silent catch" rule directly.

## TypeScript / React (Next.js App Router specifically)

- **Passing a function prop across the Server→Client boundary** — a Server
  Component (no `'use client'`) defining an inline function/closure
  (`onClick={() => ...}`) and passing it into a component that renders a
  native DOM handler. Next.js throws at request time ("Event handlers
  cannot be passed to Client Component props"), not at build time in every
  case — a diff can look correct and still be broken. Check whether a page/
  component composing an interactive child needs `'use client'` itself
  before assuming the child alone is enough.
- **Hardcoded color/spacing/typography values** in JSX `className` strings
  (a raw hex, an arbitrary Tailwind bracket value like `text-[#1a1a1a]`)
  instead of the project's design tokens. Check against whatever token
  source the repo already established (CSS variables, a Tailwind theme
  extension) — a PR introducing a parallel, ungoverned color is a real
  best-practices/consistency finding, not a style nit.
- **Duplicated Radix/shadcn-style overlay classes** (open/close transition
  utility strings) copy-pasted across multiple primitives (Select, Dialog,
  DropdownMenu, Tooltip) instead of a shared helper — see
  `case-studies.md` for the general "verify a comment's claim" pattern this
  was found alongside.
- **`next/headers` (or another server-only module) reachable from a client
  component** — a shared helper that imports `cookies()`/`headers()` and is
  also imported, even indirectly, by a `'use client'` file. Vitest, `tsc`
  and ESLint all stay green; only `next build` fails. When a diff adds such
  an import to a widely-imported module, check its importers or ask whether
  `next build` was run, and prefer passing the value in as a parameter.
- **Client types for an API that omits nulls** — a field typed `x: string | null`
  against a backend whose serializer skips empty values (see Java / Spring
  below): the real value is `undefined`, not `null`, so a check written as
  `=== null` never matches. The type should be optional (`x?: string | null`)
  and the mock should omit the key rather than send `null`.
- **A page that reads `process.env` without opting into dynamic rendering** —
  a statically prerendered page freezes the value present at build time, so a
  flag set later in the deployment platform does nothing. Look for
  `export const dynamic = "force-dynamic"` (or a runtime read such as
  `cookies()`/`headers()`) wherever a page or a shared component decides
  something from the environment.
- **A link rendered as a button** — a design-system `Button` with a
  `render={<Link …/>}` / `asChild` prop can emit `<a role="button">`. A
  control that navigates should be announced as a link; screen readers and
  `getByRole("link")` queries both depend on it.
- **A route handler that sets cookies from any POST** — `SameSite=Lax` stops
  the browser from *sending* cookies cross-site; it does not stop a top-level
  cross-site `<form method=POST>` from *receiving* `Set-Cookie` in the
  response. A login/registration handler that does `await req.json()` and
  writes the session cookie, without checking `Sec-Fetch-Site`/`Origin` or
  requiring `Content-Type: application/json` (`Request.json()` parses a
  `text/plain` form body happily), is a login-CSRF: the victim ends up inside
  the attacker's account. Every handler that writes an auth cookie needs the
  origin check.
- **A dynamic segment interpolated into a backend URL** — `` `/v1/things/${id}` ``
  from `params.id` without validating the shape (`isUuid`) or
  `encodeURIComponent`: an encoded slash or `..` changes which backend path
  the server-side fetch hits, with the user's own credentials attached.
- **No `headers()` in `next.config.ts`** — a page that puts a one-time token
  in the URL (`/reset/<token>`) depends on `Referrer-Policy`; an admin panel
  depends on `frame-ancestors`/`X-Frame-Options`. When a diff adds such a page
  and the config sets no security headers at all, say so.

## Java / Spring

- **`@Valid` missing on a nested object** — a request record with a nested
  record (`@NotNull Address address`) only validates the nested fields when
  the field itself carries `@Valid`. Without it, `@NotBlank`/`@Pattern` on the
  inner fields never run and invalid input reaches the domain.
- **Validation limits that don't match the column** — a `VARCHAR(150)` column
  behind a request field with no `@Size(max = 150)`: an over-long value is a
  500 from the database instead of a 422 with a message. Compare each new
  string field with its column length.
- **Library defaults that do more than the PR intends** — a component
  configured for one job may enable others by default (e.g. Tomcat's
  `RemoteIpValve` also rewrites the scheme from `X-Forwarded-Proto`, and
  trusts private address ranges as proxies unless `internalProxies` is set).
  When a diff installs such a component, check what it enables beyond the
  setting the PR is about.
- **`InetAddress.getByName` on untrusted text** — given something that isn't
  a literal IP it performs a DNS lookup, on the request path. Parsing or
  normalizing an address that came from a header should not touch the
  network.
- **Serializer settings that change the contract** — `default-property-inclusion:
  non_null` (Jackson) omits empty fields from the JSON instead of sending
  `null`, and a naming strategy changes the casing. Frontend types, mocks and
  the OpenAPI document must follow what is actually serialized, not what the
  Java record declares.
- **Backslashes in `@SpringBootTest(properties = …)`** — the values are read
  as `.properties`, so `\.` in a regex loses its backslash and the test runs
  a different pattern than production. Use character classes (`[.]`) or a
  test properties file.
- **`NUMERIC(p,s)` narrower than the `BigDecimal` the domain allows** —
  PostgreSQL rounds the extra decimals silently on insert and raises
  `numeric field overflow` for too many integer digits. The first corrupts
  the stored value relative to the document that was signed; the second
  fails *after* the sequence number and the signature were produced. Compare
  every new or widened decimal field with its column, in both directions.
- **`?string["0.####"]` on an amount or a quantity in FreeMarker** — it goes
  through `java.text.DecimalFormat` (HALF_EVEN, and fewer decimals than the
  domain keeps). A quantity of `0.00004` prints as `0`; a line value computed
  from the full quantity no longer equals printed quantity × unit price. Use
  `toPlainString()` or a format with as many decimals as the domain.
- **`ON CONFLICT (id) DO UPDATE SET col = EXCLUDED.col, …` for every column**
  — a whole-row upsert of an aggregate read outside the transaction overwrites
  concurrent single-column updates (an environment switch, a rotated
  credential) with stale values. Prefer per-section updates, or lock and
  re-read inside the unit of work. See `case-studies.md`.
- **Catching `S3Exception` (or any SDK's *service* exception) only** — the AWS
  SDK v2 raises `SdkClientException` for timeouts and connection failures; it
  is a sibling of `S3Exception`, not a parent. A `catch (S3Exception)` that is
  meant to turn storage failures into a retryable state lets the common
  failure mode escape. Catch `SdkException` (the parent) when the intent is
  "any storage failure".
- **`HttpRequest.timeout` of the JDK `HttpClient` covers only the headers** —
  a server that answers headers and then stalls the body holds the thread
  indefinitely. Reads of the body need their own bound (a bounded stream,
  `orTimeout` on the future) when the peer is a third party.
- **`@Scheduled` with several replicas** — a `fixedDelay` job runs once per
  JVM; without `SELECT … FOR UPDATE SKIP LOCKED`, an advisory lock or a
  marker column, two replicas process the same rows (double delivery, double
  send). An `AtomicBoolean` guard is per process and does not count.
- **Embedded Tomcat follows the Spring Boot line** — a pinned Boot version
  pins the servlet container with it. When a diff pins or bumps Boot, state
  the line's OSS support end date; when a diff adds a multipart endpoint,
  check whether the container version is past the multipart CVE fixes.

---

<!--
Template for the next language or entry — copy, fill in, delete this
comment block's contents once real entries follow.

## <Language / framework>

- **<short pattern name>** — <what to look for, the concrete consequence,
  and (if applicable) what to check it against in the same diff/repo>.
-->
