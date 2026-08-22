## Why

El resumen diario es la única feature de IA de la app, y su prompt (`supabase/functions/summarize-articles/index.ts`) tiene hardcodeado "Escribís siempre en español latinoamericano neutro, con tuteo" — sin importar el idioma que el usuario eligió para el resto de la app. Esto quedó así desde antes de que existiera el trabajo de i18n real (`add-i18n-infra-neutral-spanish`, `add-french-translations`, ambos ya archivados), que le agregó a Reevo soporte de inglés y francés en toda la UI. Hoy un usuario que lee la app en inglés o francés igual recibe el resumen diario en español, lo cual es inconsistente con el resto de la experiencia.

## What Changes

- El request que la app manda a `summarize-articles` pasa a incluir el locale activo del usuario (`en`, `es`, `fr` — los mismos que soporta `AppLocalizations`).
- El prompt server-side deja de tener el idioma de salida hardcodeado: se arma dinámicamente según el locale recibido, manteniendo la misma voz editorial (cercana, sin emojis, sin cambiar de tono según la fuente) en cualquiera de los 3 idiomas.
- Si el locale recibido no es uno de los 3 soportados (o falta), el backend cae a inglés como default seguro.

## Capabilities

### Modified Capabilities
- `daily-summaries`: el requirement de "voz consistente... en español latinoamericano neutro con tuteo" pasa a "en el idioma del locale activo del usuario, dentro de los 3 soportados por la app (en/es/fr), con la misma voz consistente en cualquiera de los 3".

## Impact

- **Cliente**: `core/ai/gemini_summary_generator.dart` (arma el request), posiblemente `features/summaries/domain/usecases/generate_daily_summary.dart` si necesita conocer el locale activo para pasarlo hacia abajo.
- **Backend**: `supabase/functions/summarize-articles/index.ts` (`buildPrompt` deja de hardcodear el idioma de salida).
- **Sin cambios de esquema**: no se persiste el locale en `daily_summaries` — el resumen ya generado no se re-traduce retroactivamente, solo las generaciones nuevas usan el locale activo al momento de generarse.
