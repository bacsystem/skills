# khipu checklist

Follow it in order for every component the plan creates or adjusts. Paths are
relative to the khipu-design-system root.

## A. Before writing code

1. Read `docs/design-system.md` sections for the area you touch, and §4
   «Escala de alturas»: every control is `h-9`.
2. Search `registry/registry.json` and `src/lib/estilos.ts` for what to reuse
   (see `clean-design.md`).
3. Pick the folder by what the component is:

| Folder | For |
|---|---|
| `src/components/ui/` | base primitives (button, popover, select…), mostly over base-ui |
| `src/components/patrones/` | small composed patterns (pills, section headers, copy button) |
| `src/components/feedback/` | toasts, alerts, banners, skeletons, empty states, progress |
| `src/components/formularios/` | fields and inputs |
| `src/components/navegacion/` | tabs, steps, side panels, menus, command palette |
| `src/components/datos/` | tables, lists, KPIs, charts, timelines |
| `src/components/nav/` | app shell: sidebar, top bar, user menu |

4. Name: file in Spanish kebab-case (`tarjeta-resumen.tsx`), exports in
   Spanish PascalCase (`TarjetaResumen`), props in Spanish camelCase
   (`titulo`, `onCambio`), as the existing components do.

## B. Writing the component

1. Imports through the `@/` alias only (the registry ignores relative imports).
2. A short JSDoc above each export, in Spanish.
3. Colors only through tokens (`bg-card`, `text-muted-foreground`,
   `border-border`…). No hex, no Tailwind palette colors (`bg-gray-100`).
4. New tokens, if approved, go in `src/app/globals.css` in all three places:
   `:root`, `.dark` and the `@theme inline` mapping.
5. When a token value changes (a T item), also update its row in
   `docs/design-system.md` §2 «Tokens de color» (light and dark values) and
   the matching swatches and values in `docs/guia-visual.html`.

## C. Quality list (all must hold; report each in the final summary)

**Reusable**
- [ ] Knows nothing about the app: routes, texts, icons, data and handlers by props.
- [ ] Accepts `className` (merged with `cn`, last) and forwards `...props` and `ref` to the root.
- [ ] Variants with `cva` when there is more than one look; sensible defaults.
- [ ] Controlled and uncontrolled (`value`/`defaultValue` + `onValueChange`) when it has its own state.
- [ ] Composition over configuration (`children`, subcomponents).

**Solid**
- [ ] Strict types: exported props type, no `any`, literal unions for variants.
- [ ] States resolved: default, hover, focus-visible, active, disabled (with the «próximamente» rule: `title="…: próximamente"`), loading, error, empty — those that apply.
- [ ] Accessible: native semantics or correct ARIA, keyboard operable, labels linked, AA contrast in light and dark.
- [ ] Robust with real data: long text (`min-w-0`, truncation), empty lists, `null` values, big numbers with `tabular-nums`.
- [ ] Responsive, and correct in light and dark.
- [ ] Server Component unless it needs `"use client"` (justified in the plan).
- [ ] Form fields validate by data type with `lib/validacion.ts` and show errors with `Campo` (see `field-validation.md`).

## D. Registering a new component

1. **Gallery:** add it to `src/app/ejemplo/galeria.tsx`, inside the
   `<section className={SECCION}>` of its group (or a new section with a
   `CabeceraSeccion` whose `subtitulo` lists the group's components). Show
   every variant and state. Import it at the top with the other imports of
   its folder, keeping alphabetical order.
2. **Docs:** in `docs/design-system.md`, by where the file lives:
   - `feedback/`, `formularios/`, `navegacion/` or `datos/` → add it to its
     row in §20 «Kit reutilizable»;
   - `ui/`, `nav/`, or a new `lib/` file (for example `validacion.ts`) → add it
     to its row in §19 «Inventario de componentes»;
   - `patrones/` → no table row; the lote paragraph is the record;
   - in every case, write a short lote paragraph in §20 like the existing ones
     (what it is, what base-ui primitive it uses, how it differs from the
     nearest existing component).
3. **Visual guide:** add a `<section>` with a `section-head` (`<h2>` + `<p>`
   with `<span class="src">carpeta/archivo.tsx</span>`) to
   `docs/guia-visual.html`, near the related sections, with static HTML that
   mirrors the component in light and dark.
4. **README:** add the file name to its folder line in the «Estructura»
   block of `README.md`.
5. **Registry:** after all changes, run `npm run registry:build` (never edit
   `registry/registry.json` by hand).

## E. Adjusting an existing component

- Never remove or rename a component, export, prop or token.
- Allowed: change values, add optional props, add variants, add tokens.
- Update its section in `docs/design-system.md` and `docs/guia-visual.html`
  if its look changes.

## F. Verification (run each one separately)

```bash
npm run typecheck
npm run lint
npm run build
npm run registry:build
```

`npm run lint` includes `check:alturas`, which rejects control heights other
than `h-9`. Then `npm run dev` and review `/ejemplo` in light and dark.
