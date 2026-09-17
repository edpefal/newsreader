## REMOVED Requirements

### Requirement: Límite semanal gratis de resumen diario por usuario
**Reason**: La elegibilidad gratis de `daily-summaries` deja de ser un cupo consumible a demanda y pasa a ser automática y fija (usuarios sin suscripción son elegibles únicamente los lunes, ver capability `daily-summaries`, requirement "Elegibilidad: suscripción activa o lunes sin suscripción"). El día de la semana ya es la única señal necesaria para determinar elegibilidad — no hace falta un contador persistido aparte, porque el propio calendario resetea la elegibilidad cada semana y la regla existente de "una generación por día" ya evita una segunda generación el mismo lunes.
**Migration**: Se elimina la tabla `daily_summary_free_usage` y su sincronización. No hay datos de usuario que migrar (el contador no tenía valor fuera de la semana en curso).

### Requirement: Reset semanal del límite gratis de resumen diario
**Reason**: Consecuencia directa de eliminar el contador semanal (ver Requirement "Límite semanal gratis de resumen diario por usuario" arriba) — sin contador, no hay nada que resetear.
**Migration**: Ninguna.

### Requirement: Chequeo e incremento atómicos del límite semanal gratis
**Reason**: Consecuencia directa de eliminar el contador semanal — sin contador, no hay nada que chequear ni incrementar atómicamente. La elegibilidad (día de la semana) se puede evaluar sin necesidad de atomicidad, porque no hay una operación de "consumir" que dos corridas concurrentes puedan disputarse.
**Migration**: Ninguna.

### Requirement: Consulta de estado del cupo gratis semanal
**Reason**: Sin generación manual ni cupo consumible, no hay ningún estado de cupo que el cliente necesite consultar.
**Migration**: Se elimina el endpoint/campo de consulta correspondiente y el indicador de UI que lo mostraba (ver capability `daily-summaries`, requirement removido "Indicador de cupo gratis antes de generar").
