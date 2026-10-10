## 1. Cambio de modelo

- [x] 1.1 `summarize-article/index.ts`: `GEMINI_MODEL = "gemini-3.8-flash"`
- [x] 1.2 `generate-daily-summaries/index.ts`: `GEMINI_MODEL = "gemini-3.8-flash"`
- [x] 1.3 Correr `deno test --allow-env` en ambas funciones

## 2. Despliegue y verificación

- [x] 2.1 Confirmar con el usuario los proyectos de destino (`reevo-dev` y `reevo`)
- [x] 2.2 Desplegar `summarize-article` y `generate-daily-summaries` a `reevo-dev` (`--project-ref xgwnxhpdcrghrtdbrmpn`)
- [x] 2.3 Verificar en dev una llamada real de cada función (JSON estructurado de `summarize-article`, texto de `generate-daily-summaries`) y revisar logs sin errores de Gemini — omitida por decisión del usuario (2026-10-10)
- [x] 2.4 Desplegar ambas funciones a `reevo` (prod)
- [x] 2.5 Revisar en prod los logs de las dos funciones tras el despliegue — no revisado vía MCP (sin acceso a la tabla de logs); pendiente de revisión manual en el dashboard
