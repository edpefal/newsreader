## Why

Hoy, para generar un nuevo build de iOS en Codemagic (workflow `ios-testflight`, que sube a TestFlight) hay que entrar al dashboard de Codemagic manualmente, o llamar a su API REST a mano con `curl` pegando el token de sesión en la terminal — lo que ya pasó en esta sesión y expuso el token en texto plano. Un GitHub Action disparable a mano (`workflow_dispatch`) permite lanzar el mismo build desde la pestaña Actions del repo, con el token guardado como secret de GitHub (nunca visible en logs ni en el chat).

## What Changes

- Se agrega un workflow de GitHub Actions (`.github/workflows/codemagic-trigger.yml`) que **solo** se dispara manualmente vía `workflow_dispatch` (nunca en push/PR).
- El workflow acepta como input la rama a buildear (default `main`) y llama a la API REST de Codemagic (`POST https://api.codemagic.io/builds`) para arrancar el workflow `ios-testflight` sobre la app `Reevo` (`appId` fijo, no sensible).
- El token de autenticación (`x-auth-token`) se lee de un secret de GitHub llamado `CODEMAGIC_API_TOKEN`, que hay que configurar una sola vez en la configuración del repo (Settings → Secrets and variables → Actions). Este change documenta el paso pero no puede automatizarlo si el secret ya existe con el valor correcto.
- El job falla explícitamente (con mensaje claro) si Codemagic responde con un error, en vez de terminar en verde silenciosamente.

## Capabilities

### New Capabilities

- `codemagic-manual-trigger`: dispara builds de Codemagic desde un GitHub Action manual, sin exponer el token de API en logs ni requerir acceso directo al dashboard de Codemagic.

### Modified Capabilities

(ninguna)

## Impact

- Nuevo archivo `.github/workflows/codemagic-trigger.yml`.
- Requiere un secret de repo `CODEMAGIC_API_TOKEN` en GitHub (configuración manual, fuera del código).
- Sin impacto en `codemagic.yaml` (el workflow `ios-testflight` ya definido ahí no cambia), en la app Flutter, ni en el pipeline `analyze-and-test` existente.
