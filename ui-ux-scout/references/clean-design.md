# DRY and SOLID for khipu components

## DRY

- **Search before creating.** Check `registry/registry.json` (every component
  and its dependencies), `src/lib/estilos.ts` (recipes: `CAMPO`,
  `BOTON_PRIMARIO`, `TARJETA`, `ETIQUETA_CAMPO`, `AYUDA_CAMPO`,
  `POPUP_LISTA`…) and `src/lib/` (`formato.ts`, `paginacion.ts`, `utils.ts`).
- **Extend before adding.** If an existing component covers the case with a
  new variant or an optional prop, propose that instead of a new component.
  The plan must justify every new component against extending one.
- **One home per rule.** A validation rule, a formatter or a class recipe
  lives in one place and is imported. Repeating a long class string in two
  components is a finding: move it to `lib/estilos.ts`.
- **Rule of two.** Extract an abstraction when there are two real uses, not
  for a hypothetical second one.
- **Not all similarity is duplication.** Two components that look alike but
  change for different reasons stay separate.

## SOLID, adapted to components

| Principle | In a khipu component |
|---|---|
| **Single responsibility** | A component presents. Logic (validation, formatting, pagination) lives in `lib/` as pure functions. |
| **Open/closed** | Extend through `cva` variants, optional props and composition (`children`, subcomponents). Adding a variant must not change existing ones. |
| **Liskov substitution** | A component wrapping a native element accepts and forwards its props (`React.ComponentProps<"input">`, `...props`), so it can replace the element anywhere, as `Entrada` does. |
| **Interface segregation** | Small, specific props. No giant `config` objects; no props that only one caller uses. Split into subcomponents when props diverge. |
| **Dependency inversion** | Routes, texts, icons, data and handlers enter by props. The component never imports app code, never fetches and never knows the route it lives on. |

## Smells that block a component

- A prop named after a single caller (`esPantallaFacturas`).
- Boolean props that combine into impossible states (`cargando` + `vacio`):
  use one `estado` union instead.
- A component that formats, validates, fetches and renders.
- Copy-pasted JSX between two components that should share a subcomponent.
