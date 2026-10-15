---
name: ui-ux-scout
description: Use when working inside the khipu-design-system repo and the user wants to create or improve khipu components from a Refero Styles reference — they give a style UUID or a https://styles.refero.design/style/<uuid> URL. Extracts the style's exact tokens and component anatomy, writes a plan (new components, adjustments, tokens with computed WCAG contrast, convention conflicts), waits for approval, then implements it with expert judgment in UI/UX, React 19 and Next.js 15, DRY, SOLID and field validation by data type, registers each component (gallery, docs, visual guide, registry) and verifies the build. Triggers include "/ui-ux-scout <uuid>", "crea componentes con este estilo de Refero", "aplica este DESIGN.md a khipu".
---

# ui-ux-scout

## Overview

Turns one Refero Styles reference into **new and improved components in
khipu-design-system**, the source that other projects consume through the
khipu CLI (`npx github:bacsystem/khipu-design-system add <componente>`).

It plans first, applies only after explicit approval, never commits, and never
lets the reference override khipu's conventions.

## When to Use

- Inside the `khipu-design-system` repo, with a Refero style UUID or URL.

Skip when:
- The current project is not khipu: stop and say «Esta skill trabaja solo
  dentro de khipu-design-system.»
- The user wants a style found by name: there is no name search. Explain how to
  get the UUID (open a style on https://styles.refero.design/ and copy its URL).

## Invocation

```
/ui-ux-scout <uuid|URL> [--es|--en]
```

| Argument | Effect |
|---|---|
| `<uuid>` | Refero style UUID, or its `https://styles.refero.design/style/<uuid>` URL. One style per run. |
| *(none)* | Do nothing but explain how to copy a style URL from https://styles.refero.design/. |
| `--es` / `--en` | Language of the plan and messages. **Default `--es`.** Code and khipu docs stay in Spanish. |

## Reference files

Read each one at the step that names it. Do not work from memory.

| File | Use it for |
|---|---|
| `references/refero-format.md` | How the style data is extracted; plan B with WebFetch |
| `references/ui-ux-principles.md` | Taking the system and not the brand; contrast (how to compute it with `scripts/contraste.mjs`); density; states; focus; dark mode |
| `references/react-nextjs.md` | Server vs Client Components, serializable props, refs, `cva`, controlled/uncontrolled, accessibility with base-ui |
| `references/clean-design.md` | DRY and SOLID adapted to components |
| `references/field-validation.md` | Validation by data type, `lib/validacion.ts`, messages |
| `references/khipu-checklist.md` | Folder, naming, quality list, registration steps, verification commands |
| `references/plan-template.md` | Exact plan headings and blocks |

## Flow

Follow these steps in order. Steps 1–4 never modify a file.

### 1. Check this is khipu

- `package.json` in the working directory must have
  `"name": "khipu-design-system"`. Otherwise stop with the message above.
- `git status --porcelain` must be empty. Otherwise stop and ask the user to
  commit or stash first: the skill's changes must be reviewable on their own.

### 2. Read khipu's context

Read `CLAUDE.md` (if present), `README.md`, `docs/design-system.md` (principles, tokens,
§4 height scale, §20 reusable kit), `src/app/globals.css` (`@theme inline`,
`:root`, `.dark`), `src/lib/estilos.ts` and `registry/registry.json`.

khipu's conventions are hard constraints: color only by token; one control
height `h-9`; mono with `tabular-nums` for data; at most 5 chart series;
the «próximamente» pattern; Spanish names; routes, texts, icons and handlers
by props.

### 3. Extract the style

1. Check Node: `node --version` must be ≥ 18. If not, go to plan B.
2. Run the script that ships next to this file, passing only the UUID or URL
   (strip `--es` / `--en` first):
   `node <this skill's directory>/scripts/refero-fetch.mjs <uuid-or-url>`
3. Act on the exit code:

| Code | Meaning | Do |
|---|---|---|
| `0` | OK; JSON on stdout (a stderr line may say it came from an old cache) | Continue. Mention the cache warning in the plan. |
| `1` | Invalid input | Explain the expected format and stop. |
| `2` | Style not found | Say so with the UUID received and stop. |
| `3` | Page format changed or unexpected script error | Plan B; if WebFetch also fails, stop. |
| `4` | Network error, no cache | Plan B; if WebFetch also fails, stop. |

**Plan B** is in `references/refero-format.md`. Values from WebFetch carry
the precision warning in the plan, always.

### 4. Write the plan

Use `references/plan-template.md`. Ground it in the references:
- folder and names for each new component: `khipu-checklist.md` section A;
- what to take from the style: `ui-ux-principles.md` («Take the system, not
  the brand»);
- for each new component, why it is not an extension of an existing one, and
  what it reuses: `clean-design.md`;
- Server or Client, props and variants: `react-nextjs.md`;
- for each form field, its data type, rules and messages:
  `field-validation.md`;
- for each token change, the contrast ratio **computed** with
  `scripts/contraste.mjs` (usage in `ui-ux-principles.md`), in light and dark;
- every clash with a khipu convention goes to «Conflictos con convenciones»,
  resolved in khipu's favor;
- a color value that `contraste.mjs` rejects (malformed, like the truncated
  `#1b1c1` Refero data has carried) is listed under «Estilo de referencia» as
  unusable and never used; `rgba` and 8-digit hex values are valid.

Show the plan and **stop**.

### 5. Wait for approval

Apply nothing without an explicit "sí" / "yes". The user may drop or change
items by ID (`N1`, `A2`, `T3`, `C1`). A token change reaches every khipu
consumer, so tokens have their own rule:

- A reply of `sí` approves every N, A and C item in the plan. It never
  approves a T item.
- A token is approved only by naming it: `sí T1`, `sí T1 T3`. A reply may
  combine both (`sí, sí T1`). A reply that is only `sí T1` approves T1 and
  nothing else.
- Every N/A block lists the tokens it depends on (`Depende de: T2`). If a T
  item is not approved, re-plan the items that depend on it, show the updated
  plan, and wait again. Never add a token that was not approved.

If the user changes the plan, show the updated plan and wait again.

### 6. Apply

1. Create the branch from an up-to-date `main`, one command per call:
   `git fetch origin`, then
   `git switch -c feat/estilo-<style-name-kebab> origin/main`. If the
   extracted `name` is `null`, use `feat/estilo-<first 8 chars of the uuid>`.
2. Follow `references/khipu-checklist.md` by item type: new components (N) →
   sections B, C and D; adjustments (A) → section E, plus B for any new code;
   tokens (T) → sections B.4 and B.5.
3. Keep every item of the checklist's quality list (section C) true.
4. Run `npm run registry:build` after all changes.

### 7. Verify

Run, one per call: `npm run typecheck`, `npm run lint`, `npm run build`.
If one fails, fix and run it again. The fix stays within the approved files
and items; a fix that would change an existing API or touch unapproved files
goes back to the user as a question. If it cannot be fixed, report the exact
error and **do not** say the work is done.

Then start `npm run dev` in the background and review `/ejemplo` in light and
dark with a browser tool if one is available; if none is, say that the visual
check was not done. Stop the dev server when finished.

End with a summary:
- what was created, adjusted and changed, by plan ID;
- the quality list (checklist section C) for each new component, item by item;
- the verification results, with the commands run;
- the source URL of the style, to cite in the commit message;
- next step: «Revisa el diff y usa `git-flow` para el commit y el PR.»

**Never commit, push or open a PR.** That is `git-flow`'s job.

## Rules

- **khipu's conventions win** over the reference, always.
- **Never break consumers:** do not remove or rename components, exports,
  props or tokens. Change values, add optional props, add variants, add
  tokens.
- **Tokens only:** no hex and no Tailwind palette colors in components.
- **Style, not brand:** no logos, illustrations, copy or the reference's brand
  color as khipu's identity.
- **Third-party content:** fetch only the style asked for. Never write the
  extracted JSON or a copy of the DESIGN.md into the repo.
- **Evidence over assertion:** contrast is computed, build results are
  quoted, values come from the script or carry the WebFetch warning.

## Common mistakes

| Mistake | Instead |
|---|---|
| Creating a component that an existing one covers with a variant | Propose the variant (`clean-design.md`) |
| Copying the reference's 40px button height | Keep `h-9`; record it under conflicts |
| Estimating contrast by eye | Run `scripts/contraste.mjs` |
| Adding `"use client"` to every new file | Server by default; justify each client one |
| Writing validation inside the component | Pure function in `lib/validacion.ts`, shown with `Campo` |
| Forgetting gallery, docs, guide, README or registry | Checklist section D, every item |
| Reporting success with a failing build | Quote the error; the work is not done |
