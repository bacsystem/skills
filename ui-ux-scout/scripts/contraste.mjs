#!/usr/bin/env node
// Calcula el ratio de contraste WCAG entre dos colores.
// Acepta los formatos de los tokens de khipu: hex (#rgb, #rgba, #rrggbb, #rrggbbaa)
// y rgb()/rgba() con comas o con la sintaxis de espacios y barra: rgb(r g b / a).
// Un color con alfa se compone sobre la superficie que tiene debajo (`base`).
// Uso: node contraste.mjs <texto> <fondo> [base]

import { pathToFileURL } from "node:url";

const HEX_RE = /^#(?:[0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$/i;
const FUNCION_RE = /^rgba?\(\s*([^)]*?)\s*\)$/i;

function colorInvalido(entrada, motivo) {
  return new Error(`Color no soportado: "${entrada}"${motivo ? ` (${motivo})` : ""}. Usa #rgb, #rgba, #rrggbb, #rrggbbaa, rgb() o rgba().`);
}

function parsearHex(entrada, texto) {
  if (!HEX_RE.test(texto)) throw colorInvalido(entrada, "hex mal formado");
  let digitos = texto.slice(1);
  if (digitos.length <= 4) digitos = [...digitos].map((c) => c + c).join("");
  const [r, g, b, a] = [0, 2, 4, 6].map((i) => (i < digitos.length ? parseInt(digitos.slice(i, i + 2), 16) : null));
  return [r, g, b, a === null ? 1 : a / 255];
}

function parsearFuncion(entrada, cuerpo) {
  const partes = cuerpo.includes(",") ? cuerpo.split(",") : cuerpo.split(/\s*\/\s*|\s+/);
  const valores = partes.map((p) => p.trim());
  if (valores.length !== 3 && valores.length !== 4) throw colorInvalido(entrada, "se esperan 3 canales y un alfa opcional");
  const numeros = valores.map(Number);
  if (valores.some((v, i) => v === "" || !Number.isFinite(numeros[i]))) throw colorInvalido(entrada, "valor no numérico");
  const canales = numeros.slice(0, 3);
  const alfa = numeros.length === 4 ? numeros[3] : 1;
  const fueraDeRango = canales.find((c) => c < 0 || c > 255);
  if (fueraDeRango !== undefined) throw colorInvalido(entrada, `canal ${fueraDeRango} fuera de 0–255`);
  if (alfa < 0 || alfa > 1) throw colorInvalido(entrada, `alfa ${alfa} fuera de 0–1`);
  return [...canales, alfa];
}

// → [r, g, b, a] con r, g, b en 0–255 y a en 0–1.
export function parsearColor(entrada) {
  const texto = String(entrada ?? "").trim();
  if (texto.startsWith("#")) return parsearHex(entrada, texto);
  const funcion = texto.match(FUNCION_RE);
  if (funcion) return parsearFuncion(entrada, funcion[1]);
  throw colorInvalido(entrada, "formato desconocido");
}

// Compone `color` (con alfa) sobre la superficie opaca `sobre` → [r, g, b] opaco.
export function componer([r, g, b, a = 1], sobre) {
  return [r, g, b].map((canal, i) => canal * a + sobre[i] * (1 - a));
}

// Luminancia relativa WCAG de un color sRGB opaco.
export function luminancia(rgb) {
  const [r, g, b] = rgb.map((canal) => {
    const c = canal / 255;
    return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

// Ratio de contraste: el fondo se compone sobre `base`, y el texto sobre el fondo ya compuesto.
export function contraste(texto, fondo, base = "#ffffff") {
  const superficie = componer(parsearColor(base), [255, 255, 255]);
  const fondoOpaco = componer(parsearColor(fondo), superficie);
  const textoOpaco = componer(parsearColor(texto), fondoOpaco);
  const [claro, oscuro] = [luminancia(textoOpaco), luminancia(fondoOpaco)].sort((x, y) => y - x);
  return (claro + 0.05) / (oscuro + 0.05);
}

const USO = "Uso: node contraste.mjs <texto> <fondo> [base]";

export function main(args, { stdout = process.stdout, stderr = process.stderr } = {}) {
  if (args.length < 2 || args.length > 3) {
    stderr.write(`${USO}\n`);
    return 1;
  }
  try {
    stdout.write(`${contraste(...args).toFixed(2)}\n`);
    return 0;
  } catch (error) {
    stderr.write(`${error.message}\n`);
    return 1;
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  process.exitCode = main(process.argv.slice(2));
}
