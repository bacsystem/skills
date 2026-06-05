# skills

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
