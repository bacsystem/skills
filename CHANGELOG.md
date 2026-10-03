# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato se basa en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto sigue [Semantic Versioning](https://semver.org/lang/es/).

## [Sin publicar]

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
