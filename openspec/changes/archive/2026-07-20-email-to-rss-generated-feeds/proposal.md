## Why

El change `auto-detect-newsletter-feed-url` resolvió detectar automáticamente el feed cuando el newsletter SÍ expone RSS/Atom. Pero muchos newsletters se distribuyen exclusivamente por email, sin ningún feed disponible bajo ninguna URL. Hoy, cuando esto pasa, el usuario recibe `FeedDiscoveryException` y no tiene ninguna alternativa dentro de la app — tiene que resignarse a no leer ese newsletter en Newsletter Hub. Similar a lo que resuelve kill-the-newsletter.com, se puede generar una dirección de email única por newsletter; cualquier correo que llegue a esa dirección se convierte en un item de un feed RSS propio, que la app consume con el pipeline de sincronización que ya existe.

## What Changes

- Nuevo backend en Supabase (primer uso real de Postgres en este proyecto; hasta ahora solo había edge functions stateless): dos tablas (`generated_feeds`, `feed_items`) y tres edge functions (`create-feed`, `inbound-email`, servidor de feed XML).
- Integración con ForwardEmail.net como proveedor de recepción de email entrante vía webhook, detrás de una abstracción (`EmailProvider`) que permite reemplazarlo en el futuro sin tocar la lógica de negocio. Requiere plan pago Enhanced Protection ($3 USD/mes): el plan gratuito bloquea dominios recién registrados o transferidos en registradores como Namecheap (política anti-abuso descubierta durante la implementación, no documentada de antemano). Usa un subdominio del dominio ya existente `image2svg.app` (`inbox.image2svg.app`), sin necesidad de registrar un dominio nuevo.
- El webhook `inbound-email` recibe cada correo, lo asocia al feed generado correspondiente por el local-part de la dirección de destino, y lo guarda como item. Autenticación de doble capa: allowlist de IP de ForwardEmail + secreto compartido en la URL.
- Retención de `feed_items`: limpieza por tiempo, 30 días. No requiere ningún cambio en `NewsSource` ni en `SyncSources` — el dedupe existente por URL en el cliente ya es suficiente para evitar duplicados o pérdida real de datos en el uso normal.
- En `AddSourceScreen`, cuando falla la detección automática (`FeedDiscoveryException`), se ofrece la alternativa de generar una dirección de email. El feed URL resultante se agrega como fuente usando el `AddSource` use case ya existente, sin cambios — un feed generado es válido (aunque con 0 items) desde el momento de su creación.
- Nueva abstracción en `core/` para el cliente de `create-feed`, siguiendo el patrón ya usado por `SummaryGenerator`/`GeminiSummaryGenerator` para llamar a edge functions de Supabase.
- Fuera de alcance explícito: manejo de adjuntos/imágenes embebidas (`cid:`) en los emails, sistema de autenticación completo para prevenir abuso del anon key (se documenta el riesgo, no se implementa auth real), automatización del registro de dominio/DNS, edición o eliminación de feeds generados desde la app.

## Capabilities

### New Capabilities
- `email-to-rss-feeds`: generación de una dirección de email única por newsletter, backend de recepción/conversión a feed RSS, y servido del feed resultante — permite agregar como fuente cualquier newsletter que no tenga RSS/Atom disponible.

### Modified Capabilities
- `source-management`: `AddSourceScreen` ofrece una alternativa nueva ("generar dirección de email") cuando la detección automática de feed falla, además del mensaje de error ya existente.

## Impact

- `supabase/functions/create-feed/`, `supabase/functions/inbound-email/`, `supabase/functions/feed/` (o el naming que se defina en design.md): edge functions nuevas.
- Tablas nuevas en la base de datos Postgres de Supabase (migración SQL nueva): `generated_feeds`, `feed_items`.
- `lib/core/`: nueva abstracción para el cliente de `create-feed` (interfaz + implementación concreta, siguiendo el patrón de `SummaryGenerator`).
- `lib/features/sources/`: nuevo use case para generar el email/feed, cambios en `AddSourceScreen`/`AddSourceCubit`/`AddSourceState` para ofrecer el fallback.
- Requiere infraestructura externa nueva: cuenta en ForwardEmail.net (plan pago Enhanced Protection, $3 USD/mes) y configuración de DNS manual sobre el subdominio `inbox.image2svg.app` (prerequisito de este change; no hace falta registrar un dominio nuevo, ya existía).
- Sin cambios en `NewsSource`, `SyncSources`, ni en el modelo de datos Hive local.
