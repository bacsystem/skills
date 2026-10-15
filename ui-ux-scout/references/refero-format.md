# Refero Styles page format

How `scripts/refero-fetch.mjs` reads a style. Verified against a real page on
2026-10-14 (Raycast, `3b6a17f0-3bdf-418c-a95e-0b89e5a8b2f8`). When Refero
changes its site, update this file and the parser together.

## Where the data is

- Style page: `https://styles.refero.design/style/<uuid>`. There is **no raw
  DESIGN.md URL**: the DESIGN.md, Tailwind and CSS-variable tabs on the page
  are all rendered from one structured object.
- That object travels in the Next.js flight payload: several
  `<script>self.__next_f.push([1,"<js string>"])</script>` chunks. Each
  `<js string>` is JSON-string-escaped; decode each one with `JSON.parse` and
  concatenate them in order.
- In the decoded text, the style object is the innermost JSON object that
  contains the marker `"colors":[{"hex"`. It is nested inside React element
  props, so the parser walks back from the marker to the nearest `{` whose
  object both parses and owns the key `colors`.
- Name: the `<title>`, in the form `<Name> design system | Refero Styles`.

## Keys of the style object (as of 2026-10-14)

| Key | Shape | Notes |
|---|---|---|
| `theme` | `"dark"` \| `"light"` | |
| `description`, `northStar`, `layout`, `elevationPhilosophy`, `imagery`, `industry` | string | free text |
| `colors` | `[{hex, name, role, group}]` | `group`: `neutral`, `accent`, … |
| `surfaces` | `[{hex, name, level, purpose}]` | `level` 0 = page canvas |
| `typography` | `[{family, role, weight, sizes, lineHeight, letterSpacing, substitute, fontFeatureSettings}]` | `weight` and `sizes` are comma-separated strings |
| `typeScale` | `[{role, size, lineHeight, letterSpacing}]` | numbers (px, ratio, px) |
| `spacing` | `{radius: {buttons, inputs, cards, …}, elementGap, sectionGap, cardPadding, pageMaxWidth}` | string values (`"8px"`, `"8-16px"`) |
| `elevation` | `[{style, element}]` | |
| `components` | `[{name, role, description}]` | description cites hex and px |
| `dos`, `donts` | `string[]` | |
| `similar` | `[{why, business}]` | not exported by the script |
| `customSections` | `[{title, content}]` | not exported by the script |

The script exports a normalized subset (see the `Estilo` shape in the script):
missing keys become `[]` or `null`, never invented values.

## Not found

An unknown UUID still returns **HTTP 200**. The page title is
`Style not found — Refero Styles` and the payload carries
`NEXT_HTTP_ERROR_FALLBACK;404`. The script maps that to exit code `2`.

## Plan B (WebFetch)

Use it when Node ≥ 18 is missing, or the script exits with `3` (format
changed) or `4` with no cache. Fetch the style URL with WebFetch and ask for
the color, typography, spacing/radius, shadow and component tables **verbatim,
as Markdown tables, without summarizing**. Then mark the plan with:

> Valores extraídos vía WebFetch: pueden no ser exactos; verifícalos antes de aplicarlos.

WebFetch runs the page through a small model, so hex and px values may come
back rounded or dropped. Never present them as exact.
