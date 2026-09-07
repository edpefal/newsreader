## Context

Codemagic ya tiene el workflow `ios-testflight` definido en `codemagic.yaml`, con `triggering: events: []` (no se dispara automáticamente por git push). Codemagic expone una API REST (`POST https://api.codemagic.io/builds`) que acepta `appId`, `workflowId` y `branch`, autenticada con un header `x-auth-token` con un token de cuenta (no de proyecto). El `appId` de este repo en Codemagic (`Reevo`) es `6a93d7e64dfa598798e17ef6` — no es sensible (no da acceso por sí solo sin el token), así que puede vivir en el workflow YAML sin ser secret. Ver proposal.md - Why para el motivo de mover esto a un GitHub Action en vez de `curl` manual.

## Goals / Non-Goals

**Goals:**
- Que cualquier colaborador con permisos de escritura pueda disparar el build de Codemagic desde GitHub sin tocar una terminal ni el dashboard de Codemagic.
- Que el token de Codemagic viva únicamente como GitHub Actions secret, nunca en el código ni en logs.

**Non-Goals:**
- No se automatiza la generación/rotación del token de Codemagic (eso sigue siendo manual, en el dashboard de Codemagic).
- No se cambia `codemagic.yaml` ni el comportamiento del workflow `ios-testflight` en sí — este change solo agrega una forma alternativa de dispararlo.
- No se agrega ningún trigger automático (push, PR, schedule) para este nuevo workflow — es explícitamente manual por decisión del usuario.

## Decisions

**Un solo job de `curl` en el GitHub Action, sin acción de terceros (`marketplace`)** — se descarta usar una action de marketplace para "llamar una API REST genérica" porque agregaría una dependencia externa (con su propio riesgo de supply chain) para algo que un `curl` de una línea resuelve sin fricción, dentro del allowlist de herramientas ya disponibles en el runner `ubuntu-latest` por defecto.

**Input `branch` con default `main`, sin input para `workflowId`** — el `workflowId` (`ios-testflight`) queda fijo en el YAML del Action en vez de ser un input, porque hoy solo existe ese workflow en `codemagic.yaml`; si en el futuro se agregan más workflows de Codemagic, se puede convertir en un `choice` input recién en ese momento (YAGNI).

**Verificación de la respuesta de la API con `curl -f` + inspección del `buildId`** — se usa `curl --fail-with-body` (o equivalente) para que un código de error HTTP haga fallar el step inmediatamente, y además se valida que la respuesta JSON tenga un campo `buildId` no vacío antes de considerar el job exitoso — cubre tanto errores HTTP explícitos como una respuesta 200 con un payload inesperado.

**El token nunca se interpola en un `echo`/`print` ni se pasa como argumento de línea de comandos visible en el log** — se pasa a `curl` vía `-H "x-auth-token: $CODEMAGIC_API_TOKEN"` leyendo la variable de entorno del secret; GitHub Actions ya enmascara automáticamente el valor de cualquier secret que aparezca en el log (lo reemplaza por `***`), pero además se evita cualquier comando que lo imprima explícitamente (ej. `env`, `set -x` sin excluir esa variable).

## Risks / Trade-offs

- [El secret `CODEMAGIC_API_TOKEN` da acceso de cuenta completo en Codemagic (todos los proyectos), no solo a este repo] → Aceptado: es la única granularidad que ofrece la API de Codemagic hoy. Mitigación: rotar el token si se sospecha de una exposición (como ya ocurrió con el usado manualmente en esta sesión), y limitar quién tiene permiso de repo para disparar `workflow_dispatch` (ya gobernado por los permisos de GitHub del repo).
- [Cualquier colaborador con push access puede disparar builds de TestFlight, consumiendo minutos de build de Codemagic] → Aceptado como parte del diseño (es justamente el objetivo: dar autoservicio); si se vuelve un problema, se puede restringir con un `environment` de GitHub que requiera aprobación antes de correr el job.

## Migration Plan

1. Agregar `.github/workflows/codemagic-trigger.yml` (nuevo archivo, no reemplaza nada existente).
2. Configurar el secret `CODEMAGIC_API_TOKEN` en Settings → Secrets and variables → Actions del repo (paso manual, fuera de este PR — se documenta en tasks.md).
3. Verificar con un disparo manual real desde la pestaña Actions.

No hay rollback especial: si el workflow no sirve, se borra el archivo YAML sin ningún efecto colateral sobre `codemagic.yaml` ni sobre otros workflows de CI.
