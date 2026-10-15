# ui-ux-scout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Crear la skill `ui-ux-scout` en `bacsystem/skills`: toma el estilo de Refero Styles indicado por UUID y guía a Claude para crear componentes en `khipu-design-system` con criterio experto (UI/UX, React 19 / Next.js 15, DRY, SOLID, validación por tipo de dato).

**Architecture:** Un script Node sin dependencias (`scripts/refero-fetch.mjs`) descarga la página del estilo, decodifica el payload de Next.js y entrega JSON exacto, con caché en el temporal del sistema. El `SKILL.md` define el flujo (comprobar khipu → leer contexto → extraer → plan → aprobación → aplicar → verificar) y delega el criterio en seis archivos de `references/`. La skill no tiene código propio fuera del script: todo lo demás son instrucciones.

**Tech Stack:** Node ≥ 18 (`fetch` nativo, `node:test`), Markdown. Destino: khipu-design-system (Next.js 15, React 19, Tailwind v4, base-ui, cva).

**Spec:** `docs/superpowers/specs/2026-10-14-ui-ux-scout-skill-design.md`

## Global Constraints

- Repo de trabajo: `D:/github/skills`, rama `feat/ui-ux-scout` (ya creada desde `origin/main`).
- Comandos: uno por invocación, sin `&&` ni `cd`; git con `git -C D:/github/skills …` (regla de `D:/github/CLAUDE.md`).
- Script: Node ≥ 18, **cero dependencias**, ESM (`.mjs`).
- Entrada de la skill: **solo UUID** o URL `https://styles.refero.design/style/<uuid>`. Sin búsqueda por nombre.
- Códigos de salida del script: `0` OK; `1` entrada inválida; `2` estilo no encontrado; `3` payload no reconocible; `4` error de red.
- Caché: `<os.tmpdir()>/ui-ux-scout/<uuid>.json`, válida 7 días. Nunca dentro de khipu.
- Fixtures de test **sintéticos**: ningún contenido real de Refero se commitea.
- `SKILL.md`, `README.md` y `references/` en inglés (convención del repo: ver `pr-review/`); nombres de componentes, mensajes de error y documentación de khipu en español.
- La skill **nunca** commitea en khipu: deja el árbol de trabajo para `git-flow`.
- Commits del repo `skills` en Conventional Commits, en español, con el trailer:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` y
  `Claude-Session: https://claude.ai/code/session_015P5t8kWo8bqwEgcFfnbcpB`.
- `CHANGELOG.md`: la entrada va bajo `## [Sin publicar]`; el número de versión lo pone `git-flow` al publicar.

## Review Focus

1. **UUID inexistente con HTTP 200**: Refero responde 200 con una página «Style not found» (verificado el 2026-10-14). Debe salir con código `2`, no `3`. → Tests en Task 1 (`parsearPagina`) y Task 2 (`obtenerEstilo` con 200 + página 404).
2. **URL pegada desde el navegador con query, hash o barra final** (`…/style/<uuid>?utm_source=x`, `…/<uuid>/`), o UUID en mayúsculas: debe aceptarse y normalizarse a minúsculas, para que la caché use una sola clave. → Tests en Task 1.
3. **Caché corrupta** (archivo truncado o no JSON): se trata como ausente y se vuelve a descargar, sin fallar. → Test en Task 2.
4. **Caché no escribible** (directorio de caché inválido): el resultado se imprime igual; la caché es una optimización, no un requisito. → Test en Task 2.
5. **Sin red con caché vencida**: devuelve la copia vieja con un aviso en stderr que incluye la fecha, en lugar de fallar. → Test en Task 2.

---

### Task 1: Parser del payload de Refero

Funciones puras que convierten el HTML de una página de estilo en JSON normalizado. Incluye la documentación del formato y la corrección del contrato en el spec con los datos reales.

**Files:**
- Create: `D:/github/skills/ui-ux-scout/scripts/refero-fetch.mjs`
- Create: `D:/github/skills/ui-ux-scout/scripts/test-refero-fetch.mjs`
- Create: `D:/github/skills/ui-ux-scout/references/refero-format.md`
- Modify: `D:/github/skills/docs/superpowers/specs/2026-10-14-ui-ux-scout-skill-design.md` (sección «Contrato del script», flujo pasos 2 y 6, pruebas)

**Interfaces:**
- Consumes: nada.
- Produces (exports de `refero-fetch.mjs`):
  - `BASE: string` = `"https://styles.refero.design/style/"`
  - `SALIDA: { OK: 0, ENTRADA_INVALIDA: 1, NO_ENCONTRADO: 2, FORMATO: 3, RED: 4 }`
  - `class ErrorRefero extends Error { codigo: number }`
  - `extraerUuid(entrada: string): string`: UUID en minúsculas o lanza `ErrorRefero(1)`
  - `esNoEncontrado(html: string): boolean`
  - `decodificarFlight(html: string): string`: lanza `ErrorRefero(3)` si un fragmento no decodifica
  - `buscarObjetoEstilo(flight: string): object | null`
  - `extraerNombre(html: string): string | null`
  - `normalizarEstilo(crudo: object, { uuid, nombre }): Estilo`
  - `parsearPagina(html: string, uuid: string): Estilo`: lanza `ErrorRefero(2)` o `ErrorRefero(3)`
  - `Estilo` = `{ source, uuid, name, theme, description, northStar, colors[{name,hex,role,group}], surfaces[{name,hex,level,purpose}], typography[{family,role,weight,sizes,lineHeight,letterSpacing,substitute,fontFeatureSettings}], typeScale[{role,size,lineHeight,letterSpacing}], spacing: object|null, elevation[{element,style}], elevationPhilosophy, components[{name,role,description}], layout, dos: string[], donts: string[] }`

- [ ] **Step 1: Escribir los tests que fallan**

Crear `D:/github/skills/ui-ux-scout/scripts/test-refero-fetch.mjs`:

