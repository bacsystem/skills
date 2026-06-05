# skills

[![Version](https://img.shields.io/github/v/tag/bacsystem/skills?label=version&sort=semver)](https://github.com/bacsystem/skills/tags)
[![License](https://img.shields.io/github/license/bacsystem/skills)](./LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/bacsystem/skills)](https://github.com/bacsystem/skills/commits/main)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://www.conventionalcommits.org/)
[![Keep a Changelog](https://img.shields.io/badge/changelog-Keep%20a%20Changelog-orange.svg)](https://keepachangelog.com/)
[![Bash](https://img.shields.io/badge/Bash-3.2%2B-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skills-8A2BE2.svg)](https://claude.com/claude-code)

Colección de skills para Claude Code.

## Descripción

Este repositorio agrupa skills reutilizables para Claude Code. Cada skill se
define en su propia carpeta con un archivo `SKILL.md` que incluye el frontmatter
(`name`, `description`) y las instrucciones que Claude seguirá al invocarla.

## Skills

| Skill | Descripción |
|---|---|
| [`git-flow`](./git-flow) | Flujo guiado de entrega: del working tree al PR (ramas, code review, Conventional Commits, SemVer y plantilla de PR) |

## Estructura

```
skills/
├── README.md
├── CHANGELOG.md
├── .gitignore
└── <nombre-skill>/
    └── SKILL.md
```

## Cómo agregar una skill

1. Crea una carpeta con el nombre de la skill (en `kebab-case`).
2. Dentro, agrega un archivo `SKILL.md` con el frontmatter y las instrucciones.
3. Registra el cambio en el [CHANGELOG](./CHANGELOG.md).

## Versiones

Resumen de las versiones publicadas. El detalle completo está en el
[CHANGELOG](./CHANGELOG.md).

| Versión | Fecha | Highlights |
|---|---|---|
| [`v0.2.4`](https://github.com/bacsystem/skills/releases/tag/v0.2.4) | 2026-06-05 | Tablas de Skills y Versiones, badges y licencia MIT |
| [`v0.2.3`](https://github.com/bacsystem/skills/releases/tag/v0.2.3) | 2026-06-05 | Script `next-version.sh` (bump SemVer) + primer runner de tests |
| [`v0.2.2`](https://github.com/bacsystem/skills/releases/tag/v0.2.2) | 2026-06-05 | Paso «Verify», SemVer `0.x`, resolución de remoto, `verify-commands.md` |
| [`v0.2.1`](https://github.com/bacsystem/skills/releases/tag/v0.2.1) | 2026-06-05 | Workflow `auto-tag` + READMEs + badges |
| [`v0.2.0`](https://github.com/bacsystem/skills/releases/tag/v0.2.0) | 2026-06-05 | Skill `git-flow` inicial |
| [`v0.1.0`](https://github.com/bacsystem/skills/releases/tag/v0.1.0) | 2026-06-05 | Estructura inicial del repositorio |

## Contribuir

- Sigue [Semantic Versioning](https://semver.org/lang/es/) para las versiones.
- Documenta cada cambio relevante en el [CHANGELOG](./CHANGELOG.md).

## Licencia

[MIT](./LICENSE) © Christian Bacilio
