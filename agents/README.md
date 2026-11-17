# agents

Agentes reutilizables para Claude Code y Gemini / Antigravity: un equipo completo (producto, arquitectura,
liderazgo técnico, desarrollo por tecnología, QA y DevOps) que trabaja sobre
cualquier repositorio. Los agentes son **genéricos**: todo lo propio de cada
proyecto lo leen de su archivo de contexto (`GEMINI.md`, `AGENTS.md` o `CLAUDE.md`).

## Agentes

| Agente | Rol | Modelo Claude | Equivalente Gemini |
|---|---|---|---|
| [`tech-lead`](./tech-lead.md) | Sesión principal: descompone issues, reparte sin solapes, revisa todo PR con `/pr-review`, pide al usuario las aprobaciones de merge, tag y despliegue | opus | gemini-pro / pro |
| [`architect`](./architect.md) | Revisión de impacto, modelo de datos, contrato de API, diseño para concurrencia, escalabilidad y tolerancia a fallos (capacidad, balanceador, timeouts, reintentos, circuit breaker, backpressure, prueba de carga), decisiones con trade-offs y ADR. No escribe código | opus | gemini-pro / pro |
| [`po`](./po.md) | Issues con historia de usuario, criterios verificables, invariantes, criterios de carga con números e INVEST; prioriza y acepta entregas. No escribe código | sonnet · esfuerzo medio | gemini-flash / flash |
| [`qa`](./qa.md) | Valida contra los criterios, ejecuta las verificaciones, diseña casos por riesgo (concurrencia real, carga, fallos) y reporta defectos reproducibles | sonnet · esfuerzo medio | gemini-flash / flash |
| [`devops`](./devops.md) | CI/CD, imágenes, entornos, despliegues reversibles, secretos, respaldos, observabilidad y carga | sonnet · esfuerzo medio | gemini-flash / flash |
| [`java-dev`](./java-dev.md) | Backend Java 21 + Spring Boot + PostgreSQL | sonnet | gemini-flash / flash |
| [`go-dev`](./go-dev.md) | Backend Go (servicios HTTP, lotes, SQLite/PostgreSQL) | sonnet | gemini-flash / flash |
| [`nextjs-dev`](./nextjs-dev.md) | Frontend Next.js (App Router) + React + TypeScript | sonnet | gemini-flash / flash |

Los desarrolladores van por tecnología: un proyecto con dos backends en Java lanza
dos instancias de `java-dev` con nombres distintos (por ejemplo `backend-dev` y
`backend-dev-2`) y el tech-lead les asigna módulos distintos.

### Sumar más desarrolladores

No se crea ningún archivo nuevo: un desarrollador más es otra instancia del mismo
agente, con otro nombre.

1. En el archivo de contexto del proyecto (`GEMINI.md`, `AGENTS.md` o `CLAUDE.md`), agrega el nombre a la lista de roles y dale su
   parte en la propiedad de archivos (por ejemplo, `backend-dev-3` →
   `adapters/out-mail` y `adapters/out-pdf`; `go-dev-2` → `internal/carga`). Dos
   instancias nunca comparten módulo a la vez.
2. Pídele al tech-lead que lo lance: «lanza un `java-dev` llamado `backend-dev-3`
   para los módulos X e Y». El tech-lead le asigna su worktree y su rama, y le
   reserva el número de migración si la tarea lleva una.
3. Al terminar su tarea, el tech-lead lo cierra. Lanzar más no tiene costo fijo;
   cada instancia activa sí consume tokens, así que conviene tener solo las que
   trabajan en paralelo sobre módulos distintos.

El límite real no es el número de agentes sino cuánto trabajo independiente hay:
si dos tareas tocan el mismo módulo o dependen una de otra, un desarrollador más
no acelera, solo genera conflictos.

## Contrato con el proyecto

