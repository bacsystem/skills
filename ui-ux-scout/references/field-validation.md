# Field validation by data type

## Where it lives

- Rules are pure functions in `src/lib/validacion.ts`, created the first time
  a component needs one. Each function takes the value (and options) and
  returns `null` when valid or the error message in Spanish.
- It enters the khipu registry as a `lib` item: `scripts/build-registry.mjs`
  lists `lib` files explicitly, so add `join(SRC, "lib", "validacion.ts")` to
  the `archivos` array there when you create the file.
- Presentation already exists; reuse it:
  - `Campo` (`formularios/campo.tsx`): prop `error` renders the message with
    `role="alert"` and id `${id}-error`.
  - `Entrada` / `AreaTexto`: prop `invalido` sets `aria-invalid` and the red
    border.
- No validation library (zod, yup…) without approving it in the plan as a
  separate item: it would become a dependency of every consumer.

## Shape

```ts
export type Regla<T> = (valor: T) => string | null;

/** Primera regla que falla, o null. */
export function validar<T>(valor: T, reglas: Regla<T>[]): string | null {
  for (const regla of reglas) {
    const error = regla(valor);
    if (error) return error;
  }
  return null;
}

export const requerido = (mensaje = "Este campo es obligatorio."): Regla<string> => (v) =>
  v.trim() === "" ? mensaje : null;
```

## Rules by data type (minimum)

| Type | Control | Rules | Example message |
|---|---|---|---|
| Text | `Entrada` | required, min/max length, trim | «Escribe al menos 3 caracteres.» |
| Email | `Entrada type="email"` | email format | «Escribe un correo válido, como nombre@empresa.pe.» |
| Integer / decimal | `StepperNumerico` / `Entrada inputMode="decimal"` | numeric, min/max, allowed decimals | «Debe estar entre 1 y 999.» |
| Amount | `EntradaMonto` | ≥ 0 unless stated, 2 decimals, consistent with `formatearMonto` | «El monto no puede ser negativo.» |
| Date / range | `EntradaFecha` / `EntradaRangoFechas` | valid ISO date, min/max, start ≤ end, zone `America/Lima` (`lib/formato.ts`) | «La fecha final debe ser posterior a la inicial.» |
| RUC | `Entrada mono` | 11 digits, prefix 10, 15, 17 or 20, check digit | «El RUC tiene 11 dígitos.» / «El RUC no es válido.» |
| DNI | `Entrada mono` | 8 digits | «El DNI tiene 8 dígitos.» |
| Phone | `Entrada type="tel"` | digits and leading `+`, length 9–15 | «Escribe un teléfono de 9 a 15 dígitos.» |
| URL | `Entrada type="url"` | absolute `http(s)` URL | «Escribe una URL que empiece con https://.» |
| Password | `Contrasena` | minimum length and the case's rules | «Usa al menos 8 caracteres.» |
| File | `ZonaArchivos` | MIME type / extension and max size | «Solo PDF de hasta 5 MB.» |

### RUC check digit (SUNAT, módulo 11)

```ts
export function rucValido(ruc: string): boolean {
  if (!/^(10|15|17|20)\d{9}$/.test(ruc)) return false;
  const pesos = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2];
  const suma = pesos.reduce((s, p, i) => s + p * Number(ruc[i]), 0);
  const digito = (11 - (suma % 11)) % 10;
  return digito === Number(ruc[10]);
}
```

Test cases for it: `20100070970` valid; `20100070971` invalid (wrong check
digit); `30100070970` invalid (prefix); `2010007097` invalid (10 digits).

## When it validates

- On blur and on submit; not while typing the first time.
- Once an error is shown, revalidate on every change so it clears as soon as
  the value is fixed.
- One error per field: the first failing rule.

## Messages

- Say what is expected, not just that it is wrong: «El RUC tiene 11 dígitos»,
  not «RUC inválido».
- Spanish, sentence case, ending with a period. No codes, no blame.

## Native attributes

Use `required`, `type`, `inputMode`, `min`, `max`, `maxLength`, `pattern` as
well as the function, for mobile keyboards and assistive tech. Never instead
of it: native validation alone cannot express khipu's messages.

## Testing

khipu has no test runner today. If the plan creates `lib/validacion.ts`, it
proposes how to test it (for example `node --test` over the cases in this
file, with Node's TypeScript type stripping or a small `.mjs` test that
imports the compiled logic). Adding the runner to khipu is approved in the
plan as a separate item.
