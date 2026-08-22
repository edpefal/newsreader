## Why

Hoy generar el resumen diario no tiene ningún límite: el botón se llama literalmente "Regenerar resumen de hoy" y no hay cooldown, contador ni rate limit del lado del servidor — el único gate es tener una suscripción activa. Cada regeneración manda el contenido completo (no truncado) de todos los artículos del inbox de hoy a Gemini, sin ningún tope. Esto es relevante ahora porque además del resumen diario va a sumarse una segunda feature de IA más adelante (resumir un artículo individual + extraer menciones), y conviene resolver el control de costo de forma compartida antes de repetir el problema en cada feature nueva.

## What Changes

- Se agrega `AiUsagePolicy` en `core/` — abstracción compartida (mismo patrón que `ObservabilityClient`/`SubscriptionStatusProvider`) para leer el estado de uso de IA del usuario actual (palabras usadas hoy, límite, cuándo resetea). Un solo consumidor hoy (`SummariesCubit`), pensada para que una futura segunda feature de IA la reuse sin tocarla.
- El backend (`summarize-articles`) pasa a contar las palabras de **input** que va a mandarle a Gemini (título + contenido de cada artículo) y a rechazar la generación, sin invocar a Gemini, si eso llevaría el consumo del día del usuario por encima de **30,000 palabras de input**. El presupuesto es por usuario, se resetea diariamente, y solo cuenta lo que se manda a Gemini (no lo que Gemini responde).
- Nueva tabla en Postgres para llevar el consumo diario por usuario, con el incremento y el chequeo del tope resueltos de forma atómica del lado del servidor (nunca confiando en un conteo que mande el cliente).
- La pantalla de Resúmenes muestra un medidor visible del consumo del día ("6,300 / 30,000 palabras"), y el botón de generar se deshabilita al agotarse el presupuesto hasta el reset (corte duro, sin forma de pedir más ese mismo día).
- Antes de regenerar el resumen de hoy cuando la cantidad de artículos de hoy es la misma que la que ya tiene el resumen guardado (o sea, no llegó nada nuevo desde la última generación), el sistema pide confirmación en vez de regenerar directo — la fricción es solo para el caso de "gasto sin razón", no cuando hay artículos nuevos.

## Capabilities

### New Capabilities
- `ai-usage-budget`: presupuesto diario de palabras de input consumidas por features de IA, contado y aplicado del lado del servidor, con un medidor visible al usuario y reset diario.

### Modified Capabilities
- `daily-summaries`: la generación del resumen diario pasa a estar sujeta al presupuesto de `ai-usage-budget` (se rechaza sin invocar a la API de IA si excede el presupuesto), y a pedir confirmación antes de regenerar cuando el conteo de artículos de hoy no cambió desde la última generación guardada.

## Impact

- **Nuevo código cliente**: `core/ai_usage/ai_usage_policy.dart` (interfaz), `core/ai_usage/supabase_ai_usage_policy.dart` (implementación), registrada en `core/di/injection.dart`.
- **Nuevo `AppErrorCode`**: para distinguir "se agotó el presupuesto de IA por hoy" de otros errores de generación, localizado en los 3 idiomas soportados.
- **Backend**: nueva tabla de consumo diario + función de Postgres para chequeo-e-incremento atómico; `supabase/functions/summarize-articles/index.ts` pasa a contar palabras y consultar el presupuesto antes de llamar a Gemini.
- **Modificados**: `features/summaries/presentation/cubit/summaries_cubit.dart` (carga el estado de uso, expone la confirmación de "mismo conteo de artículos"), `features/summaries/presentation/screens/summaries_screen.dart` (medidor visible, diálogo de confirmación, botón deshabilitado al agotar presupuesto).
- **Sin cambios** en la lógica de selección de contenido por artículo (`contentHtml` completo vs `excerpt`) ni en el prompt editorial en sí (más allá de lo que ya toca el change `fix-daily-summary-locale`, independiente de este).
