# Changelog

Todos los cambios notables de este proyecto se documentan en este archivo.

El formato se basa en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/),
y este proyecto sigue [Semantic Versioning](https://semver.org/lang/es/).

## [Sin publicar]

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

[Sin publicar]: https://github.com/bacsystem/skills/compare/v0.2.6...HEAD
[0.2.6]: https://github.com/bacsystem/skills/compare/v0.2.5...v0.2.6
[0.2.5]: https://github.com/bacsystem/skills/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/bacsystem/skills/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/bacsystem/skills/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/bacsystem/skills/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/bacsystem/skills/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/bacsystem/skills/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bacsystem/skills/releases/tag/v0.1.0
