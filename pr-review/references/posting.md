# Posting to the PR (`--comment`)

Only when `--comment` was passed. Without it, the report stays in the terminal
and nothing is posted.

1. **Confirm the target before posting.** Run `gh pr view <target> --json
   number,title,url,author,headRefOid` and show the user the repo, PR number,
   title and author you are about to comment on. A comment on a public PR —
   especially someone else's — cannot be cleanly unpublished. If `headRefOid`
   is no longer the commit you reviewed, the PR moved under you: review the new
   commits before posting, or say in the comment which commit it covers.
2. **Show the exact comment body** and ask for explicit confirmation. A bare
   "yes" to the review itself is not consent to post it. A standing consent
   written in the project's `GEMINI.md`, `AGENTS.md`, `CLAUDE.md` or memory (for example "every review is
   posted on this repo's PRs") counts as that confirmation for that repo only:
   still name the target, and still ask on any other repo.
3. On confirmation, post it as a single issue comment:
   `gh pr comment <target> --body-file <path>`
   Write the body to a temp file rather than inlining it — review bodies
   contain backticks, quotes and newlines that break shell escaping.
4. Report the resulting comment URL from `gh`'s output.
5. If `gh` is unavailable or unauthenticated, say so and print the body for
   the user to paste manually. Never fail silently.

The posted comment is the same sections, prefixed with one line naming
what was reviewed (it goes first, and the verdict line described under
**Output format** in `SKILL.md` comes right after it):

```
Code review de `<base>...<head>` (`<sha7 del head revisado>`) — corrección, Clean Code, SOLID, DRY y buenas prácticas.
```

The short SHA of the head you reviewed is what a re-review starts from
(`git log <sha>..HEAD`); write it in every posted report.

Post **one** comment per review. Never open a GitHub *review* with
approve/request-changes state — the verdict is text in the comment, not a
GitHub approval. Approving a PR is the human's call.
