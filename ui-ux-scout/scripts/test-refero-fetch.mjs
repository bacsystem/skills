// Tests de refero-fetch.mjs. Sin red: las páginas son sintéticas e imitan la estructura
// real (payload de Next.js en self.__next_f.push), sin contenido de Refero.
// Ejecutar: node --test ui-ux-scout/scripts/test-refero-fetch.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
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