```js
// Tests de refero-fetch.mjs. Sin red: las páginas son sintéticas e imitan la estructura
// real (payload de Next.js en self.__next_f.push), sin contenido de Refero.
// Ejecutar: node --test ui-ux-scout/scripts/test-refero-fetch.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import {
  BASE,
  SALIDA,
  ErrorRefero,
  extraerUuid,
  extraerNombre,
  parsearPagina,
} from "./refero-fetch.mjs";

const UUID = "3b6a17f0-3bdf-418c-a95e-0b89e5a8b2f8";

const ESTILO = {
  dos: ["Usar radios de 8px en controles"],
  donts: ["No usar sombras exteriores en tarjetas"],
  theme: "dark",
  colors: [
    { hex: "#101010", name: "Carbón", role: "Fondo de página", group: "neutral" },
    { hex: "#ff5500", name: "Brasa", role: "Acento de marca", group: "accent" },
  ],
  layout: "Una columna centrada de 1200px",
  spacing: { radius: { buttons: "8px", cards: "16px" }, cardPadding: "24px" },
  surfaces: [{ hex: "#101010", name: "Canvas", level: 0, purpose: "Fondo" }],
  elevation: [{ style: "Sin sombra; borde de 1px", element: "Tarjeta" }],
  typeScale: [{ role: "body", size: 16, lineHeight: 1.5, letterSpacing: 0 }],
  components: [{ name: "Botón", role: "Acción principal", description: "Relleno claro, 8px de radio" }],
  typography: [
    {
      role: "Interfaz",
      sizes: "12px, 14px, 16px",
      family: "Inter",
      weight: "400, 500",
      lineHeight: "1.5",
      substitute: "system-ui, sans-serif",
      letterSpacing: "0",
      fontFeatureSettings: "'kern'",
    },
  ],
  description: "Sistema oscuro de prueba",
  northStar: "Calma",
  elevationPhilosophy: "Plano, el borde hace el trabajo",
};

// Reparte el flight en dos fragmentos, como hace Next.js, para probar la concatenación.
function pagina(flight, titulo = "Acme design system | Refero Styles") {
  const mitad = Math.floor(flight.length / 2);
  const fragmento = (s) => `<script>self.__next_f.push([1,${JSON.stringify(s)}])</script>`;
  return `<!DOCTYPE html><html><head><title>${titulo}</title></head><body>${fragmento(flight.slice(0, mitad))}${fragmento(flight.slice(mitad))}</body></html>`;
}

// El objeto del estilo va anidado dentro de un elemento de React, como en la página real.
const paginaConEstilo = (estilo, titulo) =>
  pagina(`0:{"P":null}\n5:["$","div",null,{"className":"x","children":[["$","pre",null,{"data":${JSON.stringify(estilo)}}]]}]\n`, titulo);

const PAGINA_NO_ENCONTRADA =
  `<!DOCTYPE html><html><head><title>Style not found — Refero Styles</title></head><body>` +
  `<script>self.__next_f.push([1,"0:{\\"digest\\":\\"NEXT_HTTP_ERROR_FALLBACK;404\\"}\\n"])</script></body></html>`;

function codigoDe(fn) {
  try {
    fn();
  } catch (error) {
    assert.ok(error instanceof ErrorRefero, `se esperaba ErrorRefero, llegó ${error}`);
    return error.codigo;
  }
  assert.fail("se esperaba un ErrorRefero");
}

test("extraerUuid acepta un UUID suelto y lo pasa a minúsculas", () => {
  assert.equal(extraerUuid(UUID), UUID);
  assert.equal(extraerUuid(`  ${UUID.toUpperCase()} `), UUID);
});

test("extraerUuid acepta la URL del estilo con barra final, query o hash", () => {
  assert.equal(extraerUuid(`${BASE}${UUID}`), UUID);
  assert.equal(extraerUuid(`${BASE}${UUID}/`), UUID);
  assert.equal(extraerUuid(`${BASE}${UUID}?utm_source=x`), UUID);
  assert.equal(extraerUuid(`${BASE}${UUID}#tokens`), UUID);
});

test("extraerUuid rechaza nombres, UUID incompletos y URL de otro host", () => {
  assert.equal(codigoDe(() => extraerUuid("Raycast")), SALIDA.ENTRADA_INVALIDA);
  assert.equal(codigoDe(() => extraerUuid(UUID.slice(0, 35))), SALIDA.ENTRADA_INVALIDA);
  assert.equal(codigoDe(() => extraerUuid(`https://evil.example/style/${UUID}`)), SALIDA.ENTRADA_INVALIDA);
  assert.equal(codigoDe(() => extraerUuid("")), SALIDA.ENTRADA_INVALIDA);
});

test("parsearPagina devuelve los valores exactos del estilo", () => {
  const estilo = parsearPagina(paginaConEstilo(ESTILO), UUID);
  assert.equal(estilo.source, `${BASE}${UUID}`);
  assert.equal(estilo.uuid, UUID);
  assert.equal(estilo.name, "Acme");
  assert.equal(estilo.theme, "dark");
  assert.deepEqual(estilo.colors, [
    { name: "Carbón", hex: "#101010", role: "Fondo de página", group: "neutral" },
    { name: "Brasa", hex: "#ff5500", role: "Acento de marca", group: "accent" },
  ]);
  assert.deepEqual(estilo.surfaces, [{ name: "Canvas", hex: "#101010", level: 0, purpose: "Fondo" }]);
  assert.equal(estilo.typography[0].family, "Inter");
  assert.equal(estilo.typography[0].weight, "400, 500");
  assert.deepEqual(estilo.typeScale, [{ role: "body", size: 16, lineHeight: 1.5, letterSpacing: 0 }]);
  assert.deepEqual(estilo.spacing, { radius: { buttons: "8px", cards: "16px" }, cardPadding: "24px" });
  assert.deepEqual(estilo.elevation, [{ element: "Tarjeta", style: "Sin sombra; borde de 1px" }]);
  assert.deepEqual(estilo.components, [{ name: "Botón", role: "Acción principal", description: "Relleno claro, 8px de radio" }]);
  assert.deepEqual(estilo.dos, ["Usar radios de 8px en controles"]);
  assert.deepEqual(estilo.donts, ["No usar sombras exteriores en tarjetas"]);
  assert.equal(estilo.layout, "Una columna centrada de 1200px");
  assert.equal(estilo.northStar, "Calma");
});

test("parsearPagina devuelve [] o null para los campos ausentes, sin inventarlos", () => {
  const estilo = parsearPagina(paginaConEstilo({ theme: "light", colors: [{ hex: "#ffffff", name: "Blanco" }] }), UUID);
  assert.deepEqual(estilo.colors, [{ name: "Blanco", hex: "#ffffff", role: null, group: null }]);
  assert.deepEqual(estilo.typography, []);
  assert.deepEqual(estilo.components, []);
  assert.deepEqual(estilo.dos, []);
  assert.equal(estilo.spacing, null);
  assert.equal(estilo.layout, null);
  assert.equal(estilo.description, null);
});

test("parsearPagina marca como no encontrado el UUID inexistente aunque la respuesta sea 200", () => {
  assert.equal(codigoDe(() => parsearPagina(PAGINA_NO_ENCONTRADA, UUID)), SALIDA.NO_ENCONTRADO);
});

test("parsearPagina marca formato cambiado cuando no hay objeto con colors", () => {
  const sinEstilo = pagina(`0:{"P":null}\n1:["$","div",null,{"children":"hola"}]\n`);
  assert.equal(codigoDe(() => parsearPagina(sinEstilo, UUID)), SALIDA.FORMATO);
  assert.equal(codigoDe(() => parsearPagina("<html><body>sin payload</body></html>", UUID)), SALIDA.FORMATO);
});

test("parsearPagina marca formato cambiado cuando un fragmento no decodifica", () => {
  const roto = `<html><body><script>self.__next_f.push([1,"\\x"])</script></body></html>`;
  assert.equal(codigoDe(() => parsearPagina(roto, UUID)), SALIDA.FORMATO);
});

