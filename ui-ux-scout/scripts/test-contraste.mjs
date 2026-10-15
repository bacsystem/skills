// Tests de contraste.mjs. Sin red ni dependencias.
// Ejecutar: node --test ui-ux-scout/scripts/test-contraste.mjs
import { test } from "node:test";
import assert from "node:assert/strict";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";
import { parsearColor, componer, luminancia, contraste } from "./contraste.mjs";

const SCRIPT = join(dirname(fileURLToPath(import.meta.url)), "contraste.mjs");

test("contraste de negro sobre blanco es 21", () => {
  assert.equal(contraste("#000", "#fff"), 21);
});

test("contraste de un par conocido da 3.82", () => {
  assert.equal(contraste("#6a6b6c", "#040506").toFixed(2), "3.82");
});

test("contraste es simétrico al intercambiar texto y fondo", () => {
  assert.equal(contraste("#6a6b6c", "#040506").toFixed(2), contraste("#040506", "#6a6b6c").toFixed(2));
});

test("un rgba transparente sobre la base equivale a la base: ratio 1", () => {
  assert.equal(contraste("rgba(0,0,0,0)", "#ffffff"), 1);
});

test("parsearColor acepta #rgb, #rgba, #rrggbb y #rrggbbaa", () => {
  assert.deepEqual(parsearColor("#fff"), [255, 255, 255, 1]);
  assert.deepEqual(parsearColor("#f008"), [255, 0, 0, 0x88 / 255]);
  assert.deepEqual(parsearColor("#6a6b6c"), [0x6a, 0x6b, 0x6c, 1]);
  assert.ok(Math.abs(parsearColor("#ffffff80")[3] - 0.502) < 0.001);
});

test("parsearColor acepta rgb(), rgba() y la sintaxis con espacios y barra", () => {
  assert.deepEqual(parsearColor("rgb(10, 20, 30)"), [10, 20, 30, 1]);
  assert.deepEqual(parsearColor("rgba(226,232,240,0.12)"), [226, 232, 240, 0.12]);
  assert.deepEqual(parsearColor("rgb(10 20 30 / 0.5)"), [10, 20, 30, 0.5]);
});

test("parsearColor rechaza hex mal formado y formatos no soportados, nombrando el valor", () => {
  assert.throws(() => parsearColor("#1b1c1"), /#1b1c1/);
  assert.throws(() => parsearColor("oklch(0.5 0.1 200)"), /oklch/);
  assert.throws(() => parsearColor("rojo"), /rojo/);
  assert.throws(() => parsearColor("rgba(300, 0, 0, 1)"), /300/);
});

test("componer mezcla el color con alfa sobre una superficie opaca", () => {
  assert.deepEqual(componer([0, 0, 0, 0.5], [255, 255, 255]), [127.5, 127.5, 127.5]);
  assert.deepEqual(componer([10, 20, 30, 1], [255, 255, 255]), [10, 20, 30]);
});

test("luminancia: blanco 1, negro 0", () => {
  assert.equal(luminancia([255, 255, 255]), 1);
  assert.equal(luminancia([0, 0, 0]), 0);
});

test("un token rgba de khipu oscuro se compone sobre la superficie dada", () => {
  const sobreOscuro = contraste("rgba(226,232,240,0.12)", "#111827", "#111827");
  const sobreBlanco = contraste("rgba(226,232,240,0.12)", "#111827");
  assert.ok(Number.isFinite(sobreOscuro) && sobreOscuro >= 1);
  assert.ok(Number.isFinite(sobreBlanco) && sobreBlanco >= 1);
});

test("el CLI imprime el ratio con 2 decimales y sale con 0", () => {
  const r = spawnSync(process.execPath, [SCRIPT, "#6a6b6c", "#040506"], { encoding: "utf8" });
  assert.equal(r.status, 0);
  assert.equal(r.stdout.trim(), "3.82");
});

test("el CLI sale con 1 y un mensaje en español ante un color inválido", () => {
  const r = spawnSync(process.execPath, [SCRIPT, "no-es-color", "#fff"], { encoding: "utf8" });
  assert.equal(r.status, 1);
  assert.match(r.stderr, /no-es-color/);
  assert.equal(r.stdout, "");
});

test("el CLI sin argumentos suficientes sale con 1 y muestra el uso", () => {
  const r = spawnSync(process.execPath, [SCRIPT, "#fff"], { encoding: "utf8" });
  assert.equal(r.status, 1);
  assert.match(r.stderr, /^Uso: /);
});
