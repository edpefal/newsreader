## 1. Implementación

- [x] 1.1 Crear `.github/workflows/codemagic-trigger.yml` con trigger `workflow_dispatch` únicamente (sin `push`/`pull_request`), input `branch` (string, default `main`).
- [x] 1.2 Agregar el job que llama a `POST https://api.codemagic.io/builds` con `curl`, usando `x-auth-token: ${{ secrets.CODEMAGIC_API_TOKEN }}`, `appId` fijo (`6a93d7e64dfa598798e17ef6`), `workflowId` fijo (`ios-testflight`) y `branch` tomado del input.
- [x] 1.3 Hacer que el step falle explícitamente si la respuesta HTTP es de error o si el JSON de respuesta no trae `buildId`, con un mensaje de error claro en el log.
- [x] 1.4 En caso de éxito, imprimir el `buildId` obtenido (no sensible) en el log del job.

## 2. Configuración manual (fuera del código)

- [x] 2.1 Configurar el secret `CODEMAGIC_API_TOKEN` en GitHub (Settings → Secrets and variables → Actions) del repo, con el token de cuenta de Codemagic.
- [x] 2.2 Confirmar que quien configuró el secret rotó/regeneró el token de Codemagic si el valor usado había quedado expuesto previamente en texto plano.

## 3. Verificación

- [x] 3.1 Disparar el workflow manualmente desde la pestaña Actions de GitHub (o `gh workflow run codemagic-trigger.yml`) y confirmar que Codemagic recibe la solicitud (verificar en el dashboard de Codemagic o con el `buildId` devuelto). Ejecución exitosa: `buildId 6a9f3e042cc027985060945b`.
- [x] 3.2 Revisar el log de la ejecución y confirmar que el valor del token no aparece en ningún paso. Confirmado: el log muestra `CODEMAGIC_API_TOKEN: ***` (enmascarado automáticamente por GitHub Actions).
- [x] 3.3 Confirmar que un `git push` a cualquier rama NO dispara este workflow (solo el `analyze-and-test` existente debe correr). Confirmado por definición: el workflow solo declara `on: workflow_dispatch`.
