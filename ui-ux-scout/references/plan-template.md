# Plan template

The plan is shown in the terminal before any file is touched. Use these
headings exactly: Spanish by default, English with `--en`.

| `--es` | `--en` |
|---|---|
| `## Estilo de referencia` | `## Reference style` |
| `## Componentes nuevos` | `## New components` |
| `## Componentes a ajustar` | `## Components to adjust` |
| `## Tokens` | `## Tokens` |
| `## Conflictos con convenciones` | `## Convention conflicts` |
| `## Archivos que se tocarán` | `## Files to touch` |
| `## Para aprobar` | `## To approve` |

The examples below are in Spanish. With `--en`, write the whole plan in English: headings from the table above, and field labels and the approval sentence translated the same way (for example `Qué es` → `What it is`, `Por qué nuevo y no extender` → `Why new instead of extending`, `Reutiliza` → `Reuses`, `Depende de` → `Depends on`, `Claro` / `Oscuro` → `Light` / `Dark`, `Contraste` → `Contrast`). Component names, file paths, token names and plan IDs (`N1`, `A1`, `T1`, `C1`) never change.

## Content of each section

**Estilo de referencia**: name, source URL, theme, extraction method
(`script` or `WebFetch`, with the precision warning when WebFetch), and the
two or three system decisions taken from it.

**Componentes nuevos**: one block per component, with its ID `N1`, `N2`…:

```
### N1 · TarjetaResumen  (datos/tarjeta-resumen.tsx)
- Qué es: …
- Por qué nuevo y no extender <existente>: …
- API: titulo: string · valor: ReactNode · tendencia?: "sube" | "baja" · className
- Server/Client: Server (sin estado ni eventos)
- base-ui: — | <primitive>
- Reutiliza: TARJETA, ETIQUETA_DATO (lib/estilos.ts), Kpi
- Depende de: — | T<n>
- Validación: — | tipo de dato + reglas + mensaje
- Estados: …
```

**Componentes a ajustar**: ID `A1`, `A2`…: file, what changes and why, and
"API: sin cambios" or the optional prop added, and the same
`- Depende de: — | T<n>` line listing the tokens it needs.

**Tokens**: ID `T1`, `T2`…, one per token, each approved separately:

```
### T1 · --card
- Claro: <actual> → <nuevo>   Oscuro: <actual> → <nuevo>
- Contraste: --card-foreground sobre --card: <ratio>:1 (AA ✓)
- Afecta a todos los consumidores de khipu.
```

**Conflictos con convenciones**: ID `C1`…: what the reference asks, which
khipu rule it hits, and the resolution (khipu wins).

**Archivos que se tocarán**: the full list, grouped by create / modify.

**Para aprobar**: one line asking for approval by ID. With `--es`:
«Responde "sí" para aplicar los componentes y ajustes (N, A, C), o indica qué IDs quitar o cambiar (p. ej. "sin N2, N3 con otro nombre"). Cada token se aprueba nombrándolo: "sí T1", "sí T1 T3"; un "sí" solo no aprueba tokens.»

With `--en`:
«Reply "sí" to apply the components and adjustments (N, A, C), or list the IDs to drop or change (e.g. "without N2, rename N3"). Each token is approved by naming it: "sí T1", "sí T1 T3"; a bare "sí" never approves tokens.»
