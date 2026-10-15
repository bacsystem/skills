# UI/UX principles

What "expert UI/UX judgment" means when turning a Refero style into khipu
components. Read before writing the plan.

## Take the system, not the brand

| Take from the reference | Do not take |
|---|---|
| Surface and elevation steps (how many, how far apart) | Its brand accent as khipu's identity color |
| Type scale ratios, weights per role, tracking at sizes | Its logo, illustrations, imagery, copy |
| Radius scale per element type | Its exact layout of marketing pages |
| Component anatomy and states (what a card, badge, nav has) | Decorative effects that only serve its marketing site (hero gradients, glows) |
| Density and spacing rhythm | Rules that contradict khipu conventions |

A finding of the form "use their color" is not a design decision. Translate it
into a role: "accent surfaces need a desaturated tint step" is.

## Hierarchy

- One primary action per view. Secondary actions are visually quieter, not
  just smaller.
- Hierarchy comes from size, weight and color contrast together; never from
  color alone.
- Data (ids, amounts, dates) in mono with `tabular-nums` (khipu rule), so
  columns align.

## Contrast (WCAG 2.2, level AA)

| Pair | Minimum |
|---|---|
| Body text vs background | 4.5:1 |
| Large text (≥ 24px, or ≥ 18.66px bold) | 3:1 |
| UI component boundaries, icons, focus indicators vs adjacent colors | 3:1 |
| Disabled controls | exempt, but must still read as disabled |

Compute contrast; never estimate it. Run the script that ships with the skill
(zero dependencies, Node 18+):

```bash
node <skill dir>/scripts/contraste.mjs <texto> <fondo> [base]
# node <skill dir>/scripts/contraste.mjs "#94a3b8" "#111827"
```

It prints the ratio with two decimals and exits `1` with a message on a color
it cannot read.

- **Accepted colors:** `#rgb`, `#rgba`, `#rrggbb`, `#rrggbbaa`, `rgb()` and
  `rgba()` (commas, or the space/slash form `rgb(10 20 30 / 0.5)`).
- **Transparency:** a color with alpha (`rgba`, 8-digit hex) is composited over
  `base`, the opaque surface beneath it. `base` defaults to white. For dark
  tokens pass the dark surface, for example `--card`:
  `contraste.mjs "rgba(226,232,240,0.12)" "#111827" "#111827"`.
- **khipu tokens** in `globals.css` are hex or rgba, so they go in as they are;
  nothing needs converting.

## Density

- Management apps favor information density: khipu uses one control height
  (`h-9`, 36px) and 46px table rows. A reference with 40–48px controls does
  not change that; take its padding rhythm, not its heights.
- Spacing snaps to the existing scale. Do not introduce one-off values.

## States

Every interactive component resolves, when they apply: default, hover,
focus-visible, active/pressed, selected, disabled, loading, error, empty.
A state that exists in the reference but not in khipu is a candidate finding.

## Focus and targets

- Focus is always visible (`focus-visible:` ring of at least 2px and 3:1
  against the background). Never remove an outline without a replacement.
- Pointer targets at least 24×24 CSS px (WCAG 2.5.8). khipu's `h-9` meets it;
  icon-only buttons need `size-9` or a padded hit area.

## Motion

- Short and functional (150–200ms for UI feedback). Respect
  `prefers-reduced-motion` (Tailwind `motion-safe:` / `motion-reduce:`).

## Dark mode

- Not an inversion. Elevation goes up by making surfaces lighter, not by
  adding shadows.
- Desaturate and lighten accents so they do not vibrate on dark backgrounds.
- Re-check every contrast pair in dark; values that pass in light often fail.
- If the reference has only one theme, derive the other and label it
  "derived" in the plan.
