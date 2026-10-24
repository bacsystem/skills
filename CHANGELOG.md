# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato se basa en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto sigue [Semantic Versioning](https://semver.org/lang/es/).

## [0.2.13] - 2026-10-22

### Añadido
- `pr-review`: **listón estricto**. `APROBADO` exige que el revisor haya corrido
  las suites que cubren el cambio (con sus conteos), mutado el test clave hasta
  verlo en rojo, trazado las entradas límite y abierto el *radio de acción*
  del cambio (los demás escritores de la tabla, los endpoints hermanos, los
  llamadores); si falta algo, el veredicto baja a `APROBADO CON CAMBIOS` con un
  hallazgo que nombra la verificación ausente. En corrección, seguridad o datos,
  un defecto verificado es `BLOQUEANTE` por defecto y la duda entre dos
  severidades se resuelve hacia arriba; un `[POSIBLE]` en dinero, autorización,
  sesiones o persistencia también limita el veredicto.
- `pr-review`: sección obligatoria **🔬 Verificación** en el informe (ES y EN),
  antes del veredicto: suites ejecutadas, mutación, entradas trazadas,
  reproducciones y archivos del radio de acción abiertos, o «no hecho: motivo».
- `pr-review`: dos pasos previos nuevos: comprobar si el CI ejecuta las
  pruebas en las PR (si no, la corrida del revisor es la única puerta y el
  informe lo dice) y buscar si el cambio revierte un criterio de un issue ya
  cerrado.
- `pr-review`: ocho casos nuevos en `references/case-studies.md`, aprendidos de
  una auditoría completa de khipu: la guarda de estado que solo cubre los
  estados que el autor pensó; la excepción después del punto de no retorno; la
  precisión que se estrecha en la columna, la plantilla o la rehidratación; el
  upsert de fila completa que pisa actualizaciones de una columna; la regla
  aplicada a un endpoint y no a sus hermanos; la revocación que depende de la
  credencial que revoca; la dependencia que manda datos al proveedor por
  defecto; el límite sobre lo comprimido y no sobre lo decodificado.
- `pr-review`: idiomas nuevos en `references/language-idioms.md`. Java/Spring/
  PostgreSQL: `NUMERIC` más estrecho que el dominio, `?string["0.####"]` de
  FreeMarker, `ON CONFLICT … EXCLUDED` de toda la fila, `S3Exception` frente a
  `SdkClientException`, `HttpRequest.timeout` solo hasta las cabeceras,
  `@Scheduled` con varias réplicas, Tomcat atado a la línea de Boot. Next.js:
  login CSRF en route handlers que escriben cookies, segmento `[id]`
  interpolado en la URL al backend, `next.config.ts` sin `headers()`.
- `pr-review`: sección *Security boundaries* en
  `references/production-readiness.md` (paridad de guardas, claves estáticas
  que heredan cada endpoint nuevo, revocación, origen en handlers con cookies,
  límites sobre lo decodificado, cabeceras de seguridad), más adaptadores de
  desarrollo que registran enlaces de un solo uso, topes de reintento que un
  `catch` genérico salta, egreso por defecto de dependencias, ventana de
  soporte de un framework fijado y dependencias git con build en la
  instalación.
- `pr-review`: siete errores comunes nuevos y una regla: estricto no es
  ruidoso (cada hallazgo sigue exigiendo `archivo:línea`, consecuencia y forma
  de probarlo).

## [0.2.12] - 2026-10-17

### Añadido
- `pr-review`: **contratos que valida otro sistema**. Un documento que pasa el
  esquema local no es un documento aceptado por quien lo recibe (autoridad
  tributaria, pasarela de pago, API de un tercero). El revisor contrasta la
  decisión con las notas del repo sobre ese sistema y, si la PR deja pendiente
  la prueba en su sandbox y el cambio altera lo que se envía, lo reporta como
  hallazgo `IMPORTANTE`; si el repo ya tiene un arnés para ese sistema, lo
  corre o dice por qué no pudo.
- `pr-review`: un criterio del issue que la PR deja abierto a propósito (una
  prueba en sandbox, una decisión del dueño) se lista como no cumplido con lo
  que lo cierra; un issue con PR mergeada y un criterio abierto no se cierra a
  mano.
- `pr-review`: caso nuevo en `references/case-studies.md` (*un documento válido
  para el esquema no es uno aceptado*), sección *Documents another system
  validates* en `references/production-readiness.md` y tres errores comunes
  nuevos.

## [0.2.11] - 2026-10-17

