# agents

Agentes reutilizables para Claude Code: un equipo completo (producto, arquitectura,
liderazgo técnico, desarrollo por tecnología, QA y DevOps) que trabaja sobre
cualquier repositorio. Los agentes son **genéricos**: todo lo propio de cada
proyecto lo leen de su `CLAUDE.md`.

## Agentes

| Agente | Rol | Modelo |
|---|---|---|
| [`tech-lead`](./tech-lead.md) | Sesión principal: descompone issues, reparte sin solapes, revisa todo PR con `/pr-review`, pide al usuario las aprobaciones de merge, tag y despliegue | opus |
| [`architect`](./architect.md) | Revisión de impacto, modelo de datos, contrato de API, decisiones con trade-offs y ADR. No escribe código | opus |
| [`po`](./po.md) | Issues con historia de usuario, criterios verificables e INVEST; prioriza y acepta entregas. No escribe código | sonnet |
| [`qa`](./qa.md) | Valida contra los criterios, ejecuta las verificaciones, diseña casos por riesgo y reporta defectos reproducibles | sonnet |
| [`devops`](./devops.md) | CI/CD, imágenes, entornos, despliegues reversibles, secretos, respaldos, observabilidad y carga | sonnet |
| [`java-dev`](./java-dev.md) | Backend Java 21 + Spring Boot + PostgreSQL | sonnet |
| [`go-dev`](./go-dev.md) | Backend Go (servicios HTTP, lotes, SQLite/PostgreSQL) | sonnet |
| [`nextjs-dev`](./nextjs-dev.md) | Frontend Next.js (App Router) + React + TypeScript | sonnet |

Los desarrolladores van por tecnología: un proyecto con dos backends en Java lanza
dos instancias de `java-dev` con nombres distintos (por ejemplo `backend-dev` y
`backend-dev-2`) y el tech-lead les asigna módulos distintos.

## Contrato con el proyecto

Cada agente empieza leyendo el `CLAUDE.md` del repositorio. Para que el equipo
funcione sin adivinar, ese archivo debe decir:

1. **Qué es el producto** y quiénes son sus usuarios y roles.
2. **Stack y comandos:** build, suite completa, lint y typecheck, con la señal de
   éxito de cada uno y las pruebas que son caras (cuándo se corren).
3. **Arquitectura:** módulos o paquetes, reglas de dependencia y el test que las
   verifica; flujos críticos que no se tocan sin entenderlos.
4. **Propiedad de archivos por rol:** qué carpetas son de cada desarrollador, de
   devops y de quién es la configuración compartida.
5. **Ramas y PR:** rama base, ramas protegidas, método de merge, uso de stacks y
   cuándo se cierran los issues.
6. **Migraciones:** herramienta, carpeta y quién reserva los números.
7. **Docs y ADR:** dónde viven y si se versionan.
8. **Secretos:** nombres de las variables que nunca se publican y el procedimiento
   de rotación de las que cifran datos.
9. **Publicación:** si el repo es público y qué no puede aparecer en issues o PR.
10. **Memoria del proyecto** (opcional): dónde se consulta y cómo se registra cada
    sesión.

Si a un agente le falta uno de estos datos, lo pregunta en vez de inventarlo. Si
el `CLAUDE.md` contradice al agente, manda el `CLAUDE.md`.

## Personalizar en un proyecto

Un agente en `.claude/agents/<nombre>.md` del proyecto **reemplaza por completo**
al global del mismo nombre (no hay herencia). Úsalo solo si el rol necesita algo
que no cabe en el `CLAUDE.md`; lo normal es dejar el global y documentar el
proyecto.

## Instalación

Los agentes de usuario viven en `~/.claude/agents/`. Para que sigan a este
repositorio sin copiarlos, el script de instalación enlaza la carpeta. Se
ejecuta desde cualquier carpeta; si `~/.claude/agents` ya existe y no es este
enlace, la renombra a `agents.respaldo-<fecha>` antes de enlazar (no borra
nada), y si ya está enlazada no hace nada.

**macOS / Linux** (enlace simbólico):

```bash
/ruta/al/repo/skills/scripts/instalar-agentes.sh
```

**Windows** (junction; no requiere administrador ni modo desarrollador), desde
PowerShell o cmd:

```powershell
powershell -ExecutionPolicy Bypass -File C:\ruta\al\repo\skills\scripts\instalar-agentes.ps1
```

En Git Bash no uses `ln -s`: sin el modo desarrollador copia la carpeta en vez
de enlazarla, y la copia deja de seguir al repositorio. Por eso el script de
Bash se niega a correr ahí y remite al de PowerShell.

Ambos aceptan un destino distinto (`instalar-agentes.sh <destino>`,
`instalar-agentes.ps1 -Destino <ruta>`). Abre una sesión nueva de Claude Code
después de enlazar: los agentes se cargan al iniciar. Para actualizar, basta
`git pull` en el repositorio.

## Requisitos

- El ciclo de revisión usa el skill [`pr-review`](../pr-review) y el de entrega el
  skill [`git-flow`](../git-flow).
- Los teammates (mensajes entre agentes, apagado al terminar) requieren los
  equipos de agentes de Claude Code (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`).
