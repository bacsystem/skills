# Your own code and small changes

Read from `SKILL.md` before the diff when this session wrote the change under
review, or when the diff is a handful of files with no executable logic.

## When you wrote the code yourself

If this session produced the PR — you implemented it, ran its tests, wrote its
description — say so in one line at the top of the report. You are the least
independent reviewer there is: your tests, your mutation counts and your PR
body share your assumptions. Authorship still never softens a finding, but
before putting APPROVED on your own work:

- Run at least one check you did not run while implementing: reproduce an
  acceptance criterion against the real thing (the endpoint, the container,
  the page) or re-run one mutation by hand.
- Re-read the diff as published (`gh pr diff`), not as you remember it.
- Treat the PR body's numbers and claims like anyone else's.

## Small, config-only changes

When the diff is a handful of files and none carries executable logic
(compose files, `.env.example`, CI config, docs), use the short form: issue
criteria, "done well" in one to three bullets, must be fixed, verdict. Leave
out the sections that have nothing to say (follow-ups, previous findings) and
spend the effort running the change rather than describing it — start the
container with the setting, call the endpoint — because for configuration
the only reliable review is the one that executes it.
