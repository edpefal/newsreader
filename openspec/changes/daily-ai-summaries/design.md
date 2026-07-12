## Context

La app sigue Clean Architecture por feature (ver `CLAUDE.md`): cada feature tiene `domain/usecases/` y `presentation/` (Cubit/Bloc + screens), y ninguna librería de infraestructura se importa directo en `domain/`/`presentation/` — siempre a través de una abstracción en `core/`.

Persistencia local ya usa Hive CE con `typeId` reservados: `0` = `NewsSourceModel`, `1` = `ArticleModel`.

**Historial de la decisión de motor de IA (ver `proposal.md` para el resumen):** la v1 de este diseño usaba `flutter_gemma` (LLM on-device, MediaPipe/LiteRT-LM). Se probaron en dispositivo real tres modelos livianos sin éxito suficiente:
- Modelos Gemma (270M–1B): están "gated" en HuggingFace — exigen que cada usuario final tenga cuenta HF + token para descargar, inviable para una app consumer.
- SmolLM 135M (público, sin gating): calidad insuficiente — repetía párrafos completos y no respondía en español.
- Qwen 2.5 0.5B (público, sin gating, ~550MB): mejor que SmolLM pero seguía siendo notablemente peor que un LLM de nube.

Se migró a una arquitectura cloud: **Gemini (Google) vía un backend propio en Supabase Edge Functions**, que actúa de proxy. El código on-device (`flutter_gemma`, `flutter_gemma_mediapipe`, el bump de `IPHONEOS_DEPLOYMENT_TARGET` a 16.0, el bump de AGP/Kotlin de Android) se removió/revirtió por completo, salvo el bump de AGP/Gradle/Kotlin de Android que se dejó (es una mejora inocua recomendada igual por Flutter, sin relación con IA).

## Goals / Non-Goals

**Goals:**
- Generar un resumen de IA de los artículos del inbox del día actual, agrupado por fuente (un párrafo por feed).
- Persistir un resumen por día (upsert por fecha), listarlos y ver el detalle de cada uno.
- Mantener la separación de capas: ni `flutter_gemma` ni el cliente HTTP de Gemini se referencian fuera de su implementación concreta en `core/`.
- Nunca exponer la API key real de Gemini en el cliente distribuido.

**Non-Goals:**
- Protección anti-abuso robusta del endpoint (rate limiting por usuario, cuotas) — se apoya únicamente en que el anon key de Supabase identifica al proyecto; suficiente para v1 con expectativa de uso bajo.
- Resumir artículos leídos, archivados o favoritos, o de días distintos al actual.
- Regenerar o editar resúmenes de días pasados.
- Selección de modelo/proveedor por parte del usuario (se fija Gemini Flash en esta v1).

## Decisions

**Abstracción `SummaryGenerator` en `core/ai/`, implementada por `GeminiSummaryGenerator`**
La interfaz (`summarize(List<ArticleExcerpt>) → Future<String>`) no cambió al migrar de on-device a nube — solo se reemplazó la implementación concreta, sin tocar el resto del feature (`GenerateDailySummary`, `SummariesCubit`, pantallas). Esto valida la abstracción: aisló completamente al dominio/presentación del motor de IA elegido.
`GeminiSummaryGenerator` llama a la Supabase Edge Function vía `HttpClient` (se le agregó el método `post` a la interfaz existente, junto a `get`), envía `{articles: [{title, excerpt}]}` como JSON y parsea `{summary: string}` de la respuesta.
- Alternativa descartada: llamar a Gemini directo desde la app con su API key embebida — cualquiera puede extraer la key de un APK/IPA distribuido y usarla a costo del dueño de la cuenta.

