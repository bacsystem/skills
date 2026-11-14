# Report template in English (`--en`)

Same sections, order and verdict rules as the Spanish template in `SKILL.md`
(*Output format*); only the wording changes. Load this file only when `--en`
was passed.

```
**Verdict: APPROVED** · 0 blockers · 0 important · 1 minor

## 🔁 Previous findings              ← re-review only
| ID | Status | Evidence |
|---|---|---|
| F1 | ✅ Resolved | commit abc123, `file:line`, test `testName` |
| F2 | ⚠️ Partial | what is still missing |
| F3 | ➖ Dropped | why it was left out (author's argument, or moved to follow-up) |

## 🎯 Issue #N criteria               ← only when the PR links an issue
| Criterion | Status | Where |
|---|---|---|
| the criterion's text | ✅ Met / ❌ Not met / ➖ N/A | `file:line` or test; "reproduced" if you ran it, "per the PR" if you only read it |

## ✅ What's done well
- [file:line] — which concrete decision in the diff is well resolved, and why

## ⚠️ Must be fixed
- **F1** [BLOCKER] [file:line] — the defect, its concrete consequence, and the change that resolves it. *Proven by:* the test that fails while it exists.
- **F2** [IMPORTANT] [file:line] — same
- **F3** [MINOR] [file:line] — same

## 📌 Follow-ups                     ← optional
- [file:line] — a real improvement outside this PR's scope; not fixed here and not counted in the verdict.

## 🔬 Verification
- Suites: `command` → N passed / M failed (or "not run: reason")
- Mutation: `file:line` changed to X → test `name` went red (or "not done: reason")
- Inputs traced: empty, duplicate, two at once, … through `function`
- Reproduced against the real system: what, with what result (or "none")
- Blast radius: N diff files + M related files opened (table writers, sibling endpoints, callers)

## Verdict
APPROVED | APPROVED WITH CHANGES | CHANGES REQUIRED
Files reviewed: N/N
```

The posted comment's first line in English:

```
Code review of `<base>...<head>` (`<sha7 of the reviewed head>`) — correctness, Clean Code, SOLID, DRY and best practices.
```
