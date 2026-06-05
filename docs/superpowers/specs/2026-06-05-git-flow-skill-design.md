# Diseño: skill `git-flow`

**Fecha:** 2026-06-05
**Estado:** Aprobado

## Propósito

Llevar los cambios desde el código hasta el PR en un solo flujo guiado, siguiendo
convenciones consistentes: Conventional Commits, ramas `tipo/descripcion`,
versionado semántico automático y plantilla de PR.

La skill es de tipo **flexible**: es un flujo guiado donde el usuario puede
intervenir en cada paso. No es una automatización ciega.

## Estructura en el repo

```
git-flow/
├── SKILL.md
└── references/
    └── pr-template.md
```

## Flujo (en orden)

1. **Detectar contexto**
   - Rama actual, cambios staged/unstaged (`git status`, `git diff`).
   - Qué archivos de versión existen: `package.json`, `VERSION`, `CHANGELOG.md`, `README.md`.
   - Si `gh` CLI está disponible y autenticado.
   - Si no hay cambios, detener con mensaje claro.

2. **Crear rama**
   - Si la rama actual es `main`/`master`: inferir el tipo del cambio y crear
     `tipo/descripcion` (ej. `feat/login-form`).
   - Si ya se está en una rama de trabajo: respetarla.

3. **Code review**
   - Revisar el diff (bugs, convenciones, simplificaciones) **antes** de commitear.
   - Mostrar hallazgos al usuario. Continuar tras su visto bueno.

4. **Clasificar cambio y calcular versión**
   - Deducir el tipo Conventional Commit (`feat`, `fix`, `docs`, `chore`, etc.).
   - Calcular bump SemVer: `feat` → minor, `fix` → patch, `BREAKING CHANGE` → major.

5. **Validar y actualizar documentos**
   - Detectar y **mostrar al usuario** qué archivos actualizar antes del `add`:
     - Nueva entrada en `CHANGELOG.md` (formato Keep a Changelog).
     - Versión en `package.json` / `VERSION` si existen.
     - `README.md` si el cambio lo amerita.
   - Aplicar las actualizaciones tras confirmación.

6. **`add` + commit**
   - Hacer `git add` de los archivos relevantes.
   - Commit con mensaje Conventional Commit en **inglés**.

7. **Tag**
   - Crear tag `vX.Y.Z` en git con la versión calculada.

8. **Push + PR (con confirmación)**
   - Hacer push de la rama.
   - Generar la descripción del PR con `references/pr-template.md`.
   - **Mostrar la descripción y preguntar antes de crear el PR.**
   - Crear el PR con `gh` solo si el usuario confirma.

## Decisiones

| Aspecto | Decisión |
|---|---|
| Nombre de rama | `tipo/descripcion` (basado en Conventional Commits) |
| Versionado | SemVer automático por tipo de commit |
| Fuente de versión | Detectar/validar archivos existentes antes del `add` |
| Idioma | Commits, PR y plantilla en inglés |
| PR | Vía `gh` CLI (GitHub), **con confirmación previa** |
| Code review | Incluido antes del commit, con visto bueno del usuario |

## Plantilla de PR (`references/pr-template.md`)

Debe incluir, en inglés:
- Título (Conventional Commit).
- Resumen del cambio.
- Tipo de cambio (feat/fix/docs/etc.).
- Cambios principales (lista).
- Versión / SemVer bump.
- Checklist (tests, docs, changelog actualizado).

## Fuera de alcance (por ahora)

- Integración con Jira u otros issue trackers.
- Soporte para convenciones de rama con ticket ID.
- Releases automáticos / publicación de paquetes.
