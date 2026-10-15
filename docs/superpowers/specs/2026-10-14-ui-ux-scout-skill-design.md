# Diseño: skill `ui-ux-scout`

**Fecha:** 2026-10-14
**Estado:** Aprobado (diseño conversacional); spec pendiente de revisión

## Propósito

Auditar el design system del proyecto donde se invoca contra sistemas de
referencia publicados en [Refero Styles](https://styles.refero.design/), y
entregar una lista priorizada de mejoras concretas.

La skill **audita y propone**. Nunca edita código, commitea ni aplica cambios:
aplicar las propuestas es una tarea aparte que requiere el visto bueno explícito
del usuario (mismo criterio que `pr-review`).

Es genérica: sirve para cualquier proyecto con tokens y componentes. El primer
caso de uso es `bacsystem/khipu-design-system`.

## Estructura en el repo

```
ui-ux-scout/
├── SKILL.md                    flujo + invocación
├── README.md
├── scripts/
│   ├── refero-fetch.mjs        descarga y parsea un estilo → JSON normalizado
│   └── test-refero-fetch.mjs   tests con fixture sintético
└── references/
    ├── audit-rubric.md         ejes de auditoría y umbrales
    ├── report-template.md      formato del informe (es/en)
    └── refero-format.md        estructura del payload de Refero + plan B
```

Además: fila en la tabla **Skills** del `README.md` raíz y entrada en
`CHANGELOG.md` (el workflow `auto-tag` crea el tag a partir de él).

## Invocación

```
/ui-ux-scout [<uuid|URL> ...] [--es|--en] [--focus <eje>] [--save]
```

| Argumento | Efecto |
|---|---|
| `<uuid>` | UUID del estilo en Refero (p. ej. `3b6a17f0-3bdf-418c-a95e-0b89e5a8b2f8`). También se acepta la URL `https://styles.refero.design/style/<uuid>`, de la que se toma el UUID. Hasta **3** por corrida; más se rechaza con un mensaje. **No hay búsqueda por nombre.** |
| *(sin argumento)* | No audita. Explica cómo obtener el UUID: elegir un estilo en <https://styles.refero.design/> y copiar su URL. |
| `--es` / `--en` | Idioma del informe. Por defecto `--es`. |
| `--focus <eje>` | Limita la auditoría: `tokens` (color, tipografía, espaciado y forma, modo oscuro), `componentes` (componentes, layout y densidad) o `a11y` (accesibilidad y contraste). Sin él, se auditan todos los ejes. |
| `--save` | Además de mostrarlo, guarda el informe en `docs/ui-ux-scout/<AAAA-MM-DD>-<estilo>.md` del proyecto auditado. |

Sin `--save` el informe queda solo en la terminal.

## Flujo (en orden)

1. **Perfil del proyecto**
   - Leer `CLAUDE.md`, `AGENTS.md` y la documentación de diseño que el
     repositorio señale (en khipu: `docs/design-system.md`, `README.md`).
   - Localizar los tokens: `globals.css` (bloques `@theme`, `:root`, `.dark`),
     `tailwind.config.*` o archivos de tema.
   - Inventariar los componentes (carpetas y nombres exportados).
   - Anotar las **convenciones declaradas** del proyecto (en khipu: color solo
     por token, una sola altura de control `h-9`, mono con `tabular-nums` para
     datos, máximo 5 series en gráficos). Son restricciones de la auditoría,
     no hallazgos.
   - Si no se encuentran tokens, detenerse y decir qué se buscó y dónde.

2. **Validar la referencia**
   - Extraer el UUID del argumento (UUID suelto o URL `/style/<uuid>`) y
     validar su formato (36 caracteres, hexadecimal con guiones). Un argumento
     que no sea UUID ni URL válida se rechaza explicando el formato esperado.

3. **Extraer**
   - Ejecutar `node scripts/refero-fetch.mjs <uuid>` (ruta relativa a la
     carpeta de la skill). Salida: JSON normalizado por stdout (ver
     **Contrato del script**).
   - Caché en el directorio temporal del sistema
     (`<tmp>/ui-ux-scout/<uuid>.json`), válida 7 días. Nunca dentro del repo
     auditado.
   - **Plan B:** si Node no está disponible, el script sale con código ≠ 0 o
     el JSON no trae `colors`, usar `WebFetch` sobre la página del estilo
     pidiendo las tablas literales, y marcar el informe con un aviso visible:
     *«Valores extraídos vía WebFetch: pueden no ser exactos; verifícalos antes
     de aplicarlos.»*

4. **Comparar** según `references/audit-rubric.md`, eje por eje:
   - **Color:** roles cubiertos (superficies, texto, borde, acento,
     semánticos), pasos de superficie/elevación, contraste WCAG 2.2 de los
     pares texto/fondo del proyecto (calculado, no estimado).
   - **Tipografía:** escala (número de pasos, ratio), pesos, interlineado,
     tracking, uso de mono y features OpenType.
   - **Espaciado y forma:** unidad base, escala, radios, sombras/elevación.
   - **Componentes:** los que la referencia tiene y el proyecto no, y los que
     ambos tienen pero difieren en estados o anatomía.
   - **Layout y densidad:** anchos, grid, densidad de tablas y formularios.
   - **Modo oscuro:** paridad de tokens claro/oscuro.
   - **Accesibilidad:** foco visible, tamaños de objetivo, contraste.

5. **Informe** según `references/report-template.md` (ver **Formato del
   informe**). Se muestra en la terminal; con `--save` también se escribe el
   archivo.

## Reglas

- **Nunca edita código.** Ni tokens, ni componentes, ni configuración. La
  única escritura permitida es el informe con `--save`.
- **Principios, no clonación.** Se extraen decisiones de sistema (pasos de
  elevación, escala tipográfica, densidad), no la identidad de marca de la
  referencia (su color de acento, su logo, su voz). Una propuesta que solo
  copia la marca de otro producto no es un hallazgo válido.
- **Las convenciones del proyecto mandan.** Toda propuesta debe ser
  compatible con ellas. Si una mejora las contradice, se reporta en la sección
  **Conflictos con convenciones**, nunca como recomendación directa.
- **Evidencia en cada hallazgo:** valor de la referencia frente al valor del
  proyecto, con la ruta y línea del archivo del proyecto.
- **Contenido de terceros:** solo se descarga lo que el usuario pide, bajo
  demanda, con un máximo de 3 estilos por corrida y una petición por segundo.
  No se commitean copias de los `DESIGN.md`. El informe cita la fuente (URL
  del estilo) y solo incluye los valores necesarios para justificar cada
  hallazgo.

## Formato del informe

Encabezados fijos por idioma (`--es` / `--en`):

1. **Resumen**: proyecto, referencias auditadas, método de extracción
   (script o WebFetch) y conteo de hallazgos por prioridad.
2. **Lo que tu sistema ya hace bien**: puntos concretos con evidencia.
3. **Hallazgos**, ordenados por prioridad (`Alta` / `Media` / `Baja`). Cada uno
   con:
   - ID estable `UX-<n>`
   - eje
   - evidencia (referencia frente a proyecto, `archivo:línea`)
   - propuesta concreta (qué token o componente cambiar y cómo)
   - archivos que tocaría
   - esfuerzo (`S` / `M` / `L`)
   - riesgo (qué podría romper)
4. **Conflictos con convenciones**: mejoras que chocan con reglas del
   proyecto, con el trade-off explicado.
5. **Veredicto**: una de `Sólido`, `Mejorable`, `Requiere trabajo`, con una
   frase que lo justifica.

## Contrato del script `refero-fetch.mjs`

- Node ≥ 18 (usa `fetch` nativo). Sin dependencias.
- Entrada: `node refero-fetch.mjs <uuid|url>`. Una entrada sin UUID válido
  sale con código `1`.
- Descarga `https://styles.refero.design/style/<uuid>` y parsea el payload de
  Next.js (`self.__next_f.push(...)`), que contiene el objeto del estilo
  con, entre otros, `theme` y `colors: [{hex, name, role, group}]`.
- Salida (stdout, JSON):

  ```json
  {
    "source": "https://styles.refero.design/style/<uuid>",
    "name": "Raycast",
    "theme": "dark",
    "colors": [{ "name": "", "hex": "", "role": "", "group": "" }],
    "typography": [{ "family": "", "role": "", "weights": [], "sizes": [], "lineHeight": "", "letterSpacing": "" }],
    "spacing": { "base": 8, "scale": [] },
    "radii": [{ "name": "", "value": "" }],
    "shadows": [{ "name": "", "value": "" }],
    "components": [{ "name": "", "description": "" }],
    "dos": [],
    "donts": [],
    "designMd": "<texto completo del DESIGN.md, si viene en el payload>"
  }
  ```

  Los campos ausentes en el payload van como `[]` o `null`, nunca se inventan.
- Códigos de salida: `0` OK; `1` entrada inválida; `2` estilo no encontrado (404); `3` payload no
  reconocible (formato cambiado); `4` error de red. Mensaje en stderr.
- Los nombres exactos de las claves del payload se documentan en
  `references/refero-format.md` al implementar, a partir de una página real.

## Por qué solo UUID

Decidido el 2026-10-14. `sitemaps/styles.xml` lista solo URLs `/style/<uuid>`,
sin nombres. Además, la búsqueda del sitio (`/?q=`) no devuelve enlaces a
estilos que se puedan parsear de forma fiable. Resolver nombres exigiría
descargar cientos de páginas o depender de detalles internos del sitio, así que
la skill trabaja solo con el UUID (o la URL que lo contiene).

## Errores

| Situación | Comportamiento |
|---|---|
| Argumento sin UUID válido | Rechazar y explicar cómo copiar la URL del estilo. |
| Estilo no encontrado (404) | Decirlo, mostrando el UUID recibido. |
| Payload no reconocible | Aviso de formato cambiado → plan B con WebFetch. |
| Sin red | Detenerse con mensaje claro; usar caché si existe y avisarlo. |
| Node ausente o < 18 | Plan B con WebFetch y aviso de precisión. |
| Proyecto sin tokens localizables | Detenerse indicando qué rutas se revisaron. |
| Más de 3 estilos | Rechazar y pedir que se elijan hasta 3. |

## Pruebas

- `test-refero-fetch.mjs` (`node --test`), sin red:
  - un **fixture sintético** que imita la estructura del payload, sin
    contenido real de Refero;
  - casos: parseo correcto, campos ausentes → `[]`/`null`, payload sin el
    objeto del estilo → código `3`, entrada URL frente a UUID, entrada
    inválida → código `1`.
- Prueba de punta a punta (manual): auditar `khipu-design-system` contra
  Raycast. Criterios:
  - los hex del informe coinciden con la página de Refero;
  - cada hallazgo trae `archivo:línea` real del proyecto;
  - ninguna propuesta viola las convenciones de khipu sin estar en
    **Conflictos**;
  - no se modificó ningún archivo del proyecto (`git status` limpio, salvo el
    informe con `--save`).

## Fuera de alcance

- Aplicar los cambios propuestos.
- Descargar o mirrorear la biblioteca de Refero.
- Integración con el MCP de Refero (posible versión futura).
- Auditar más de 3 referencias por corrida.
- Buscar estilos por nombre o sugerir referencias.
