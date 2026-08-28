## Context

Ver `proposal.md` para la motivación. Este documento cubre cómo se implementa reusando la infraestructura ya existente de `daily-summaries` (`SummaryGenerator`, `check_and_record_ai_usage`, `entitlement.ts`, `language.ts`) sin duplicarla, y cómo se suma la pieza nueva (extracción + enriquecimiento de menciones).

## Goals / Non-Goals

**Goals:**
- Reusar el mecanismo de cuota/entitlement/idioma ya validado en prod, sin reimplementarlo.
- Aislar el enriquecimiento de menciones detrás de una abstracción reemplazable (`MentionEnricher`), consistente con la regla de abstracciones del proyecto.
- Mantener el resumen de artículo y el enriquecimiento de menciones como preocupaciones separadas (dominios de falla distintos, cuotas distintas).

**Non-Goals:**
- Enriquecer menciones de "productos" (fuera de scope, ver proposal.md).
- Ofrecer un flujo de "regenerar" el resumen de un artículo ya generado.
- Cachear/proxear resultados de Google Books/iTunes del lado del servidor (el proxy solo reenvía, no persiste ni cachea).

## Decisions

### Dos Edge Functions separadas: `summarize-article` y `enrich-mentions`

`summarize-article` es la única que habla con Gemini y con `check_and_record_ai_usage`; extiende el patrón de `summarize-articles` (mismo `entitlement.ts`, mismo `language.ts`) pero con un prompt propio (un solo artículo, no agrupado por fuente) y un `responseSchema` de Gemini que fuerza JSON: `{ summary: string, mentions: [{ type: "book"|"podcast"|"music", name: string }] }`. Alternativa descartada: extender `summarize-articles` para aceptar también un solo artículo — se descartó porque mezclaría dos prompts/formatos de salida muy distintos en la misma función y complicaría el parseo de la respuesta.

`enrich-mentions` es un proxy fino, sin estado, sin dependencia de Gemini: recibe `{ mentions: [{ type, name }] }` y devuelve `{ mentions: [{ type, name, imageUrl?, link? }] }`, resolviendo cada una contra Google Books (books) o iTunes Search (podcast/music) del lado del servidor. Sigue el mismo esquema de auth (Bearer del usuario) que las demás funciones, pero NO llama a `check_and_record_ai_usage` (no consume presupuesto de IA) ni requiere el `responseSchema`/parseo de Gemini.

### `MentionEnricher` como abstracción cliente, no interfaz por tipo

Se expone en `core/ai/mention_enricher.dart` como:

```dart
enum MentionType { book, podcast, music }

typedef RawMention = ({MentionType type, String name});
typedef EnrichedMention = ({
  MentionType type,
  String name,
  String? imageUrl,
  String? link,
});

abstract class MentionEnricher {
  Future<List<EnrichedMention>> enrich(List<RawMention> mentions);
}
```

Una única implementación concreta (`RemoteMentionEnricher`) llama a `enrich-mentions` con la lista completa (una sola request, no N requests por mención). El ruteo interno por tipo (libro → Google Books, podcast/música → iTunes Search) vive en el backend de `enrich-mentions`, no en el cliente — así sumar un proveedor nuevo (ej. Spotify) o cambiar cuál proveedor resuelve música es un cambio de backend + reglas internas de esa función, sin tocar la app ni la interfaz `MentionEnricher`. Alternativa descartada: interfaz por tipo (`BookEnricher`, `AudioEnricher`) — se descartó en la conversación de exploración por preferencia explícita del usuario hacia una interfaz genérica única.

### Persistencia: nuevo modelo Hive `ArticleSummaryModel` (typeId 3)

Nueva entidad `ArticleSummary` (`core/domain/entities/article_summary.dart`): `articleId`, `summary`, `mentions: List<EnrichedMention>`, `createdAt`. Se persiste con `@HiveType(typeId: 3)` (siguiente id libre; 0=NewsSourceModel, 1=ArticleModel, 2=DailySummaryModel), en una box nueva vía un datasource nuevo (`ArticleSummaryLocalDataSource`, análogo a `SummaryLocalDataSource`), expuesto por un `ArticleSummaryRepository` propio del feature. Las menciones se guardan embebidas como `List<Map>` (mismo patrón que `sourceBlocks` en `DailySummaryModel`), no como entidad Hive aparte — no necesitan existir independientes del resumen que las originó.

Clave primaria: `articleId` (no hay días ni agrupación — un resumen por artículo, `get(articleId)` / `save(summary)`).

### Flujo end-to-end

```
ReaderScreen (botón AppBar)
  → ArticleSummaryCubit
      1. lookup local: ArticleSummaryRepository.getByArticleId(id)
         → si existe: mostrar directo (sin red)
         → si no existe:
      2. GenerateArticleSummary (usecase)
           → SummarizeArticle (nueva impl. de un generator dedicado a
             artículo único, o extensión de la interfaz existente
             `SummaryGenerator` con un método nuevo `summarizeArticle`)
           → POST summarize-article → { summary, mentions (raw) }
      3. MentionEnricher.enrich(rawMentions)
           → POST enrich-mentions → mentions enriquecidas
      4. persistir ArticleSummary completo (resumen + menciones ya
         enriquecidas) vía ArticleSummaryRepository.save(...)
      5. emitir estado con el resultado → bottom sheet
```

El enriquecimiento (paso 3) se ejecuta siempre antes de persistir — no se persiste un resumen "sin enriquecer" a la espera de un enriquecimiento posterior. Si `enrich-mentions` falla completo (no una mención puntual, sino la request entera), el sistema persiste igual el resumen con las menciones en su forma cruda (sin imagen/link, tratadas igual que "sin match" según la spec de `article-mentions`), para no perder el resumen generado por una falla de un servicio no relacionado a Gemini.

## Risks / Trade-offs

- [Riesgo] Mezclar `summary` + `mentions` en una sola respuesta de Gemini con `responseSchema` puede ser menos confiable que un texto libre (como hace `summarize-articles` hoy) → Mitigación: Gemini 3.7 flash soporta `responseSchema` con `application/json` de forma nativa; se valida el shape recibido y se cae a `generationFailed` si no matchea, igual que ya hace `GeminiSummaryGenerator` hoy con la ausencia de `summary`.
- [Riesgo] `enrich-mentions` sin cache puede pegarle repetidas veces a Google Books/iTunes por la misma mención mencionada en distintos artículos → Mitigación: aceptado para esta versión (no-goal); el resultado enriquecido igual se persiste por artículo, así que solo pega una vez por artículo, no en cada apertura.
- [Riesgo] Nombres de menciones ambiguos (ej. una canción y una película con el mismo nombre) pueden matchear mal en Google Books/iTunes Search → Mitigación: aceptado, coherente con el requirement de mostrar "sin match" cuando el proveedor no encuentra nada — un match incorrecto es un problema de calidad de búsqueda de los proveedores externos, no bloqueante para esta versión.

## Migration Plan

No hay migración de datos: `ArticleSummaryModel` es una box nueva, no toca `ArticleModel` ni `DailySummaryModel`. Deploy: registrar el nuevo Hive TypeAdapter (`build_runner`), abrir la nueva box en `main.dart` junto a las existentes, desplegar las dos Edge Functions nuevas con `supabase functions deploy`, y agregar `GEMINI_API_KEY` (ya existe como secret compartido) sin secrets nuevos — Google Books/iTunes Search no requieren key.
