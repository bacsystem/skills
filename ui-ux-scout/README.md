# ui-ux-scout

A Claude Code skill that takes a style from
[Refero Styles](https://styles.refero.design/) and **creates and improves
components in [khipu-design-system](https://github.com/bacsystem/khipu-design-system)**,
with expert judgment in UI/UX, React 19 and Next.js 15, DRY, SOLID and field
validation by data type.

khipu is the source: other projects get the new components through the khipu
CLI (`npx github:bacsystem/khipu-design-system add <componente>`).

It plans first, applies only after your approval, and never commits.

## How to use it

Inside the khipu-design-system repo, with a clean working tree:

```
/ui-ux-scout 3b6a17f0-3bdf-418c-a95e-0b89e5a8b2f8
/ui-ux-scout https://styles.refero.design/style/3b6a17f0-3bdf-418c-a95e-0b89e5a8b2f8
/ui-ux-scout 3b6a17f0-3bdf-418c-a95e-0b89e5a8b2f8 --en
```

To get a UUID, open a style on https://styles.refero.design/ and copy its URL.
There is no search by name.

| Flag | Effect |
|---|---|
| `--es` | Plan and messages in Spanish. **Default.** |
| `--en` | Plan and messages in English. |

## What it does

1. Checks it is running in khipu with a clean tree.
2. Reads khipu's conventions, tokens, recipes and registry.
3. Extracts the style's exact values with `scripts/refero-fetch.mjs`
   (falls back to WebFetch with a precision warning).
4. Shows a plan: new components (`N1`…), adjustments (`A1`…), tokens (`T1`…,
   with computed WCAG contrast) and convention conflicts (`C1`…).
5. Waits for your approval; tokens are approved one by one (`sí T1`), never by a general "sí".
6. Applies it on a `feat/estilo-<name>` branch: component, gallery entry,
   docs, visual guide, README and registry.
7. Runs `typecheck`, `lint` and `build`, reviews `/ejemplo`, and leaves the
   changes uncommitted for `git-flow`.

## Design rules

- khipu's conventions win over the reference (`h-9`, tokens only, mono for
  data, Spanish names, everything by props).
- Never removes or renames components, exports, props or tokens.
- Takes the system (elevation, scale, density, anatomy), not the brand.
- Only fetches the style you ask for, and never writes a copy of it to the repo.

## Files

- [`SKILL.md`](./SKILL.md): the full skill definition.
- [`scripts/refero-fetch.mjs`](./scripts/refero-fetch.mjs): UUID → exact JSON;
  exit codes `0` OK, `1` invalid input, `2` not found, `3` format changed,
  `4` network. Cache in the system temp dir for 7 days.
- [`references/`](./references): UI/UX principles, React/Next, DRY and SOLID,
  field validation, khipu checklist, plan template, Refero page format.

## Tests

```bash
node --test ui-ux-scout/scripts/test-refero-fetch.mjs
```

No network: pages are synthetic fixtures.

## Installation

Requires Node 18 or later. Symlink the skill into your personal skills
directory so repo edits apply immediately:

```bash
ln -snf "$(pwd)/ui-ux-scout" ~/.claude/skills/ui-ux-scout
```

Then start a new Claude Code session and use `/ui-ux-scout`.