### Añadido
- `pr-review`: **modo corrección** (*Fix mode*). Aplica los hallazgos por ID
  cuando el usuario lo pide («corrige H2», «CORRIGE») o cuando el `CLAUDE.md`
  o la memoria del proyecto ya lo autorizan antes del merge. Primero la prueba
  que falla, luego el arreglo; corre las suites que el cambio puede afectar,
  rompe el código una vez a propósito para confirmar que la prueba nueva se
  pone roja, hace commit en la rama de la PR, corrige las cifras del cuerpo de
  la PR e informa con una tabla de re-revisión. Solo empuja a una rama propia o
  con permiso de su dueño (en una PR ajena deja los commits en local). Nunca
  debilita una prueba para que pase y nunca hace merge.
- `pr-review`: **revisar código propio**. Si la misma sesión escribió la PR, el
  informe lo dice y exige al menos una comprobación que el autor no hizo al
  implementar (reproducir un criterio contra el sistema real o repetir una
  mutación a mano); las cifras de la PR se tratan como afirmaciones ajenas.
- `pr-review`: **cambios chicos y de configuración** (compose, `.env.example`,
  CI, docs) usan un informe corto y el esfuerzo se va a ejecutar el cambio.
- `pr-review`: **preferir ejecutar a leer** en la regla de evidencia (un
  `curl`, un contenedor con el ajuste, un archivo de pruebas).
- `pr-review`: los **criterios del issue** dicen si el revisor los
  *reprodujo* o si son *según la PR*; un criterio que nombra variantes (factura
  y boleta, web y móvil) pide una prueba por variante.
- `pr-review`: el informe **abre con una línea de veredicto** y el conteo por
  severidad, sin quitar la sección de veredicto del final.
- `pr-review`, referencias: «el tipo y el mock repiten la misma suposición»
  (clave omitida frente a `null`), «un criterio nombra una variante sin
  prueba», «revisar tu propio trabajo comparte tus puntos ciegos»; en TypeScript,
  tipos de cliente frente a un backend que omite nulos y páginas que congelan
  una variable de entorno en el build; en Java/Spring, ajustes del serializador
  que cambian el contrato; en producción, un ajuste que lee más de un servicio
  y llega solo a uno, y funciones apagadas hasta encender un flag.

### Cambiado
- `pr-review`: la regla «nunca edita» pasa a valer **en modo revisión**; el
  modo corrección es la única vía por la que el skill cambia archivos.
- `pr-review`: las mutaciones se hacen solo sobre archivos con commit y se
  restauran con `git checkout -- <archivo>`.

## [0.2.10] - 2026-10-15

### Añadido
- Skill `ui-ux-scout`: crea y mejora componentes en khipu-design-system a
  partir de un estilo de Refero Styles indicado por UUID. Muestra un plan
  (componentes nuevos, ajustes, tokens con contraste WCAG calculado y
  conflictos con las convenciones de khipu), espera la aprobación, lo aplica
  en una rama y verifica `typecheck`, `lint` y `build`. Nunca commitea.
- `ui-ux-scout/scripts/refero-fetch.mjs`: extrae los valores exactos del
  estilo del payload de Next.js de la página, con caché de 7 días y códigos de
  salida `0`–`4`; tests sin red con fixtures sintéticos.
- `ui-ux-scout/scripts/contraste.mjs`: ratio de contraste WCAG para tokens en
  hex (3, 4, 6 y 8 dígitos) y `rgb()`/`rgba()`, componiendo el alfa sobre la
  superficie base; rechaza colores mal formados. Con tests.
- `ui-ux-scout/references/`: principios de UI/UX, React 19 y Next.js 15, DRY
  y SOLID para componentes, validación por tipo de dato (incluido RUC con
  dígito verificador), checklist de alta en khipu, plantilla del plan y
  formato de la página de Refero.

## [0.2.9] - 2026-10-03

### Añadido
- `pr-review`: **eje de corrección**, el primero de cinco. En vez de juzgar si
  el cambio «se ve bien», pasa entradas por el código: casos borde (vacío,
  nulo, límites, *off-by-one*, texto raro), duplicados, reintentos y
  peticiones concurrentes, caminos de error que dejan trabajo a medias,
  errores de lógica, zonas horarias y dinero, y tipos y validación de datos
  coherentes entre capas (formulario, DTO, dominio, columna).
