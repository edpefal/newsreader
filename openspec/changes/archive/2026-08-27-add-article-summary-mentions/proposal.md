## Why

Hoy la única feature de IA de la app es el resumen diario del inbox completo (`daily-summaries`). No hay forma de pedir una síntesis de un artículo puntual, ni de descubrir de forma accionable los libros, podcasts o álbumes/canciones que ese artículo menciona — algo que ya identificamos como valioso (referencia Snipd/NotebookLM) y que hoy exige que el usuario lea el artículo entero y busque cada mención a mano.

## What Changes

- Nueva feature `features/article_summary` con un botón en el AppBar del `ReaderScreen` que dispara, on-demand, la generación de un resumen del artículo abierto más la lista de menciones a libros/podcasts/música detectadas en su contenido.
- Nueva Edge Function `summarize-article` (Gemini): recibe título+contenido de un artículo, devuelve `{ summary, mentions: [{ type, name }] }` crudo (sin enriquecer). Reusa el mismo entitlement check y el mismo presupuesto diario de palabras (`ai-usage-budget`) que `summarize-articles`.
- Nueva Edge Function `enrich-mentions`: proxy fino a Google Books (libros) y iTunes Search (podcasts/música); recibe la lista de menciones crudas y devuelve, por cada una, imagen de portada + link cuando encuentra match. No consume presupuesto de IA (no llama a Gemini).
- Nueva abstracción `MentionEnricher` en `core/` (análoga a `FeedParser`/`HttpClient`): oculta el proveedor real detrás de una interfaz genérica parametrizada por tipo de mención, para poder agregar proveedores nuevos (ej. Spotify) sin tocar domain/presentation.
- Persistencia local (Hive) del resultado por artículo, para no regenerar ni reconsumir cuota si el usuario vuelve a abrir el mismo artículo — se muestra lo guardado directamente.
- UI: bottom sheet con el texto del resumen y cards de menciones; una mención sin match enriquecido se muestra igual, como texto plano sin imagen ni link; tocar una mención enriquecida abre el link en el navegador del sistema (no en el `ArticleWebView` interno).
- Fuera de scope explícito: menciones de "productos" (no se encontró una API gratuita viable que resuelva nombre de producto en texto libre → imagen/link; se deja pendiente para una iteración futura).

## Capabilities

### New Capabilities
- `article-summaries`: generación on-demand de un resumen de un artículo individual (vía Gemini), gateado por el mismo entitlement pago de `daily-summaries`, persistido localmente para no regenerar.
- `article-mentions`: detección y enriquecimiento de menciones a libros/podcasts/música dentro de un artículo, incluyendo el comportamiento cuando el enriquecimiento no encuentra match y cómo se abren los links.

### Modified Capabilities
(ninguna — `ai-usage-budget` y `subscription-entitlements` ya están definidas de forma genérica para "cualquier feature de IA"/"otras capabilities" y se reusan tal cual, sin cambios de requirement)

## Impact

- **Backend**: 2 Edge Functions nuevas (`summarize-article`, `enrich-mentions`) en `supabase/functions/`; ambas dependen de la sesión autenticada y (la primera) del RPC `check_and_record_ai_usage` ya existente.
- **App**: nuevo feature `features/article_summary/` (domain/usecases + presentation: cubit/bloc, bottom sheet, widgets de mention card); nueva entidad de dominio para el resultado persistido y sus menciones; nuevo datasource/repositorio Hive; nueva abstracción `core/ai/mention_enricher.dart` con implementaciones concretas para Google Books e iTunes Search en `core/data/` (o `core/ai/`, a definir en design.md).
- **i18n**: nuevas claves en los `.arb` para el botón, el bottom sheet y estados de error.
- No afecta `daily-summaries` ni el flujo de sync/inbox existentes.