test("extraerNombre limpia el sufijo de Refero y decodifica entidades", () => {
  assert.equal(extraerNombre("<title>Ben &amp; Jerry design system | Refero Styles</title>"), "Ben & Jerry");
  assert.equal(extraerNombre("<title>Solo | Refero Styles</title>"), "Solo");
  assert.equal(extraerNombre("<html></html>"), null);
});
```

- [ ] **Step 2: Ejecutar los tests y comprobar que fallan**

Run: `node --test D:/github/skills/ui-ux-scout/scripts/test-refero-fetch.mjs`
Expected: FAIL, `Cannot find module` … `refero-fetch.mjs`.

- [ ] **Step 3: Implementar el parser**

Crear `D:/github/skills/ui-ux-scout/scripts/refero-fetch.mjs`:

```js
#!/usr/bin/env node
// Descarga un estilo de Refero Styles por UUID y lo imprime como JSON normalizado.
// La página no expone un DESIGN.md crudo: los datos viajan en el payload de Next.js
// (self.__next_f.push) y de ahí se extraen tal cual, sin pasar por un modelo que resuma.
// Formato documentado en ../references/refero-format.md.

export const BASE = "https://styles.refero.design/style/";

export const SALIDA = Object.freeze({ OK: 0, ENTRADA_INVALIDA: 1, NO_ENCONTRADO: 2, FORMATO: 3, RED: 4 });

export class ErrorRefero extends Error {
  constructor(codigo, mensaje) {
    super(mensaje);
    this.name = "ErrorRefero";
    this.codigo = codigo;
  }
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

export function extraerUuid(entrada) {
  const texto = String(entrada ?? "").trim();
  let candidato = texto.toLowerCase();
  if (texto.includes("://")) {
    let url = null;
    try {
      url = new URL(texto);
    } catch {
      // URL mal formada: cae al rechazo de abajo.
    }
    const ruta = url?.hostname === "styles.refero.design" ? url.pathname.match(/^\/style\/([^/]+)\/?$/) : null;
    candidato = ruta ? ruta[1].toLowerCase() : "";
  }
  if (!UUID_RE.test(candidato)) {
    throw new ErrorRefero(SALIDA.ENTRADA_INVALIDA, `"${texto}" no es un UUID ni una URL de estilo válida. Formato esperado: ${BASE}<uuid>`);
  }
  return candidato;
}

// Refero responde 200 también para un UUID inexistente; lo que lo delata es la página de 404 de Next.
export function esNoEncontrado(html) {
  return html.includes("NEXT_HTTP_ERROR_FALLBACK;404") || /<title>\s*Style not found/i.test(html);
}

const FRAGMENTO_RE = /self\.__next_f\.push\(\[1,"((?:[^"\\]|\\.)*)"\]\)/g;

export function decodificarFlight(html) {
  let flight = "";
  for (const m of html.matchAll(FRAGMENTO_RE)) {
    try {
      flight += JSON.parse(`"${m[1]}"`);
    } catch {
      throw new ErrorRefero(SALIDA.FORMATO, "Un fragmento del payload de Next.js no se pudo decodificar: el formato de Refero cambió.");
    }
  }
  return flight;
}

// Índice de la llave que cierra el objeto abierto en `inicio`, respetando cadenas; -1 si no cierra.
function cierreDeObjeto(texto, inicio) {
  let profundidad = 0;
  let enCadena = false;
  let escape = false;
  for (let k = inicio; k < texto.length; k++) {
    const c = texto[k];
    if (enCadena) {
      if (escape) escape = false;
      else if (c === "\\") escape = true;
      else if (c === '"') enCadena = false;
    } else if (c === '"') enCadena = true;
    else if (c === "{") profundidad++;
    else if (c === "}" && --profundidad === 0) return k;
  }
  return -1;
}

const MARCA = '"colors":[{"hex"';
const VENTANA = 100_000; // cuánto retrocede desde la marca buscando la llave que abre el objeto

// El objeto del estilo es el objeto JSON más interno que contiene la marca "colors":[{"hex".
export function buscarObjetoEstilo(flight) {
  for (let pos = flight.indexOf(MARCA); pos !== -1; pos = flight.indexOf(MARCA, pos + 1)) {
    for (let k = pos; k >= Math.max(0, pos - VENTANA); k--) {
      if (flight[k] !== "{") continue;
      const fin = cierreDeObjeto(flight, k);
      if (fin < pos) continue;
      let objeto;
      try {
        objeto = JSON.parse(flight.slice(k, fin + 1));
      } catch {
        continue;
      }
      if (Object.hasOwn(objeto, "colors")) return objeto;
      break;
    }
  }
  return null;
}

const ENTIDADES = { "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": '"', "&#x27;": "'", "&#39;": "'" };

