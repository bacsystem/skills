# skills

[![Version](https://img.shields.io/github/v/tag/bacsystem/skills?label=version&sort=semver)](https://github.com/bacsystem/skills/tags)
[![Auto tag](https://img.shields.io/github/actions/workflow/status/bacsystem/skills/auto-tag.yml?branch=main&label=auto-tag)](https://github.com/bacsystem/skills/actions/workflows/auto-tag.yml)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://www.conventionalcommits.org/)
[![Keep a Changelog](https://img.shields.io/badge/changelog-Keep%20a%20Changelog-orange.svg)](https://keepachangelog.com/)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skills-8A2BE2.svg)](https://claude.com/claude-code)

Colección de skills para Claude Code.

## Descripción

Este repositorio agrupa skills reutilizables para Claude Code. Cada skill se
define en su propia carpeta con un archivo `SKILL.md` que incluye el frontmatter
(`name`, `description`) y las instrucciones que Claude seguirá al invocarla.

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

## Contribuir

- Sigue [Semantic Versioning](https://semver.org/lang/es/) para las versiones.
- Documenta cada cambio relevante en el [CHANGELOG](./CHANGELOG.md).
