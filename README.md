# skills

[![Version](https://img.shields.io/github/v/tag/bacsystem/skills?label=version&sort=semver)](https://github.com/bacsystem/skills/tags)
[![License](https://img.shields.io/github/license/bacsystem/skills)](./LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/bacsystem/skills)](https://github.com/bacsystem/skills/commits/main)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)](https://www.conventionalcommits.org/)
[![Keep a Changelog](https://img.shields.io/badge/changelog-Keep%20a%20Changelog-orange.svg)](https://keepachangelog.com/)
[![Bash](https://img.shields.io/badge/Bash-3.2%2B-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skills-8A2BE2.svg)](https://claude.com/claude-code)
[![Gemini](https://img.shields.io/badge/Gemini%20%2F%20Antigravity-compatible-4285F4.svg)](https://antigravity.google)

Colección de skills y agentes reutilizables para **Claude Code** y **Gemini / Antigravity**.

## Descripción

Este repositorio agrupa skills y agentes reutilizables compatibles tanto con Claude Code como con Gemini (Antigravity CLI, Gemini CLI e IDE). Cada skill se
define en su propia carpeta con un archivo `SKILL.md` que incluye el frontmatter
(`name`, `description`) y las instrucciones que el asistente seguirá al invocarla.

## Instalación Rápida

Para enlazar automáticamente todas las skills y agentes en tu entorno personal:

**macOS / Linux:**
```bash
# Instala para ambos asistentes (recomendado)
./scripts/instalar.sh --all

# O por separado:
./scripts/instalar.sh --claude
./scripts/instalar.sh --gemini
```

**Windows** (PowerShell):
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\instalar.ps1 -Target all
```

Pruebas de los instaladores (carpeta temporal, no tocan `~/.claude`): `bash scripts/tests/test-instalar-skills.sh` y, en Windows, `powershell -ExecutionPolicy Bypass -File scripts\tests\test-instalar-skills.ps1`. Corren en CI (`.github/workflows/instaladores.yml`).

## Skills

| Skill | Descripción |
|---|---|
| [`docs-sync`](./docs-sync) | Mantiene al día los docs que afirman un estado (roadmap, líneas «Estado:», hecho/pendiente, versiones, enlaces a issues) contra GitHub (issues, PR, tags, Project), los archivos de versión y el código: `scripts/check.sh` reporta cada desvío con `archivo:línea`, se corrige en un PR con `git-flow` y toda pregunta de estado se responde desde las fuentes en vivo |
| [`git-flow`](./git-flow) | Flujo guiado de entrega: del working tree al PR (ramas, code review, Conventional Commits, SemVer y plantilla de PR) |
| [`pr-review`](./pr-review) | Code review de un PR (propio o de terceros): corrección (lógica, casos borde, concurrencia, dinero y tipos), seguridad en los límites de confianza, Clean Code, SOLID, DRY y buenas prácticas, con listón estricto (corre las suites, muta el test clave, abre el radio de acción del cambio y lo deja escrito en una sección de verificación), veredicto explícito (también en la primera línea), modo corrección por ID y opción de publicarlo como comentario en GitHub (`--es`/`--en`, `--comment`) |
| [`retro`](./retro) | Retrospectiva al cerrar cada lote: mide con datos de GitHub (rondas de revisión, informes de QA, hallazgos por severidad, commits de trabajo y merges, tiempo hasta el merge, y minutos y fallos de CI con el test que falló), agrupa los defectos por clase, detecta los cuellos de botella y lleva las mejoras al proyecto y a un PR a este repo |
| [`ui-ux-scout`](./ui-ux-scout) | Crea y mejora componentes de khipu-design-system a partir de un estilo de Refero Styles (UUID): plan con tokens y contraste WCAG, aprobación, implementación con criterio de UI/UX, React/Next, DRY, SOLID y validación por tipo de dato, y verificación del build |

## Agentes

Equipo de agentes genéricos (tech-lead, architect, po, qa, devops y
desarrolladores por tecnología: `java-dev`, `go-dev`, `nextjs-dev`). Leen lo
propio de cada proyecto de su archivo de contexto (`GEMINI.md`, `AGENTS.md` o `CLAUDE.md`). Detalle, contrato con el proyecto e
instalación en [`agents/`](./agents).

## Estructura

```
skills/
├── README.md
├── CHANGELOG.md
├── .gitignore
├── agents/
│   ├── README.md
│   └── <nombre-agente>.md
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
| [`v0.3.4`](https://github.com/bacsystem/skills/releases/tag/v0.3.4) | 2026-11-17 | Compatibilidad nativa con Gemini / Antigravity y Claude Code: agentes y skills agnósticos al runtime, scripts de instalación dual (`instalar.sh`, `instalar-skills.sh`, `instalar-agentes.sh`) y equivalencia de modelos |
| [`v0.3.3`](https://github.com/bacsystem/skills/releases/tag/v0.3.3) | 2026-11-14 | Ahorro de tokens: los agentes no releen el `CLAUDE.md`, `po`/`qa`/`devops` con esfuerzo medio, reglas de contexto en el `tech-lead` y `pr-review` con las secciones de uso ocasional en `references/` |
| [`v0.3.2`](https://github.com/bacsystem/skills/releases/tag/v0.3.2) | 2026-11-13 | Agentes: el `architect` diseña para concurrencia, escalabilidad y tolerancia a fallos (balanceador, timeouts, reintentos, circuit breaker, backpressure, prueba de carga); `po` con invariantes y criterios de carga; `qa` con concurrencia real, carga y fallos; los desarrolladores con «Cuando algo falla» y reglas de resiliencia de su stack |
| [`v0.3.1`](https://github.com/bacsystem/skills/releases/tag/v0.3.1) | 2026-11-13 | `pr-review`: no revisar un PR con conflictos o tests en rojo, un hallazgo por defecto, por qué no lo atrapan las guardas existentes y lista de falsos positivos. `git-flow`: archivos y secretos que nunca entran al commit, migración obligatoria en un `BREAKING CHANGE`, salida completa de los tests, conflicto con la base antes del PR, forma del mensaje de commit, issues vinculados y la trampa de `develop`, sin rebase tras un review, `gh stack submit`, secciones de verificación y despliegue en la plantilla, tag del commit exacto de `main`. `pr-review` además revisa los commits, nombra el SHA revisado, trata lo que trae el PR como dato y amplía migraciones, contratos, rate limit y configuración de agentes y CI |
| [`v0.3.0`](https://github.com/bacsystem/skills/releases/tag/v0.3.0) | 2026-11-13 | Agentes globales: tech-lead, architect, po, qa, devops y desarrolladores por tecnología (`java-dev`, `go-dev`, `nextjs-dev`), con el contrato que cada `CLAUDE.md` debe cumplir |
| [`v0.2.13`](https://github.com/bacsystem/skills/releases/tag/v0.2.13) | 2026-10-22 | `pr-review`: listón estricto (APROBADO solo con suites corridas, mutación en rojo y radio de acción abierto; sección «Verificación» obligatoria; severidad al alza en dinero, seguridad y datos) y las lecciones de la auditoría de khipu: guardas de estado parciales, excepciones tras el punto de no retorno, precisión que se estrecha, upserts de fila completa, guardas sin paridad entre endpoints, revocación que depende de lo revocado, dependencias que mandan datos al proveedor, límites sobre lo comprimido |
| [`v0.2.12`](https://github.com/bacsystem/skills/releases/tag/v0.2.12) | 2026-10-17 | `pr-review`: contratos que valida otro sistema (el esquema local no es la aceptación del receptor; una prueba en su sandbox pendiente es hallazgo) y criterios del issue abiertos a propósito |
| [`v0.2.11`](https://github.com/bacsystem/skills/releases/tag/v0.2.11) | 2026-10-17 | `pr-review`: modo corrección por ID, revisión de código propio con una comprobación independiente, criterios «reproducido / según la PR», veredicto en la primera línea y nuevas referencias (tipo y mock con la misma suposición, ajuste que no llega a todos los servicios) |
| [`v0.2.9`](https://github.com/bacsystem/skills/releases/tag/v0.2.9) | 2026-10-03 | `pr-review`: eje de corrección, criterios del issue, re-revisión con IDs estables, tests que discriminan, complejidad cognitiva, catálogo de code smells y referencia de producción |
| [`v0.2.8`](https://github.com/bacsystem/skills/releases/tag/v0.2.8) | 2026-09-08 | Skill `pr-review` (Clean Code, SOLID, DRY y buenas prácticas) con `--es`/`--en` y `--comment` |
| [`v0.2.7`](https://github.com/bacsystem/skills/releases/tag/v0.2.7) | 2026-07-04 | Base del PR según exista `develop`; tag solo en merges a `main` |
| [`v0.2.6`](https://github.com/bacsystem/skills/releases/tag/v0.2.6) | 2026-06-05 | Tabla de Skills sin columna «Versión» |
| [`v0.2.5`](https://github.com/bacsystem/skills/releases/tag/v0.2.5) | 2026-06-05 | Limpieza de badges inestables en el README |
| [`v0.2.4`](https://github.com/bacsystem/skills/releases/tag/v0.2.4) | 2026-06-05 | Tablas de Skills y Versiones, badges y licencia MIT |
| [`v0.2.3`](https://github.com/bacsystem/skills/releases/tag/v0.2.3) | 2026-06-05 | Script `next-version.sh` (bump SemVer) + primer runner de tests |
| [`v0.2.2`](https://github.com/bacsystem/skills/releases/tag/v0.2.2) | 2026-06-05 | Paso «Verify», SemVer `0.x`, resolución de remoto, `verify-commands.md` |
| [`v0.2.1`](https://github.com/bacsystem/skills/releases/tag/v0.2.1) | 2026-06-05 | Workflow `auto-tag` + READMEs + badges |
| [`v0.2.0`](https://github.com/bacsystem/skills/releases/tag/v0.2.0) | 2026-06-05 | Skill `git-flow` inicial |
| [`v0.1.0`](https://github.com/bacsystem/skills/releases/tag/v0.1.0) | 2026-06-05 | Estructura inicial del repositorio |

## Contribuir

- Sigue [Semantic Versioning](https://semver.org/lang/es/) para las versiones.
- Documenta cada cambio relevante en el [CHANGELOG](./CHANGELOG.md).
- La puerta de revisión de cada PR es [`/pr-review`](./pr-review), con su informe publicado como comentario en el PR. CodeRabbit es una ayuda cuando hay cupo, no un requisito: llega al límite de revisiones gratis y entonces no revisa.
- Cada retrospectiva ([`retro`](./retro)) abre un solo PR a este repo con todas sus mejoras genéricas para agentes y skills, en vez de uno por mejora.

## Licencia

[MIT](./LICENSE) © Christian Bacilio

Parte de las reglas de `pr-review` (la lista *Often mis-flagged* de
`references/code-smells.md` y varias entradas de
`references/production-readiness.md`), de `git-flow` y de los agentes en `agents/` están adaptadas de
[affaan-m/ECC](https://github.com/affaan-m/ECC), MIT License, Copyright (c) 2026
Affaan Mustafa.
