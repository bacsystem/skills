# Diseño: skill `ui-ux-scout`

**Fecha:** 2026-10-14
**Estado:** Aprobado (diseño conversacional); spec pendiente de revisión

## Propósito

Tomar el `DESIGN.md` de un estilo publicado en
[Refero Styles](https://styles.refero.design/) y **crear componentes en
`khipu-design-system`** (y ajustar los existentes y los tokens cuando haga
falta), con criterio experto en:

- **UI/UX:** jerarquía, contraste, densidad, estados, accesibilidad.
- **React 19 / Next.js 15:** Server y Client Components, composición.
- **DRY y SOLID** aplicados a componentes.
- **Validación de campos según el tipo de dato.**

khipu es la fuente: los demás proyectos reciben los componentes con la CLI que
khipu ya tiene (`npx github:bacsystem/khipu-design-system add <componente>`).
La skill no actúa sobre otros proyectos.

## Alcance

**Incluye**

- Componentes nuevos que el `DESIGN.md` describe y khipu no tiene.
- Ajustes a componentes existentes (estados, radios, sombras, anatomía).
- Cambios de tokens en `src/app/globals.css`, aceptados uno por uno.
- Alta completa de cada componente nuevo en khipu: galería, documentación,
  guía visual y registro.

**Fuera de alcance (esta versión)**

- Actuar en proyectos que no sean khipu.
- Buscar estilos por nombre o sugerir referencias: la entrada es siempre un
  UUID (ver **Por qué solo UUID**).
- Commit, push y PR: se hacen después con la skill `git-flow`.
- Angular (ver **Fases futuras**).

## Estructura en el repo `bacsystem/skills`

```
ui-ux-scout/
├── SKILL.md
├── README.md
├── scripts/
│   ├── refero-fetch.mjs         UUID → JSON exacto del estilo
│   └── test-refero-fetch.mjs    tests con fixture sintético (node --test)
└── references/
    ├── ui-ux-principles.md      jerarquía, contraste WCAG 2.2, densidad, estados,
    │                            foco visible, tamaños de objetivo, modo oscuro
    ├── react-nextjs.md          React 19 y Next.js 15: Server/Client Components,
    │                            "use client" solo donde hace falta, props
    │                            serializables, composición, accesibilidad con base-ui
    ├── clean-design.md          DRY y SOLID aplicados a componentes React
    │                            (ver **DRY y SOLID**)
    ├── field-validation.md      reglas de validación por tipo de dato
    │                            (ver **Validación de campos**)
    ├── khipu-checklist.md       pasos para dar de alta o ajustar un componente
    ├── plan-template.md         formato del plan que el usuario aprueba
    └── refero-format.md         estructura del payload de Refero + plan B
```

Además: fila en la tabla **Skills** del `README.md` raíz y entrada en
`CHANGELOG.md`.

## Invocación

```
/ui-ux-scout <uuid|URL> [--es|--en]
```

| Argumento | Efecto |
|---|---|
| `<uuid>` | UUID del estilo en Refero (p. ej. `3b6a17f0-3bdf-418c-a95e-0b89e5a8b2f8`). También se acepta la URL `https://styles.refero.design/style/<uuid>`, de la que se toma el UUID. Un estilo por corrida. |
| *(sin argumento)* | No hace nada. Explica cómo obtener el UUID: elegir un estilo en <https://styles.refero.design/> y copiar su URL. |
| `--es` / `--en` | Idioma del plan y de los mensajes. Por defecto `--es`. El código y la documentación de khipu siguen en español, con los nombres de khipu. |

## Flujo (en orden)

1. **Comprobar que es khipu**
   - El `package.json` del directorio actual debe tener
     `"name": "khipu-design-system"`. Si no, detenerse: *«Esta skill trabaja
     solo dentro de khipu-design-system.»*
   - El árbol de trabajo debe estar limpio (`git status`). Si no, detenerse y
     pedir que se guarden o descarten los cambios.

2. **Leer el contexto de khipu**
   - `CLAUDE.md`, `README.md` y `docs/design-system.md` (principios, tokens,
     escala de alturas, kit reutilizable §20).
   - `src/app/globals.css` (`@theme`, `:root`, `.dark`).
   - `registry/registry.json`, para saber qué componentes existen.
   - `src/lib/estilos.ts`, que tiene las recetas compartidas.
   - Las **convenciones de khipu** son restricciones duras: color solo por
     token, una sola altura de control `h-9`, mono con `tabular-nums` para
     datos, máximo 5 series en gráficos, patrón «próximamente», nombres en
     español, rutas, textos, iconos y handlers por props.

3. **Validar el UUID y extraer el estilo**
   - Validar el formato (36 caracteres, hexadecimal con guiones).
   - Ejecutar `node <carpeta-de-la-skill>/scripts/refero-fetch.mjs <uuid>`.
   - Caché en `<tmp del sistema>/ui-ux-scout/<uuid>.json`, válida 7 días.
     Nunca dentro de khipu.
   - **Plan B:** si Node no está disponible, el script falla o el JSON no trae
     `colors`, usar `WebFetch` sobre la página del estilo y marcar el plan con
     un aviso visible: *«Valores extraídos vía WebFetch: pueden no ser
     exactos.»*

4. **Plan** (según `references/plan-template.md`). Se muestra en la terminal.
   No se toca ningún archivo todavía. Contiene:
   - **Componentes nuevos:** para cada uno, nombre en español, carpeta
     (`ui`, `patrones`, `feedback`, `formularios`, `navegacion`, `datos`,
     `nav`), API de props, si es Server o Client Component y por qué, base-ui
     si aplica, y de qué componentes y recetas existentes depende.
   - **Reutilización (DRY):** para cada componente nuevo, qué componentes,
     recetas de `lib/estilos.ts` y utilidades de `lib/` reutiliza, y por qué
     no basta con extender uno existente. Si un componente existente ya cubre
     el caso con una variante o prop opcional, se propone eso en lugar de un
     componente nuevo.
   - **Validación:** para cada campo de formulario que se cree o ajuste, su
     tipo de dato, las reglas que aplica, cuándo valida y el mensaje de error
     (ver **Validación de campos**).
   - **Componentes a ajustar:** archivo, qué cambia y por qué, y si cambia la
     API (no se permite romperla, ver **Reglas**).
   - **Tokens:** cada cambio por separado, con valor actual → nuevo en claro y
     oscuro, contraste WCAG calculado de los pares afectados y la advertencia
     de que afecta a todos los consumidores de khipu.
   - **Conflictos con convenciones:** qué pide el `DESIGN.md`, qué dice khipu y
     cómo se resuelve. Siempre gana khipu.
   - **Archivos que se tocarán.**

5. **Aprobación**
   - El usuario aprueba, quita o cambia puntos. Los tokens se aprueban uno por
     uno. Sin un «sí» explícito no se aplica nada.

6. **Aplicar** en una rama nueva `feat/estilo-<nombre-del-estilo>` creada
   desde `main`, siguiendo `references/khipu-checklist.md`. Para cada
   componente nuevo:
   1. Crear el archivo en su carpeta, con imports por alias `@/`.
   2. Agregarlo a la galería de `src/app/ejemplo/galeria.tsx`.
   3. Documentarlo en `docs/design-system.md` §20 «Kit reutilizable»: en la
      fila de su grupo y en un párrafo de lote.
   4. Agregarlo a `docs/guia-visual.html`.
   5. Agregarlo a la lista de **Estructura** del `README.md`.

   Después de todos los cambios: `npm run registry:build`.

7. **Verificar**
   - `npm run typecheck`, `npm run lint` (incluye `check:alturas`) y
     `npm run build`. Si alguno falla, corregir y repetir. Si no se puede
     corregir, informar el error y no dar el trabajo por terminado.
   - Levantar `npm run dev` y revisar `/ejemplo` en claro y oscuro.
   - Dejar los cambios **sin commitear** y un resumen de lo hecho. El commit y
     el PR se hacen con `git-flow`.

## Reglas

- **Las convenciones de khipu mandan** sobre el `DESIGN.md`.
- **Nada de hex ni paleta de Tailwind en componentes:** todo pasa por tokens.
- **DRY y SOLID** según la sección del mismo nombre; la validación, según
  **Validación de campos**; cada componente, según **Componentes
  reutilizables y sólidos**.
- **No romper consumidores:** no se borran ni renombran componentes, props,
  exports ni tokens existentes. Solo se cambian valores, se agregan props
  opcionales o se agregan tokens nuevos.
- **Estética, no marca:** se toman decisiones de sistema (elevación, escala,
  densidad, anatomía de componentes), no logos, ilustraciones, textos ni el
  color de marca de la referencia como identidad de khipu.
- **Contenido de terceros:** solo se descarga el estilo pedido, una petición
  por corrida. No se commitean copias del `DESIGN.md`. El resumen final
  incluye la URL de la fuente para citarla en el commit.

## DRY y SOLID

Contenido de `references/clean-design.md`, aplicado a componentes de khipu.

**DRY**

- Antes de crear algo, buscar en `registry/registry.json`, `lib/estilos.ts`
  y `lib/` si ya existe. Reutilizar componentes y recetas (`CAMPO`,
  `BOTON_PRIMARIO`, `TARJETA`…) en lugar de repetir clases.
- Una regla de validación, un formato o una receta viven en **un solo
  lugar** y se importan; no se copian entre componentes.
- No crear abstracciones para un solo uso: se extrae cuando hay al menos dos
  usos reales.

**SOLID** (adaptado a componentes)

- **Responsabilidad única:** un componente presenta; la lógica (validación,
  formato, paginación) vive en `lib/` como funciones puras.
- **Abierto/cerrado:** se extiende con variantes (`cva`), props opcionales y
  composición (`children`, slots), sin modificar el comportamiento existente.
- **Sustitución:** los componentes que envuelven un elemento nativo aceptan y
  propagan sus props (`React.ComponentProps<"input">`, `...props`), como ya
  hace `Entrada`.
- **Segregación de interfaces:** props pequeñas y específicas; nada de
  objetos de configuración gigantes ni props que solo usa un caso.
- **Inversión de dependencias:** rutas, textos, iconos y handlers entran por
  props; el componente no conoce la app que lo usa (convención de khipu).

## Componentes reutilizables y sólidos

Todo componente que la skill cree o ajuste debe cumplir esta lista antes de
darse por terminado. Está en `references/khipu-checklist.md` y la skill la
recorre punto por punto en el resumen final.

**Reutilizable**

- No conoce la app que lo usa: rutas, textos, iconos, datos y handlers entran
  por props.
- Acepta `className` y lo combina con `cn`; propaga el resto de props
  (`...props`) y la `ref` al elemento raíz (en React 19, `ref` como prop).
- Variantes con `cva` cuando hay más de una apariencia; valores por defecto
  sensatos para que funcione con props mínimas.
- Soporta modo controlado y no controlado cuando tiene estado propio
  (`value` / `defaultValue` + `onValueChange`), como los componentes de base-ui.
- Composición antes que configuración: `children` y subcomponentes en lugar
  de decenas de props.

**Sólido**

- Tipado estricto: props exportadas como tipo, sin `any`, uniones literales
  para variantes.
- Todos los estados resueltos: por defecto, hover, foco visible, activo,
  deshabilitado (con la regla «próximamente» de khipu), cargando, error y
  vacío, cuando apliquen.
- Accesible: semántica nativa o roles ARIA correctos, operable con teclado,
  `aria-*` y etiquetas asociadas, contraste AA en claro y oscuro.
- Robusto ante datos reales: textos largos (`min-w-0`, truncado), listas
  vacías, valores `null`, números grandes con `tabular-nums`.
- Responsive y correcto en claro y oscuro.
- Server Component por defecto; `"use client"` solo si usa estado, efectos o
  eventos, y lo justifica en el plan.
- Un comentario JSDoc breve encima del export, como los componentes actuales.
- Su entrada en la galería de `/ejemplo` muestra todas sus variantes y
  estados.

## Validación de campos

Contenido de `references/field-validation.md`.

**Dónde vive**

- Las reglas son funciones puras en `src/lib/validacion.ts` (se crea la
  primera vez que hace falta; entra al registro como `lib`). Cada función
  recibe el valor y devuelve `null` si es válido o el mensaje de error en
  español.
- La presentación ya existe y se reutiliza: `Campo` (prop `error`, con
  `role="alert"`) y `Entrada` / `AreaTexto` (prop `invalido`, que pone
  `aria-invalid`).
- No se agregan librerías de validación (p. ej. zod) sin aprobarlo en el plan.

**Reglas por tipo de dato** (mínimo)

| Tipo | Control | Reglas |
|---|---|---|
| Texto | `Entrada` | requerido, longitud mín./máx., recorte de espacios |
| Email | `Entrada type="email"` | formato de email |
| Número entero / decimal | `StepperNumerico` / `Entrada inputMode="decimal"` | numérico, rango mín./máx., decimales permitidos |
| Monto | `EntradaMonto` | ≥ 0 salvo que se indique, 2 decimales, coherente con `formatearMonto` |
| Fecha / rango | `EntradaFecha` / `EntradaRangoFechas` | fecha ISO válida, mín./máx., inicio ≤ fin, zona `America/Lima` |
| RUC | `Entrada mono` | 11 dígitos, prefijo válido (10, 15, 17, 20) y dígito verificador |
| DNI | `Entrada mono` | 8 dígitos |
| Teléfono | `Entrada type="tel"` | solo dígitos y `+`, longitud |
| URL | `Entrada type="url"` | URL absoluta `http(s)` |
| Contraseña | `Contrasena` | longitud mínima y reglas que pida el caso |
| Archivo | `ZonaArchivos` | tipo MIME / extensión y tamaño máximo |

**Cuándo valida y cómo se muestra**

- Al salir del campo (`blur`) y al enviar; no mientras se escribe la primera
  vez. Una vez mostrado un error, se revalida al cambiar.
- El mensaje dice qué se espera, no solo que está mal («El RUC tiene 11
  dígitos»). Un error por campo.
- Los atributos nativos (`required`, `type`, `inputMode`, `min`, `max`,
  `maxLength`) se usan además de la función, para teclado móvil y
  accesibilidad; nunca en su lugar.

**Pruebas de validación:** khipu no tiene hoy un test runner. Si el plan crea
`lib/validacion.ts`, debe proponer cómo probarlo (p. ej. `node --test` con los
casos de la tabla). Agregar el runner al repo se aprueba en el plan como un
punto aparte.

## Contrato del script `refero-fetch.mjs`

- Node ≥ 18 (`fetch` nativo). Sin dependencias.
- Entrada: `node refero-fetch.mjs <uuid|url>`.
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

## Por qué solo UUID

Decidido el 2026-10-14. `sitemaps/styles.xml` lista solo URLs `/style/<uuid>`,
sin nombres, y la búsqueda del sitio (`/?q=`) no devuelve enlaces a estilos que
se puedan parsear de forma fiable. Resolver nombres exigiría descargar cientos
de páginas o depender de detalles internos del sitio.

## Errores

| Situación | Comportamiento |
|---|---|
| No es el repo de khipu | Detenerse con mensaje claro. |
| Árbol de trabajo con cambios | Detenerse y pedir que se guarden o descarten. |
| Argumento sin UUID válido | Rechazar y explicar cómo copiar la URL del estilo. |
| Estilo no encontrado (404) | Decirlo, mostrando el UUID recibido. |
| Payload no reconocible | Aviso de formato cambiado → plan B con WebFetch. |
| Sin red | Usar caché si existe y avisarlo; si no, detenerse. |
| Node ausente o < 18 | Plan B con WebFetch y aviso de precisión. |
| Verificación falla tras aplicar | Corregir; si no se puede, informar y no dar por terminado. |

## Pruebas

- `test-refero-fetch.mjs` (`node --test`), sin red:
  - un **fixture sintético** que imita la estructura del payload, sin
    contenido real de Refero;
  - casos: parseo correcto, campos ausentes → `[]`/`null`, payload sin el
    objeto del estilo → código `3`, URL frente a UUID, entrada inválida →
    código `1`.
- Prueba de punta a punta (manual), en khipu con el estilo Raycast
  (`3b6a17f0-3bdf-418c-a95e-0b89e5a8b2f8`). Criterios:
  - los hex del plan coinciden con la página de Refero;
  - se crea al menos un componente nuevo y aparece en `registry/registry.json`;
  - el componente nuevo aparece en `/ejemplo`, `docs/design-system.md` (§20)
    y `docs/guia-visual.html`;
  - `npm run typecheck`, `npm run lint` y `npm run build` pasan;
  - ningún componente, prop, export ni token existente fue borrado o
    renombrado;
  - cada componente nuevo cumple la lista de **Componentes reutilizables y
    sólidos**, y el resumen final la recorre punto por punto;
  - el plan justifica cada componente nuevo frente a extender uno existente
    (DRY) y no hay clases ni reglas duplicadas entre componentes;
  - si se crea un campo de formulario, valida según su tipo con
    `lib/validacion.ts` y muestra el error con `Campo`;
  - `node cli/khipu.mjs add <componente-nuevo>` lo copia a un proyecto de
    prueba.

## Fases futuras

- **B · Rama Angular de khipu:** carpeta propia, toolchain, mismos tokens CSS,
  port de los componentes base, y CLI y registro con `--angular`. Spec propio.
- **C · La skill genera también Angular:** con B hecho, por cada componente
  nuevo la skill crea su versión Angular (standalone, signals) y la da de alta.
  Requiere agregar `references/angular.md`.