- `pr-review`: **criterios del issue enlazado**. Lee el issue que el PR cierra
  o referencia, contrasta cada criterio de aceptación con el diff y lo reporta
  en una sección propia; un PR que dice cerrar un issue con un criterio
  pendiente recibe un hallazgo. También señala cambios fuera de alcance.
- `pr-review`, eje Clean Code: **complejidad cognitiva** con umbrales
  orientativos (anidamiento, operadores por condición, largo de función,
  parámetros, banderas booleanas) que indican dónde mirar, no qué reportar.
- `pr-review`, eje de buenas prácticas: **lo que se rompe después del merge**
  (migraciones, compatibilidad de API y datos, configuración, operabilidad,
  rendimiento visible en un diff, estados y accesibilidad del frontend,
  dependencias nuevas).
- `references/code-smells.md`: catálogo de *code smells* (bloaters, couplers,
  change preventers, dispensables, obfuscators), cada uno con cuándo **es** un
  hallazgo y cuándo es solo estilo.
- `references/production-readiness.md`: guía por tema de lo que se rompe en
  producción, para revisar solo las secciones que el diff toca.
- `pr-review`, errores comunes: revisar solo la forma del código, reportar una
  métrica en vez de un costo, convertir las listas en hallazgos e ignorar el
  issue enlazado.
- `pr-review`: **modo re-revisión**. Cuando el PR ya se revisó (antes en la
  conversación o en un comentario previo), el reporte abre con una tabla de
  los hallazgos anteriores —resuelto, parcial o descartado, con evidencia— y
  revisa solo los commits nuevos. Una corrección que introduce un problema
  nuevo es un hallazgo nuevo; «resuelto» exige evidencia, no la palabra del
  autor.
- `pr-review`: **IDs estables por hallazgo** (`H1`, `H2`… en español; `F1`,
  `F2`… en inglés), que se conservan entre revisiones, y en cada hallazgo el
  test que lo demuestra (el que falla mientras el defecto exista).
- `pr-review`: sección opcional **Seguimiento** / **Follow-ups** para mejoras
  reales fuera del alcance del PR. No cuenta para el veredicto ni entra en
  «corrige los hallazgos»; no es una severidad más baja.
- `pr-review`, eje de buenas prácticas: **los tests discriminan** (nombrar el
  cambio de producción que haría fallar los tests críticos), **los mocks y
  fakes respetan el contrato real**, y **las cifras del PR se verifican**
  (conteos de tests, mutaciones, «probado en X»).
- `pr-review`: antes del diff, leer las convenciones del repo (`CLAUDE.md`,
  `AGENTS.md`, `CONTRIBUTING.md`, documentos de QA); en diffs grandes, revisar
  por capas y cerrar con «Archivos revisados: N/N».
- `references/case-studies.md`: un test que pasa —o falla— por la razón
  equivocada; la defensa en profundidad que oculta la regresión de una capa;
  el mismo valor guardado con dos grafías según la ruta; un fake compartido en
  el que un test escribe. El caso de comentarios no verificados se extiende a
  las cifras del cuerpo del PR.
- `references/language-idioms.md`: sección **Java / Spring** (`@Valid` en
  objetos anidados, `@Size` desalineado con la columna, valores por defecto de
  librerías como `RemoteIpValve`, `InetAddress.getByName` con texto no
  confiable, barras invertidas en `@SpringBootTest(properties)`) y dos
  entradas de Next.js (`next/headers` alcanzable desde un componente cliente;
  un enlace publicado como `role="button"`).
- Registro tardío: `references/case-studies.md` y `references/language-idioms.md`
  existían desde el commit `a5134ff`, que entró sin entrada en este changelog.

## [0.2.8] - 2026-09-08

### Añadido
- Skill `pr-review`: code review de un pull request —propio o de terceros—
  contra cuatro ejes (Clean Code, SOLID, DRY y buenas prácticas de desarrollo),
  con salida en tres secciones fijas: lo que está bien, lo que debe corregirse
  (con severidad `BLOQUEANTE`/`IMPORTANTE`/`MENOR`) y un veredicto explícito.
  Cada hallazgo exige `archivo:línea` y una consecuencia concreta; cero
  hallazgos es un resultado válido. El skill solo revisa y reporta: nunca
  edita, commitea ni mergea.
- Flags de idioma `--es`/`--en` (por defecto español) que cambian los
  encabezados, las severidades y el veredicto del reporte.
- Flag `--comment` para publicar el review como comentario en el PR de GitHub
  (`gh pr comment`), mostrando antes el PR objetivo y el cuerpo exacto y
  pidiendo confirmación explícita. Sin el flag, el reporte queda solo en
  consola. Publica un comentario plano: nunca abre un review de GitHub con
  estado approve/request-changes.

