# React 19 and Next.js 15 in khipu

khipu components are copied into other apps by the khipu CLI, so they must
work in any Next.js 15 App Router project.

## Server or Client Component

- **Server Component by default.** Add `"use client"` only when the component
  uses state, effects, event handlers, browser APIs, refs to DOM nodes, or
  context. Say why in the plan.
- base-ui primitives are interactive; components that wrap them are client
  components (as `ui/dialog.tsx`, `ui/popover.tsx` already are).
- Keep the client boundary small: a server wrapper can render a small client
  child instead of turning the whole tree into a client component.

## Props across the boundary

- Props passed from a Server Component to a Client Component must be
  serializable. Functions and lucide icon components are not. khipu rule:
  icons and callbacks are defined in a `"use client"` component (see the
  README "Regla del App Router").
- Prefer `ReactNode` slots (`icono={<FileIcon />}`) when a Server Component
  must pass an icon.

## Refs

- React 19 passes `ref` as a regular prop. Do **not** use `forwardRef` (khipu
  has none). Spread `...props` onto the root element so `ref` reaches it.

## Variants and class names

- Variants with `cva` and `VariantProps`, as `ui/badge.tsx`:

```tsx
const variantes = cva("base classes", {
  variants: { tono: { neutro: "…", ok: "…" } },
  defaultVariants: { tono: "neutro" },
});
type Props = React.ComponentProps<"div"> & VariantProps<typeof variantes>;
export function Ejemplo({ className, tono, ...props }: Props) {
  return <div className={cn(variantes({ tono }), className)} {...props} />;
}
```

- Merge classes with `cn` (`ui/` imports it from `"cn"`; the rest from
  `@/lib/utils`; follow the folder you are in). User `className` goes last so
  it can override.

## Controlled and uncontrolled

Components with their own state support both, like base-ui:

```tsx
const [interno, setInterno] = useState(defaultValue);
const controlado = value !== undefined;
const actual = controlado ? value : interno;
function cambiar(siguiente: T) {
  if (!controlado) setInterno(siguiente);
  onValueChange?.(siguiente);
}
```

## Ids and accessibility

- `useId()` for generated ids that link label, help and error
  (`aria-describedby`). Accept an `id` prop to override it.
- Use base-ui for overlays, menus, selects, sliders, tabs: it brings keyboard
  handling and ARIA. Do not rebuild those by hand.
- base-ui `render` prop changes the rendered element without losing behavior
  (see `ui/badge.tsx` with `useRender`).

## Avoid

- `useEffect` to derive state from props: compute it during render.
- `useMemo` / `useCallback` without a measured reason.
- Index keys on lists that reorder.
- Fetching data inside design-system components: data enters by props.