**Backend: Supabase Edge Function (`supabase/functions/summarize-articles/`)**
Función Deno que recibe la lista de artículos, arma el prompt, llama a `generativelanguage.googleapis.com` con la API key de Gemini guardada como secret (`GEMINI_API_KEY`, nunca en el código), y devuelve `{summary}`. La app se autentica ante la función con el **anon key de Supabase** (pensado para ser público/embebido en clientes), nunca con la key de Gemini.
- Alternativa descartada: Cloudflare Workers — funcionalmente equivalente, se prefirió Supabase porque el usuario ya tenía cuenta ahí.
- Alternativa descartada: backend propio en un VPS/servidor tradicional — más operación (mantenimiento, escalado, HTTPS) para un caso de uso de un solo endpoint sin estado.

**Resumen por fuente, no un solo párrafo global**
`GenerateDailySummary` agrupa los artículos de hoy por `sourceName` (preservando el orden de aparición) e invoca `SummaryGenerator.summarize()` **una vez por fuente**. El nombre de la fuente se antepone en código (`"$sourceName\n$paragraph"`), nunca lo genera el modelo — evita que el LLM invente o mezcle nombres de feed.
- Alternativa descartada: un solo prompt con todos los artículos pidiéndole al modelo que organice y titule por feed — más rápido (una sola llamada) pero con riesgo real de que el modelo alucine el nombre del feed o mezcle contenido de fuentes distintas, dado el historial de calidad observado.
- Trade-off: N llamadas al backend (una por fuente con artículos hoy) en vez de una sola: más latencia total si hay muchas fuentes, aceptable dado que Gemini Flash responde en segundos.

**Prompt: título + excerpt únicamente**
Se mantiene de la v1 on-device: cabe cómodo en cualquier límite de contexto y evita prompts gigantes con HTML completo.
- Alternativa descartada: incluir `contentHtml` completo — innecesario ahora que no hay límite de contexto ajustado (~1024 tokens) como con los modelos chicos, pero se mantiene la decisión por simplicidad/costo (menos tokens = más barato).

**Entidad `DailySummary` con id = fecha (`yyyy-MM-dd`)**
Sin cambios respecto a la v1: permite que "sobrescribir el resumen de hoy" sea un simple `box.put(dateKey, summary)`.

**Nuevo `HiveModel` con `typeId: 2`**
Sin cambios respecto a la v1.

**Cubit en vez de Bloc**
Sin cambios respecto a la v1.

**Botón deshabilitado si no hay artículos de hoy**
Sin cambios respecto a la v1.

## Risks / Trade-offs

- **[Riesgo] Costo de la API de Gemini si el uso crece mucho** → Mitigación: Gemini Flash es muy barato por request (~1-2K tokens de prompt); a monitorear si la app escala a muchos usuarios activos.
- **[Riesgo] Endpoint sin rate limiting propio, solo protegido por el anon key de Supabase** → Mitigación: aceptado como Non-Goal de v1; si se detecta abuso, agregar rate limiting en la Edge Function o Row Level Security/Auth de Supabase.
- **[Riesgo] Falla de red o del backend/Gemini** → Mitigación: el Cubit expone un estado de error distinto al de "sin artículos", con mensaje explícito y posibilidad de reintentar (sin cambios respecto a v1).
- **[Riesgo] N llamadas al backend (una por fuente) aumentan latencia con muchas fuentes activas** → Mitigación: aceptado como trade-off por confiabilidad (ver Decisions); a revisar si se vuelve un problema de UX real.
- **[Riesgo] Dependencia de un servicio externo (Gemini) y de infraestructura propia (Supabase)** → Mitigación: aceptado — es el trade-off explícito de haber migrado de on-device a nube por calidad.

## Migration Plan

No aplica migración de datos existentes (entidad y box nuevos, no tocan `NewsSourceModel`/`ArticleModel`). Rollback de la parte cloud: eliminar la Edge Function de Supabase y el secret; en la app, `SummaryGenerator` es una interfaz — se podría reintroducir una implementación on-device o mockeada sin tocar el resto del feature.

## Open Questions

- Si conviene agregar rate limiting o autenticación de usuario real (no solo anon key) a la Edge Function si la app gana tracción.
- Si vale la pena paralelizar las N llamadas por fuente (`Future.wait`) en vez de secuenciales, para reducir la latencia total cuando hay varias fuentes con artículos hoy.