## [0.2.7] - 2026-07-04

### Corregido
- `git-flow/SKILL.md`: el paso 9 fijaba la base del PR en `main` sin condición.
  Ahora el paso 1 detecta si existe una rama `develop` (local o en el remoto) y,
  si existe, esa es la base del PR — para repos que siguen GitFlow con rama
  `develop`. El paso 10 (tag post-merge) solo taguea si la base fue `main`; un
  merge a `develop` es un paso de integración, no un release.

## [0.2.6] - 2026-06-05

### Cambiado
- Tabla **Skills** del README: se quita la columna «Versión». Para un repo de un
  solo skill cuya versión coincide con la del repo, esa celda duplicaba info y
  se desincronizaba en cada release docs-only. La versión vive en el badge, la
  tabla de Versiones y los tags.

## [0.2.5] - 2026-06-05

### Eliminado
- Badges `auto-tag` y `Top language` del README principal: el primero queda en
  rojo mientras GitHub Actions esté deshabilitado (billing de la org); el
  segundo renderiza de forma intermitente el error de pool de tokens de
  shields.io. El badge `Bash` ya comunica el stack.

## [0.2.4] - 2026-06-05

### Añadido
- Licencia MIT (`LICENSE`).
- README principal: tabla de **Skills** (catálogo) y tabla de **Versiones**
  (historial enlazado al CHANGELOG).
- Badges en el README: License, Last commit, Top language y Bash.

## [0.2.3] - 2026-06-05

### Añadido
- Script `git-flow/scripts/next-version.sh`: calcula la próxima versión SemVer
  a partir de `(versión actual, tipo de commit)`, encapsulando la regla 0.x.
  Es función pura y testeable; el skill lo usa en el paso «Compute version».
- Runner de tests `git-flow/scripts/test-next-version.sh` (bash sin
  dependencias): primer conjunto de tests del repo.

## [0.2.2] - 2026-06-05

### Añadido
- Skill `git-flow`: paso «Verify» que ejecuta el comando de test/lint del
  proyecto antes de commitear y se detiene si falla.
- Referencia `git-flow/references/verify-commands.md`: mapa de comandos de
  test/lint por ecosistema (Node, Python, Go, Rust, etc.) para el paso «Verify».

### Corregido
- SemVer pre-1.0 (`0.x`): un cambio incompatible sube la *minor* y el resto la
  *patch* (antes `feat` subía la minor, sobre-versionando proyectos 0.x).
- El flujo ya no asume el remoto `origin`: lo resuelve con `git remote -v`
  (soporta remotos con alias SSH).
- README de `git-flow`: el auto-tag se documenta como condicional a que GitHub
  Actions esté habilitado, con instrucción de tag manual mientras tanto.

## [0.2.1] - 2026-06-05

### Añadido
- GitHub Action `auto-tag`: crea el tag `vX.Y.Z` automáticamente al mergear a `main`, leyendo la versión del `CHANGELOG.md`.
- README de la skill `git-flow` (`git-flow/README.md`).
- Badges de [shields.io](https://shields.io) en el README principal (versión, estado del workflow, Conventional Commits, Keep a Changelog).

## [0.2.0] - 2026-06-05

### Añadido
- Skill `git-flow`: flujo guiado de entrega (rama `tipo/descripcion`, code review, Conventional Commits, SemVer automático y PR) con plantilla de PR en `git-flow/references/pr-template.md`.
- Documento de diseño de la skill `git-flow` en `docs/superpowers/specs/`.

## [0.1.0] - 2026-06-05

### Añadido
- Estructura inicial del repositorio: `README.md`, `CHANGELOG.md` y `.gitignore`.

[Sin publicar]: https://github.com/bacsystem/skills/compare/v0.2.9...HEAD
[0.2.9]: https://github.com/bacsystem/skills/compare/v0.2.8...v0.2.9
[0.2.8]: https://github.com/bacsystem/skills/compare/v0.2.7...v0.2.8
[0.2.7]: https://github.com/bacsystem/skills/compare/v0.2.6...v0.2.7
[0.2.6]: https://github.com/bacsystem/skills/compare/v0.2.5...v0.2.6
[0.2.5]: https://github.com/bacsystem/skills/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/bacsystem/skills/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/bacsystem/skills/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/bacsystem/skills/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/bacsystem/skills/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/bacsystem/skills/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bacsystem/skills/releases/tag/v0.1.0