export function extraerNombre(html) {
  const titulo = html.match(/<title>([^<]*)<\/title>/)?.[1];
  if (!titulo) return null;
  const limpio = titulo
    .replace(/&(?:amp|lt|gt|quot|#x27|#39);/g, (e) => ENTIDADES[e])
    .replace(/\s+design system\s*\|\s*Refero Styles\s*$/i, "")
    .replace(/\s*\|\s*Refero Styles\s*$/i, "")
    .trim();
  return limpio || null;
}

const texto = (v) => (typeof v === "string" && v.trim() !== "" ? v : null);
const lista = (v) => (Array.isArray(v) ? v : []);
const objeto = (v) => (v && typeof v === "object" && !Array.isArray(v) ? v : null);
const filas = (v, claves) =>
  lista(v)
    .filter(objeto)
    .map((o) => Object.fromEntries(claves.map((c) => [c, o[c] ?? null])));
const cadenas = (v) => lista(v).filter((s) => typeof s === "string");

export function normalizarEstilo(crudo, { uuid, nombre }) {
  return {
    source: BASE + uuid,
    uuid,
    name: nombre,
    theme: texto(crudo.theme),
    description: texto(crudo.description),
    northStar: texto(crudo.northStar),
    colors: filas(crudo.colors, ["name", "hex", "role", "group"]),
    surfaces: filas(crudo.surfaces, ["name", "hex", "level", "purpose"]),
    typography: filas(crudo.typography, ["family", "role", "weight", "sizes", "lineHeight", "letterSpacing", "substitute", "fontFeatureSettings"]),
    typeScale: filas(crudo.typeScale, ["role", "size", "lineHeight", "letterSpacing"]),
    spacing: objeto(crudo.spacing),
    elevation: filas(crudo.elevation, ["element", "style"]),
    elevationPhilosophy: texto(crudo.elevationPhilosophy),
    components: filas(crudo.components, ["name", "role", "description"]),
    layout: texto(crudo.layout),
    dos: cadenas(crudo.dos),
    donts: cadenas(crudo.donts),
  };
}

export function parsearPagina(html, uuid) {
  if (esNoEncontrado(html)) {
    throw new ErrorRefero(SALIDA.NO_ENCONTRADO, `No existe un estilo con UUID ${uuid} en Refero Styles.`);
  }
  const crudo = buscarObjetoEstilo(decodificarFlight(html));
  if (!crudo) {
    throw new ErrorRefero(SALIDA.FORMATO, 'La página no trae el objeto del estilo (sin "colors"): el formato de Refero cambió. Usa el plan B con WebFetch.');
  }
  return normalizarEstilo(crudo, { uuid, nombre: extraerNombre(html) });
}
```

- [ ] **Step 4: Ejecutar los tests y comprobar que pasan**

Run: `node --test D:/github/skills/ui-ux-scout/scripts/test-refero-fetch.mjs`
Expected: PASS, 9 tests, 0 fail.

- [ ] **Step 5: Documentar el formato**

Crear `D:/github/skills/ui-ux-scout/references/refero-format.md`:

````markdown
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
````

- [ ] **Step 6: Corregir el contrato del spec con los datos reales**

En `D:/github/skills/docs/superpowers/specs/2026-10-14-ui-ux-scout-skill-design.md`:

1. Reemplazar desde la línea que empieza con `- Descarga \`https://styles.refero.design/style/<uuid>\` y parsea el payload de` hasta la línea `  \`references/refero-format.md\` al implementar, a partir de una página real.` (todo el resto de la sección «Contrato del script», después de `- Entrada: …`) por:

````markdown
- Descarga `https://styles.refero.design/style/<uuid>` y parsea el payload de
  Next.js (`self.__next_f.push(...)`). La página **no trae un DESIGN.md como
  texto**: lo arma a partir de un objeto estructurado, que es lo que se
  extrae (ver `references/refero-format.md`).
- Salida (stdout, JSON):

  ```json
  {
    "source": "https://styles.refero.design/style/<uuid>",
    "uuid": "<uuid>",
    "name": "Raycast",
    "theme": "dark",
    "description": "", "northStar": "", "layout": "", "elevationPhilosophy": "",
    "colors": [{ "name": "", "hex": "", "role": "", "group": "" }],
    "surfaces": [{ "name": "", "hex": "", "level": 0, "purpose": "" }],
    "typography": [{ "family": "", "role": "", "weight": "", "sizes": "", "lineHeight": "", "letterSpacing": "", "substitute": "", "fontFeatureSettings": "" }],
    "typeScale": [{ "role": "", "size": 16, "lineHeight": 1.5, "letterSpacing": 0 }],
    "spacing": { "radius": { "buttons": "8px" }, "cardPadding": "24px" },
    "elevation": [{ "element": "", "style": "" }],
    "components": [{ "name": "", "role": "", "description": "" }],
    "dos": [],
    "donts": []
  }
  ```

  Los campos ausentes van como `[]` o `null`, nunca se inventan.
- Códigos de salida: `0` OK; `1` entrada inválida; `2` estilo no encontrado;
  `3` payload no reconocible (formato cambiado); `4` error de red.
  Mensaje en stderr.
- **Un UUID inexistente responde HTTP 200** (verificado el 2026-10-14): el
  «no encontrado» se detecta por la marca `NEXT_HTTP_ERROR_FALLBACK;404` o el
  título `Style not found`, no por el código HTTP.
````

2. En el paso 2 del flujo, cambiar `(principios, tokens,\n     escala de alturas, inventario §19, kit reutilizable §20)` por `(principios, tokens,\n     escala de alturas, kit reutilizable §20)`.
3. En el paso 6, sub-paso 3, cambiar `Documentarlo en \`docs/design-system.md\`: su sección y una fila en el\n      inventario §19.` por `Documentarlo en \`docs/design-system.md\` §20 «Kit reutilizable»: en la\n      fila de su grupo y en un párrafo de lote.`
4. En **Pruebas**, cambiar `\`docs/design-system.md\` (§19)` por `\`docs/design-system.md\` (§20)`.

Verificar: `git -C D:/github/skills grep -n "§19" -- docs/superpowers/specs/2026-10-14-ui-ux-scout-skill-design.md`
Expected: sin resultados.

- [ ] **Step 7: Commit**

```bash
git -C D:/github/skills add ui-ux-scout/scripts/refero-fetch.mjs ui-ux-scout/scripts/test-refero-fetch.mjs ui-ux-scout/references/refero-format.md docs/superpowers/specs/2026-10-14-ui-ux-scout-skill-design.md
git -C D:/github/skills commit -m "feat(ui-ux-scout): parser del payload de Refero Styles" -m "Extrae el objeto del estilo del payload de Next.js y lo normaliza; detecta el UUID inexistente aunque la respuesta sea 200. Ajusta el contrato del spec a la página real." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_015P5t8kWo8bqwEgcFfnbcpB"
```

(Ejecutar `add` y `commit` como dos invocaciones separadas.)

---

### Task 2: Descarga, caché y CLI

**Files:**
- Modify: `D:/github/skills/ui-ux-scout/scripts/refero-fetch.mjs` (imports al inicio; funciones nuevas al final)
- Modify: `D:/github/skills/ui-ux-scout/scripts/test-refero-fetch.mjs` (import y tests nuevos)

**Interfaces:**
- Consumes (Task 1): `BASE`, `SALIDA`, `ErrorRefero`, `extraerUuid`, `parsearPagina`.
- Produces:
  - `CACHE_TTL_MS: number` = 7 días en ms
  - `CACHE_DIR: string` = `join(os.tmpdir(), "ui-ux-scout")`
  - `obtenerEstilo(entrada, { fetchImpl?, cacheDir?, ahora? }): Promise<{ estilo: Estilo, aviso: string | null }>`
  - `main(args: string[], { stdout?, stderr?, fetchImpl?, cacheDir?, ahora? }): Promise<number>`: devuelve el código de salida
  - CLI: `node refero-fetch.mjs <uuid|url>` → JSON por stdout, código de `SALIDA`

- [ ] **Step 1: Escribir los tests que fallan**

En `test-refero-fetch.mjs`, reemplazar el bloque de import de `./refero-fetch.mjs` por:

```js
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import {
  BASE,
  SALIDA,
  CACHE_TTL_MS,
  ErrorRefero,
  extraerUuid,
  extraerNombre,
  parsearPagina,
  obtenerEstilo,
  main,
} from "./refero-fetch.mjs";
```

Y agregar al final del archivo:

```js
// fetch falso: devuelve las respuestas en orden; un Error simula falta de red.
function fetchFalso(...respuestas) {
  const llamadas = [];
  const impl = async (url) => {
    llamadas.push(url);
    const r = respuestas.shift();
    if (r instanceof Error) throw r;
    const status = r.status ?? 200;
    return { status, ok: status >= 200 && status < 300, text: async () => r.html ?? "" };
  };
  return { impl, llamadas };
}

const dirTemporal = () => mkdtemp(join(tmpdir(), "ui-ux-scout-test-"));

async function codigoAsync(promesa) {
  try {
    await promesa;
  } catch (error) {
    assert.ok(error instanceof ErrorRefero, `se esperaba ErrorRefero, llegó ${error}`);
    return error.codigo;
  }
  assert.fail("se esperaba un ErrorRefero");
}

test("obtenerEstilo descarga, guarda en caché y la reutiliza sin volver a pedir", async () => {
  const cacheDir = await dirTemporal();
  const red = fetchFalso({ html: paginaConEstilo(ESTILO) });
  const primera = await obtenerEstilo(UUID, { fetchImpl: red.impl, cacheDir, ahora: 1_000 });
  assert.equal(primera.estilo.colors[0].hex, "#101010");
  assert.equal(primera.aviso, null);
  assert.deepEqual(red.llamadas, [`${BASE}${UUID}`]);

  const segunda = await obtenerEstilo(UUID.toUpperCase(), { fetchImpl: red.impl, cacheDir, ahora: 2_000 });
  assert.deepEqual(segunda.estilo, primera.estilo);
  assert.equal(red.llamadas.length, 1, "la segunda llamada debe salir de la caché");
});

test("obtenerEstilo renueva la caché vencida", async () => {
  const cacheDir = await dirTemporal();
  const red = fetchFalso({ html: paginaConEstilo(ESTILO) }, { html: paginaConEstilo({ ...ESTILO, theme: "light" }) });
  await obtenerEstilo(UUID, { fetchImpl: red.impl, cacheDir, ahora: 0 });
  const renovada = await obtenerEstilo(UUID, { fetchImpl: red.impl, cacheDir, ahora: CACHE_TTL_MS + 1 });
  assert.equal(renovada.estilo.theme, "light");
  assert.equal(red.llamadas.length, 2);
});

test("obtenerEstilo usa la caché vencida con aviso si no hay red", async () => {
  const cacheDir = await dirTemporal();
  await obtenerEstilo(UUID, { fetchImpl: fetchFalso({ html: paginaConEstilo(ESTILO) }).impl, cacheDir, ahora: 0 });
  const sinRed = fetchFalso(new Error("getaddrinfo ENOTFOUND"));
  const { estilo, aviso } = await obtenerEstilo(UUID, { fetchImpl: sinRed.impl, cacheDir, ahora: CACHE_TTL_MS + 1 });
  assert.equal(estilo.theme, "dark");
  assert.match(aviso, /caché del 1970-01-01/);
});

test("obtenerEstilo sin red y sin caché sale con código de red", async () => {
  const cacheDir = await dirTemporal();
  const sinRed = fetchFalso(new Error("getaddrinfo ENOTFOUND"));
  assert.equal(await codigoAsync(obtenerEstilo(UUID, { fetchImpl: sinRed.impl, cacheDir })), SALIDA.RED);
});

test("obtenerEstilo distingue no encontrado (404 o página de 404 con 200) de error HTTP", async () => {
  const cacheDir = await dirTemporal();
  assert.equal(await codigoAsync(obtenerEstilo(UUID, { fetchImpl: fetchFalso({ status: 404 }).impl, cacheDir })), SALIDA.NO_ENCONTRADO);
  assert.equal(await codigoAsync(obtenerEstilo(UUID, { fetchImpl: fetchFalso({ html: PAGINA_NO_ENCONTRADA }).impl, cacheDir })), SALIDA.NO_ENCONTRADO);
  assert.equal(await codigoAsync(obtenerEstilo(UUID, { fetchImpl: fetchFalso({ status: 503 }).impl, cacheDir })), SALIDA.RED);
});

test("obtenerEstilo ignora una caché corrupta y vuelve a descargar", async () => {
  const cacheDir = await dirTemporal();
  await writeFile(join(cacheDir, `${UUID}.json`), "{no es json");
  const red = fetchFalso({ html: paginaConEstilo(ESTILO) });
  const { estilo } = await obtenerEstilo(UUID, { fetchImpl: red.impl, cacheDir, ahora: 0 });
  assert.equal(estilo.name, "Acme");
  assert.equal(red.llamadas.length, 1);
  const guardada = JSON.parse(await readFile(join(cacheDir, `${UUID}.json`), "utf8"));
  assert.equal(guardada.guardado, 0);
});

test("obtenerEstilo devuelve el estilo aunque no pueda escribir la caché", async () => {
  const base = await dirTemporal();
  const archivo = join(base, "no-es-directorio");
  await writeFile(archivo, "x");
  const { estilo } = await obtenerEstilo(UUID, { fetchImpl: fetchFalso({ html: paginaConEstilo(ESTILO) }).impl, cacheDir: archivo, ahora: 0 });
  assert.equal(estilo.theme, "dark");
});

function salidaFalsa() {
  let texto = "";
  return { write: (s) => { texto += s; }, get texto() { return texto; } };
}

test("main imprime el JSON del estilo y devuelve 0", async () => {
  const stdout = salidaFalsa();
  const stderr = salidaFalsa();
  const codigo = await main([UUID], { stdout, stderr, fetchImpl: fetchFalso({ html: paginaConEstilo(ESTILO) }).impl, cacheDir: await dirTemporal() });
  assert.equal(codigo, SALIDA.OK);
  assert.equal(JSON.parse(stdout.texto).name, "Acme");
  assert.equal(stderr.texto, "");
});

test("main sin argumentos o con un nombre devuelve 1 con un mensaje", async () => {
  const stderr = salidaFalsa();
  assert.equal(await main([], { stdout: salidaFalsa(), stderr }), SALIDA.ENTRADA_INVALIDA);
  assert.match(stderr.texto, /^Uso: /);
  const stderr2 = salidaFalsa();
  assert.equal(await main(["Raycast"], { stdout: salidaFalsa(), stderr: stderr2 }), SALIDA.ENTRADA_INVALIDA);
  assert.match(stderr2.texto, /no es un UUID/);
});

test("el CLI sale con código 1 ante una entrada inválida, sin tocar la red", () => {
  const script = join(dirname(fileURLToPath(import.meta.url)), "refero-fetch.mjs");
  const r = spawnSync(process.execPath, [script, "no-es-uuid"], { encoding: "utf8" });
  assert.equal(r.status, SALIDA.ENTRADA_INVALIDA);
  assert.match(r.stderr, /no es un UUID/);
  assert.equal(r.stdout, "");
});
```

- [ ] **Step 2: Ejecutar los tests y comprobar que fallan**

Run: `node --test D:/github/skills/ui-ux-scout/scripts/test-refero-fetch.mjs`
Expected: FAIL, `does not provide an export named 'CACHE_TTL_MS'`.

- [ ] **Step 3: Implementar descarga, caché y CLI**

En `refero-fetch.mjs`, agregar estas líneas inmediatamente después del comentario de cabecera (antes de `export const BASE`):

```js
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
```

Y agregar al final del archivo:

```js
export const CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000;
export const CACHE_DIR = join(tmpdir(), "ui-ux-scout");
const AGENTE = "ui-ux-scout (+https://github.com/bacsystem/skills)";

async function leerCache(ruta) {
  try {
    const cache = JSON.parse(await readFile(ruta, "utf8"));
    return typeof cache?.guardado === "number" && cache.estilo ? cache : null;
  } catch {
    return null; // ausente o corrupta: se trata igual
  }
}

// La caché es una optimización: si no se puede escribir, el resultado se entrega igual.
async function guardarCache(cacheDir, ruta, contenido) {
  try {
    await mkdir(cacheDir, { recursive: true });
    await writeFile(ruta, JSON.stringify(contenido));
  } catch {
    // sin caché esta vez
  }
}

export async function obtenerEstilo(entrada, { fetchImpl = globalThis.fetch, cacheDir = CACHE_DIR, ahora = Date.now() } = {}) {
  const uuid = extraerUuid(entrada);
  const rutaCache = join(cacheDir, `${uuid}.json`);
  const cache = await leerCache(rutaCache);
  if (cache && ahora - cache.guardado < CACHE_TTL_MS) return { estilo: cache.estilo, aviso: null };

  const falloDeRed = (detalle) => {
    if (cache) {
      const fecha = new Date(cache.guardado).toISOString().slice(0, 10);
      return { estilo: cache.estilo, aviso: `${detalle}; se usa la copia en caché del ${fecha}.` };
    }
    throw new ErrorRefero(SALIDA.RED, `${detalle}.`);
  };

  let respuesta;
  try {
    respuesta = await fetchImpl(BASE + uuid, { headers: { "user-agent": AGENTE } });
  } catch (error) {
    return falloDeRed(`No se pudo conectar con Refero Styles (${error.message})`);
  }
  if (respuesta.status === 404) {
    throw new ErrorRefero(SALIDA.NO_ENCONTRADO, `No existe un estilo con UUID ${uuid} en Refero Styles.`);
  }
  if (!respuesta.ok) return falloDeRed(`Refero Styles respondió HTTP ${respuesta.status}`);

  const estilo = parsearPagina(await respuesta.text(), uuid);
  await guardarCache(cacheDir, rutaCache, { guardado: ahora, estilo });
  return { estilo, aviso: null };
}

const USO = "Uso: node refero-fetch.mjs <uuid|https://styles.refero.design/style/<uuid>>";

export async function main(args, { stdout = process.stdout, stderr = process.stderr, ...opciones } = {}) {
  if (args.length !== 1) {
    stderr.write(`${USO}\n`);
    return SALIDA.ENTRADA_INVALIDA;
  }
  if (typeof (opciones.fetchImpl ?? globalThis.fetch) !== "function") {
    stderr.write("Hace falta Node 18 o superior (fetch nativo).\n");
    return SALIDA.RED;
  }
  try {
    const { estilo, aviso } = await obtenerEstilo(args[0], opciones);
    if (aviso) stderr.write(`${aviso}\n`);
    stdout.write(`${JSON.stringify(estilo, null, 2)}\n`);
    return SALIDA.OK;
  } catch (error) {
    if (!(error instanceof ErrorRefero)) throw error;
    stderr.write(`${error.message}\n`);
    return error.codigo;
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  process.exitCode = await main(process.argv.slice(2));
}
```

- [ ] **Step 4: Ejecutar los tests y comprobar que pasan**

Run: `node --test D:/github/skills/ui-ux-scout/scripts/test-refero-fetch.mjs`
Expected: PASS, 19 tests, 0 fail.

- [ ] **Step 5: Prueba de humo contra la página real (con red)**

Run: `node D:/github/skills/ui-ux-scout/scripts/refero-fetch.mjs 3b6a17f0-3bdf-418c-a95e-0b89e5a8b2f8`
Expected: código 0; JSON con `"name": "Raycast"`, `"theme": "dark"`, 17 `colors`, el primero `{"name": "Void Black", "hex": "#040506", …}`. No se guarda la salida en el repo.

Run: `node D:/github/skills/ui-ux-scout/scripts/refero-fetch.mjs 00000000-0000-0000-0000-000000000000`
Expected: código 2, stderr `No existe un estilo con UUID 00000000-0000-0000-0000-000000000000 en Refero Styles.`

- [ ] **Step 6: Commit**

```bash
git -C D:/github/skills add ui-ux-scout/scripts/refero-fetch.mjs ui-ux-scout/scripts/test-refero-fetch.mjs
git -C D:/github/skills commit -m "feat(ui-ux-scout): descarga, caché y CLI de refero-fetch" -m "Caché de 7 días en el temporal del sistema, copia vencida con aviso si no hay red, y códigos de salida 0-4." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_015P5t8kWo8bqwEgcFfnbcpB"
```

(Ejecutar `add` y `commit` como dos invocaciones separadas.)

---

### Task 3: Referencias de criterio: UI/UX, React/Next, DRY y SOLID

**Files:**
- Create: `D:/github/skills/ui-ux-scout/references/ui-ux-principles.md`
- Create: `D:/github/skills/ui-ux-scout/references/react-nextjs.md`
- Create: `D:/github/skills/ui-ux-scout/references/clean-design.md`

**Interfaces:**
- Consumes: nada.
- Produces: tres archivos que `SKILL.md` (Task 5) cita por nombre. `ui-ux-principles.md` define el snippet de contraste que el plan usa en «Tokens».

- [ ] **Step 1: Crear `ui-ux-principles.md`**

````markdown
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

Compute contrast; never estimate it. Run with Node (works for `#rgb` and
`#rrggbb`):

```bash
node -e "const L=h=>{h=h.replace('#','');if(h.length===3)h=[...h].map(c=>c+c).join('');const [r,g,b]=[0,2,4].map(i=>{const c=parseInt(h.slice(i,i+2),16)/255;return c<=0.04045?c/12.92:((c+0.055)/1.055)**2.4});return 0.2126*r+0.7152*g+0.0722*b};const [a,b]=process.argv.slice(1).map(L).sort((x,y)=>y-x);console.log(((a+0.05)/(b+0.05)).toFixed(2))" "#6a6b6c" "#040506"
```

khipu tokens live in `globals.css` as `oklch(...)` or hex. For `oklch`, convert
first (for example with the browser devtools color picker or a known
conversion), and say in the plan which value you converted.

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
````

- [ ] **Step 2: Crear `react-nextjs.md`**

````markdown
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
````

- [ ] **Step 3: Crear `clean-design.md`**

````markdown
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
````

- [ ] **Step 4: Verificar que los archivos existen y no tienen marcadores pendientes**

Run: `git -C D:/github/skills grep -n -i -E "TODO|TBD|FIXME" -- ui-ux-scout/references`
Expected: sin resultados (código de salida 1).

- [ ] **Step 5: Commit**

```bash
git -C D:/github/skills add ui-ux-scout/references/ui-ux-principles.md ui-ux-scout/references/react-nextjs.md ui-ux-scout/references/clean-design.md
git -C D:/github/skills commit -m "docs(ui-ux-scout): referencias de UI/UX, React/Next, DRY y SOLID" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_015P5t8kWo8bqwEgcFfnbcpB"
```

(Ejecutar `add` y `commit` como dos invocaciones separadas.)

---

### Task 4: Referencias de ejecución: validación, checklist de khipu y plantilla del plan

**Files:**
- Create: `D:/github/skills/ui-ux-scout/references/field-validation.md`
- Create: `D:/github/skills/ui-ux-scout/references/khipu-checklist.md`
- Create: `D:/github/skills/ui-ux-scout/references/plan-template.md`

**Interfaces:**
- Consumes: nada.
- Produces: tres archivos que `SKILL.md` (Task 5) cita por nombre. `plan-template.md` fija los encabezados del plan (`--es` y `--en`) que `SKILL.md` exige.

- [ ] **Step 1: Crear `field-validation.md`**

````markdown
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
````

- [ ] **Step 2: Crear `khipu-checklist.md`**

````markdown
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
2. **Docs:** in `docs/design-system.md` §20 «Kit reutilizable», add it to its
   group's row and write a short lote paragraph like the existing ones
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
````

- [ ] **Step 3: Crear `plan-template.md`**

````markdown
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
- Validación: — | tipo de dato + reglas + mensaje
- Estados: …
```

**Componentes a ajustar**: ID `A1`, `A2`…: file, what changes and why, and
"API: sin cambios" or the optional prop added.

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

**Para aprobar**: one line asking for approval by ID, for example:
«Responde "sí" para aplicar todo, o indica qué IDs quitar o cambiar (p. ej.
"sin T2, N3 con otro nombre").»
````

- [ ] **Step 4: Verificar que los archivos no tienen marcadores pendientes**

Run: `git -C D:/github/skills grep -n -i -E "TODO|TBD|FIXME" -- ui-ux-scout/references`
Expected: sin resultados (código de salida 1).

- [ ] **Step 5: Commit**

```bash
git -C D:/github/skills add ui-ux-scout/references/field-validation.md ui-ux-scout/references/khipu-checklist.md ui-ux-scout/references/plan-template.md
git -C D:/github/skills commit -m "docs(ui-ux-scout): validación por tipo de dato, checklist de khipu y plantilla del plan" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_015P5t8kWo8bqwEgcFfnbcpB"
```

(Ejecutar `add` y `commit` como dos invocaciones separadas.)

---

### Task 5: `SKILL.md`

**Files:**
- Create: `D:/github/skills/ui-ux-scout/SKILL.md`

**Interfaces:**
- Consumes: `scripts/refero-fetch.mjs` (CLI y códigos de Task 1-2); los seis archivos de `references/` (Tasks 1, 3, 4), citados por nombre exacto.
- Produces: la skill invocable como `/ui-ux-scout`.

- [ ] **Step 1: Crear `SKILL.md`**

````markdown
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
| `references/ui-ux-principles.md` | Taking the system and not the brand; contrast (with the command to compute it); density; states; focus; dark mode |
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

Read `CLAUDE.md`, `README.md`, `docs/design-system.md` (principles, tokens,
§4 height scale, §20 reusable kit), `src/app/globals.css` (`@theme inline`,
`:root`, `.dark`), `src/lib/estilos.ts` and `registry/registry.json`.

khipu's conventions are hard constraints: color only by token; one control
height `h-9`; mono with `tabular-nums` for data; at most 5 chart series;
the «próximamente» pattern; Spanish names; routes, texts, icons and handlers
by props.

### 3. Extract the style

1. Check Node: `node --version` must be ≥ 18. If not, go to plan B.
2. Run the script that ships next to this file:
   `node <this skill's directory>/scripts/refero-fetch.mjs <uuid-or-url>`
3. Act on the exit code:

| Code | Meaning | Do |
|---|---|---|
| `0` | OK; JSON on stdout (a stderr line may say it came from an old cache) | Continue. Mention the cache warning in the plan. |
| `1` | Invalid input | Explain the expected format and stop. |
| `2` | Style not found | Say so with the UUID received and stop. |
| `3` | Page format changed | Plan B. |
| `4` | Network error, no cache | Plan B; if WebFetch also fails, stop. |

**Plan B** is in `references/refero-format.md`. Values from WebFetch carry
the precision warning in the plan, always.

### 4. Write the plan

Use `references/plan-template.md`. Ground it in the references:
- what to take from the style: `ui-ux-principles.md` («Take the system, not
  the brand»);
- for each new component, why it is not an extension of an existing one, and
  what it reuses: `clean-design.md`;
- Server or Client, props and variants: `react-nextjs.md`;
- for each form field, its data type, rules and messages:
  `field-validation.md`;
- for each token change, the contrast ratio **computed** with the command in
  `ui-ux-principles.md`, in light and dark;
- every clash with a khipu convention goes to «Conflictos con convenciones»,
  resolved in khipu's favor.

Show the plan and **stop**.

### 5. Wait for approval

Apply nothing without an explicit "sí" / "yes". The user may drop or change
items by ID (`N1`, `A2`, `T3`, `C1`). Token items are approved one by one,
because a token change reaches every khipu consumer. If the user changes the
plan, show the updated plan and wait again.

### 6. Apply

1. Create the branch from an up-to-date `main`, one command per call:
   `git fetch origin`, then
   `git switch -c feat/estilo-<style-name-kebab> origin/main`.
2. Follow `references/khipu-checklist.md` sections B, D and E for each
   approved item.
3. Keep every item of the checklist's quality list (section C) true.
4. Run `npm run registry:build` after all changes.

### 7. Verify

Run, one per call: `npm run typecheck`, `npm run lint`, `npm run build`.
If one fails, fix and run it again. If it cannot be fixed, report the exact
error and **do not** say the work is done.

Then run `npm run dev` and review `/ejemplo` in light and dark.

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
| Estimating contrast by eye | Run the command in `ui-ux-principles.md` |
| Adding `"use client"` to every new file | Server by default; justify each client one |
| Writing validation inside the component | Pure function in `lib/validacion.ts`, shown with `Campo` |
| Forgetting gallery, docs, guide, README or registry | Checklist section D, every item |
| Reporting success with a failing build | Quote the error; the work is not done |
````

- [ ] **Step 2: Verificar el frontmatter y las referencias citadas**

Run: `git -C D:/github/skills grep -n -o -E "references/[a-z-]+\.md" -- ui-ux-scout/SKILL.md`
Expected: solo estos siete nombres (con repeticiones): `refero-format.md`, `ui-ux-principles.md`, `react-nextjs.md`, `clean-design.md`, `field-validation.md`, `khipu-checklist.md`, `plan-template.md`. Cada uno debe existir:

Run: `ls D:/github/skills/ui-ux-scout/references`
Expected: los siete archivos anteriores.

- [ ] **Step 3: Commit**

```bash
git -C D:/github/skills add ui-ux-scout/SKILL.md
git -C D:/github/skills commit -m "feat(ui-ux-scout): definición de la skill" -m "Flujo de siete pasos: comprobar khipu, leer contexto, extraer, plan, aprobación, aplicar y verificar. Nunca commitea." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_015P5t8kWo8bqwEgcFfnbcpB"
```

(Ejecutar `add` y `commit` como dos invocaciones separadas.)

---

### Task 6: README de la skill, README raíz y CHANGELOG

**Files:**
- Create: `D:/github/skills/ui-ux-scout/README.md`
- Modify: `D:/github/skills/README.md` (tabla **Skills**, después de la fila de `pr-review`)
- Modify: `D:/github/skills/CHANGELOG.md` (bajo `## [Sin publicar]`)

**Interfaces:**
- Consumes: la invocación y los archivos de Tasks 1-5.
- Produces: documentación pública de la skill.

- [ ] **Step 1: Crear `ui-ux-scout/README.md`**

````markdown
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
5. Waits for your approval; tokens are approved one by one.
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
````

- [ ] **Step 2: Agregar la fila en el README raíz**

En `D:/github/skills/README.md`, inmediatamente después de la línea que empieza con `` | [`pr-review`](./pr-review) | ``, agregar:

```markdown
| [`ui-ux-scout`](./ui-ux-scout) | Crea y mejora componentes de khipu-design-system a partir de un estilo de Refero Styles (UUID): plan con tokens y contraste WCAG, aprobación, implementación con criterio de UI/UX, React/Next, DRY, SOLID y validación por tipo de dato, y verificación del build |
```

- [ ] **Step 3: Agregar la entrada al CHANGELOG**

En `D:/github/skills/CHANGELOG.md`, reemplazar la línea `## [Sin publicar]` por:

```markdown
## [Sin publicar]

### Añadido
- Skill `ui-ux-scout`: crea y mejora componentes en khipu-design-system a
  partir de un estilo de Refero Styles indicado por UUID. Muestra un plan
  (componentes nuevos, ajustes, tokens con contraste WCAG calculado y
  conflictos con las convenciones de khipu), espera la aprobación, lo aplica
  en una rama y verifica `typecheck`, `lint` y `build`. Nunca commitea.
- `ui-ux-scout/scripts/refero-fetch.mjs`: extrae los valores exactos del
  estilo del payload de Next.js de la página, con caché de 7 días y códigos de
  salida `0`–`4`; tests sin red con fixtures sintéticos.
- `ui-ux-scout/references/`: principios de UI/UX, React 19 y Next.js 15, DRY
  y SOLID para componentes, validación por tipo de dato (incluido RUC con
  dígito verificador), checklist de alta en khipu, plantilla del plan y
  formato de la página de Refero.
```

- [ ] **Step 4: Verificar**

Run: `git -C D:/github/skills diff --stat`
Expected: `README.md`, `CHANGELOG.md` modificados; `ui-ux-scout/README.md` sin seguimiento (aparece con `git -C D:/github/skills status --short`).

- [ ] **Step 5: Commit**

```bash
git -C D:/github/skills add ui-ux-scout/README.md README.md CHANGELOG.md
git -C D:/github/skills commit -m "docs(ui-ux-scout): README, tabla de skills y CHANGELOG" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_015P5t8kWo8bqwEgcFfnbcpB"
```

(Ejecutar `add` y `commit` como dos invocaciones separadas.)

---

### Task 7: Verificación de punta a punta

Comprueba que la skill completa funciona en khipu. No crea archivos en el repo `skills`. Los cambios que haga en khipu durante la prueba se revisan con el usuario antes de conservarlos.

**Files:**
- Ninguno en `skills`. En khipu: lo que el plan aprobado indique (en una rama `feat/estilo-raycast`).

**Interfaces:**
- Consumes: la skill completa (Tasks 1-6).
- Produces: evidencia de que cumple los criterios de «Pruebas» del spec.

- [ ] **Step 1: Tests del script**

Run: `node --test D:/github/skills/ui-ux-scout/scripts/test-refero-fetch.mjs`
Expected: PASS, 19 tests, 0 fail.

- [ ] **Step 2: Instalar la skill**

Preguntar al usuario antes de crear el enlace en su directorio personal. Con su visto bueno, en Git Bash:

Run: `ln -snf "D:/github/skills/ui-ux-scout" ~/.claude/skills/ui-ux-scout`
Expected: `ls ~/.claude/skills/ui-ux-scout/SKILL.md` existe.

(En Windows, `ln -s` sin modo desarrollador puede copiar en vez de enlazar. Si copia, decírselo al usuario: las ediciones del repo no se verán hasta volver a copiar.)

- [ ] **Step 3: Ejecutar la skill en khipu hasta el plan**

En una sesión nueva de Claude Code con directorio `D:/github/khipu-design-system` y árbol limpio:
`/ui-ux-scout 3b6a17f0-3bdf-418c-a95e-0b89e5a8b2f8`

Expected:
- comprueba `package.json` y `git status`;
- el plan usa los encabezados de `plan-template.md`;
- los hex del plan coinciden con la salida del script (p. ej. `#040506` para Void Black);
- cada token trae su contraste calculado;
- cada componente nuevo justifica por qué no extiende uno existente;
- `h-9` aparece como conflicto si el estilo pide otra altura;
- **no se modificó ningún archivo** (`git -C D:/github/khipu-design-system status --short` vacío).

- [ ] **Step 4: Aprobar un subconjunto y aplicar**

Aprobar al menos un componente nuevo y ningún token (para no cambiar la identidad de khipu en la prueba). Expected, al terminar la skill:
- rama `feat/estilo-raycast` en khipu;
- el componente nuevo existe, aparece en `src/app/ejemplo/galeria.tsx`, en `docs/design-system.md` §20, en `docs/guia-visual.html`, en el bloque «Estructura» del `README.md` y en `registry/registry.json`;
- `npm run typecheck`, `npm run lint` y `npm run build` pasan (la skill los cita);
- `git -C D:/github/khipu-design-system diff --stat` no muestra componentes, exports, props ni tokens borrados o renombrados;
- el resumen recorre la lista de calidad punto por punto;
- no hay commits nuevos en khipu (`git -C D:/github/khipu-design-system log origin/main..HEAD` vacío).

- [ ] **Step 5: Distribución con la CLI**

Run: `node D:/github/khipu-design-system/cli/khipu.mjs list`
Expected: el componente nuevo aparece en la lista.

(La prueba de `add` sobre un proyecto de prueba requiere un proyecto Next.js aparte; si no existe uno, informarlo al usuario y no darlo por verificado.)

- [ ] **Step 6: Informar**

Reportar al usuario cada criterio con su evidencia (comandos y salidas). Los cambios en khipu quedan sin commitear: el usuario decide si los conserva (con `git-flow`) o los descarta.
