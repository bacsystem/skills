---
name: retro
description: Use at the close of every delivery batch or release (or when the owner asks "what slowed us down", "retro", "retrospectiva", "feedback de la implementación") to measure the batch from GitHub data, find the bottlenecks and recurring defects, and turn them into concrete improvements — a retro doc in the project, updates to its known-defects list and context file, and a PR to the shared skills/agents repo. Works the same from Claude Code and Gemini / Antigravity.
---

# retro

## Overview

A retrospective that runs **every time a batch closes**, so the process keeps
improving instead of staying where it is. It is data first: it reads what the
PRs, reviews and CI actually recorded, not impressions. It produces three
outputs, each approved by the owner through a normal PR — nothing is applied
silently.

## When to Use

- A delivery batch closes (the release PR of the batch is open or merged).
- The owner asks where the time went, what to improve, or for feedback on the
  implementation.

Skip when: a single PR is still in flight — wait for the batch.

## Inputs

- The repo (`owner/repo`) and the PR numbers of the batch.
- The project's process doc and known-defects list, if it has them (its
  context file — `CLAUDE.md`, `GEMINI.md` or `AGENTS.md` — names them).
- The shared skills/agents repo the team uses (for this collection,
  `bacsystem/skills`), cloned locally.

## Workflow

1. **Measure.** Run `scripts/collect.sh <owner/repo> <PR>...` (read-only, `gh`
   and `jq`). It prints, per PR: review rounds (one per review, re-review or
   closing comment, not per "Verdict" line), QA reports, findings by
   severity, work commits and merges after opening (separate columns; merges include the base and, on a stacked branch, the branch below),
   time to merge (minutes, or hours with one decimal), failed CI runs with the
   job and first failing test of each (from `gh run view --log-failed`, when
   the log is still available) and CI minutes. Check by hand any number that
   looks off; the counts are approximate. Read the failure causes before
   counting a red CI as a defect. A timing test that misses its bound is a
   false alarm only with evidence that the environment caused it (the
   runner's load, the race detector, a measurement that passes outside it);
   without that evidence, investigate it as a possible regression. When the owner merges the
   whole batch at once, the time to merge measures the wait for that merge,
   not the work.
   Spot-check the round count against the PR with the most comments: when
   the script finds fewer rounds than there are published reviews, count by
   hand and say so in the retro (the script failing is itself an
   improvement for this repo).
   **Classify the base merges** before calling them a bottleneck: for each
   merge commit, `git merge-tree --write-tree --name-only <parent1> <parent2>`
   with the repo's attributes and again with `-c attr.tree=<empty tree>`
   (`4b825dc642cb6eb9a060e54bf8d69288fbee4904`) separates the merges that
   conflict only in the changelog (which a `merge=union` driver solves
   locally but GitHub still flags), real conflicts (name the files: an
   append-only list every story edits is a hotspot) and stacked-branch
   merges.
2. **Read the findings.** Open the review and QA comments of the PRs with the
   most rounds or `IMPORTANT`/`BLOCKER` findings. Group the findings by
   **defect class** (fail-open on missing data, tenant/principal leak, time
   zone, decimal scale, test that does not discriminate, wiring not tested,
   stale doc…), not by PR.
3. **Find the bottlenecks.** For each, name the evidence: where the
   wall-clock time went (agent rounds, repeated suite runs, CI, waiting on a
   decision, stacked branches re-merged), and which defect classes repeated.
   A bottleneck without a number or a PR reference is not reported.
4. **Decide the improvements.** Each one says what changes, where, and which
   bottleneck or defect class it removes. Prefer removing a step over adding
   one. Split them by destination:
   - **Project-specific** (this repo's stack, schema, domain rules) → the
     project's docs.
   - **Generic** (would help any project using these agents) → the shared
     skills/agents repo.
5. **Write the outputs** (each on its own branch, through the project's
   commit/PR flow, e.g. `/git-flow`):
   - `docs/retros/YYYY-MM-DD-<batch>.md` in the project: metrics table,
     bottlenecks with evidence, defect classes, improvements and where each
     landed, and what to watch next batch.
   - The project's **known-defects list** (e.g.
     `docs/architecture/review-checklist.md`) gains every new defect class,
     with the PR where it appeared. The **context file** changes only if a
     team rule changed. When the project keeps several context files (for
     example `GEMINI.md` importing `CLAUDE.md`), edit only the one it names as
     the source of truth, so Claude and Gemini always read the same rules.
   - A **PR to the shared skills/agents repo** with the generic improvements:
     the agent or skill that owns the behavior, its `CHANGELOG.md` entry and
     the repo's own tests. Keep it generic: no project names, paths or
     domain rules — reference "the project's context file" instead.
6. **Report** to the owner in a few lines: the top 3 bottlenecks with their
   numbers, what changes, and the PR links. The owner approves by merging.

## Rules

- Data before opinion: every claim cites a metric, a PR or a review finding.
- One retro per batch; compare with the previous retro's "watch next batch"
  list and say whether each item improved.
- Do not tune shared agents to one project: if a rule only makes sense for
  this stack, it goes to the project's docs.
- Never put secrets, customer data, local paths or credentials in a retro or
  a PR (the repos may be public).
- A retro never edits merged history or reopens closed reviews; it changes
  the process for the next batch.

## Common Mistakes

- **Listing complaints without numbers** — measure first (step 1).
- **Adding a new step for every problem** — prefer removing one.
- **Editing the import shim** (`GEMINI.md` that only imports `CLAUDE.md`)
  — edit the source of truth only.
- **Project rules in the shared agents** — keep the skills repo generic.
