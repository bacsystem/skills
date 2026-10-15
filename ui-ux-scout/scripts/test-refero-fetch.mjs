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
