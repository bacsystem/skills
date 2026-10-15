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