Cada agente empieza leyendo el archivo de contexto del repositorio (`GEMINI.md`, `AGENTS.md` o `CLAUDE.md`). Para que el equipo
funcione sin adivinar, ese archivo debe decir:

1. **Qué es el producto** y quiénes son sus usuarios y roles.
2. **Stack y comandos:** build, suite completa, lint y typecheck, con la señal de
   éxito de cada uno y las pruebas que son caras (cuándo se corren).
3. **Arquitectura:** módulos o paquetes, reglas de dependencia y el test que las
   verifica; flujos críticos que no se tocan sin entenderlos (incluidos los
   locks o transacciones intencionales).
   **Carga y despliegue:** carga objetivo (usuarios concurrentes, peticiones por
   segundo, p95), cuántas instancias corren y detrás de qué balanceador o proxy,
   y la herramienta y el lugar de las pruebas de carga. Sin estos datos, el
   architect, el po y qa los preguntan en vez de inventarlos.
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

> [!TIP]
> **Compatibilidad dual:** Puedes crear un enlace simbólico en tus proyectos (`ln -s CLAUDE.md GEMINI.md`) o utilizar el archivo neutral `AGENTS.md`. De esta forma, tanto Claude Code como Gemini / Antigravity leerán exactamente el mismo contrato.

Si a un agente le falta uno de estos datos, lo pregunta en vez de inventarlo. Si
el archivo de contexto contradice al agente, manda el del proyecto.

## Personalizar en un proyecto

Un agente en `.claude/agents/<nombre>.md` o `.agents/<nombre>.md` del proyecto **reemplaza por completo**
al global del mismo nombre (no hay herencia). Úsalo solo si el rol necesita algo
que no cabe en el contexto general; lo normal es dejar el global y documentar el
proyecto.

## Instalación

Los agentes de usuario se pueden instalar para **Claude Code** (`~/.claude/agents/`), para **Gemini / Antigravity** (`~/.gemini/agents/`), o para **ambos**. Para que sigan a este
repositorio sin copiarlos, los scripts de instalación enlazan la carpeta automáticamente.

**macOS / Linux** (enlace simbólico):

```bash
# Instala para ambos asistentes (por defecto)
./scripts/instalar-agentes.sh --all

# O específicamente para uno de ellos:
./scripts/instalar-agentes.sh --claude
./scripts/instalar-agentes.sh --gemini
```

**Windows** (junction; no requiere modo desarrollador ni administrador):

```powershell
# Instala para ambos asistentes
powershell -ExecutionPolicy Bypass -File .\scripts\instalar-agentes.ps1 -Target all

# O específicamente para uno de ellos:
powershell -ExecutionPolicy Bypass -File .\scripts\instalar-agentes.ps1 -Target claude
powershell -ExecutionPolicy Bypass -File .\scripts\instalar-agentes.ps1 -Target gemini
```

Si el destino ya existe y no es este enlace, el script lo renombra a
`<destino>.respaldo-<fecha>` antes de enlazar (no se borra nada). Abre una sesión nueva de Claude Code o Gemini/Antigravity después de enlazar. Para actualizar, basta con hacer `git pull` en este repositorio.

## Arrancar el equipo

- **En Claude Code:**
  ```bash
  claude --agent tech-lead
  ```
  o fíjalo en `.claude/settings.json` del proyecto con `"agent": "tech-lead"`.

- **En Gemini / Antigravity:**
  Carga el rol del `tech-lead` al inicio de la sesión o invócalo a través de los subagentes configurados.

Los demás roles los lanza el tech-lead como teammates / subagentes; cada desarrollador en
paralelo trabaja en su propio worktree.

## Requisitos

- El ciclo de revisión usa el skill [`pr-review`](../pr-review) y el de entrega el
  skill [`git-flow`](../git-flow).
- En Claude Code, los teammates requieren `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. En Gemini / Antigravity, se ejecutan mediante subagentes nativos o multi-agente.
