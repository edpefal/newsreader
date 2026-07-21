## 1. Reescribir el prompt

- [x] 1.1 Reescribir `buildPrompt()` en `supabase/functions/summarize-articles/index.ts`: reemplazar las instrucciones factuales rígidas por una definición de voz (tono business-casual, ingenioso pero no cursi, español latinoamericano neutro con tuteo), manteniendo intacto el contrato de formato de salida (nombre de fuente en una línea, párrafo en la siguiente, línea en blanco entre fuentes).
- [x] 1.2 Agregar guías explícitas de calibración dentro del prompt: qué SÍ (gancho de apertura por bloque, alguna observación propia sin inventar datos) y qué NO (chistes forzados, exclamaciones en exceso, emojis, adaptar el tono según la fuente).
- [x] 1.3 Agregar 1-2 ejemplos de referencia (few-shot) dentro del prompt, en español neutro, mostrando el contraste entre un párrafo factual plano y uno con la voz deseada, para el mismo contenido de entrada.

## 2. Despliegue y verificación manual

- [x] 2.1 Desplegar `summarize-articles` (`supabase functions deploy summarize-articles`).
- [x] 2.2 Generar un resumen diario real (regenerar el de hoy) y verificar manualmente: la voz es consistente entre distintas fuentes (no se adapta al tono original de cada una), no hay emojis, no se siente forzado ni "cringe", y el formato (fuente + párrafo) se sigue viendo bien en `SummaryDetailScreen` sin cambios en el cliente. Verificado con curl (3 fuentes muy distintas: laboral, cripto, cocina) y en emulador Android con 13 fuentes reales del día — voz consistente tipo "amigo con onda", ganchos de apertura, sin emojis, tuteo correcto.
- [x] 2.3 Verificar con un día de muchas fuentes (similar al caso de 18 fuentes usado en el change anterior) que los bloques con más voz no empujan el resultado a cortarse por `maxOutputTokens` (8192). Verificado con 13 fuentes reales: el último bloque (Daily Stoic) termina en una oración completa, sin cortes.
- [x] 2.4 Si el tono no convence en la verificación manual, iterar las guías/ejemplos del prompt y volver a desplegar antes de dar el change por cerrado. No hizo falta iterar: el tono resultó consistente y natural en la primera pasada.
