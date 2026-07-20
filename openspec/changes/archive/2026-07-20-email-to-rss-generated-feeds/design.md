## Context

Hoy Supabase se usa en este proyecto exclusivamente para una edge function stateless (`summarize-articles`, proxy a Gemini) — no hay ninguna tabla Postgres en uso (`supabase/config.toml` no define migraciones), ni ningún mecanismo de recepción de datos entrantes desde fuera de la app. Este change introduce el primer uso real de la base de datos de Supabase y el primer flujo donde el backend recibe datos de un tercero (ForwardEmail.net) de forma asíncrona, sin que la app esté involucrada en el momento en que llegan.

El patrón cliente-a-edge-function ya existe (`GeminiSummaryGenerator` implementando `SummaryGenerator`, con URL y anon key hardcodeados, llamado vía `HttpClient`) y se reutiliza para el cliente nuevo.

La detección de que un newsletter no tiene feed (`FeedDiscoveryException`, de `auto-detect-newsletter-feed-url`) es el punto de entrada de este flujo — este change no cambia esa detección, solo agrega qué hacer después de que falla.

## Goals / Non-Goals

**Goals:**
- Generar una dirección de email única y un feed RSS correspondiente, sin intervención manual de nuestra parte por cada newsletter.
- Que el feed generado sea consumible por el pipeline `AddSource`/`SyncSources` existente sin ningún cambio en esas piezas.
- Mantener el nuevo backend dentro de Supabase, siguiendo el patrón ya establecido por `summarize-articles`.
- Autenticar el webhook de forma razonable dado que ForwardEmail no ofrece firma HMAC verificable para este tipo de webhook.

**Non-Goals:**
- Procesar adjuntos o imágenes embebidas (`cid:`) — el HTML se guarda tal cual, las referencias a `cid:` quedan rotas (limitación conocida).
- Sistema de autenticación de usuarios para proteger `create-feed` de abuso — se documenta el riesgo, se aplica un rate limit básico, no se implementa auth completa.
- Automatizar el registro de dominio o la configuración de DNS — instrucciones manuales, ejecutadas una sola vez fuera de este change.
- Edición o eliminación de feeds generados desde la UI — se puede pedir vía SQL directo si hace falta, no es parte de este change.

## Decisions

### 1. Formato del id de feed: UUID v4
Se usa un UUID v4 como `generated_feeds.id`, generado del lado del backend (edge function `create-feed`, vía `crypto.randomUUID()` en Deno). Se descarta el formato "amigable" tipo `apple.mountain.42` (usado por el proyecto de referencia yl8976/Email-to-RSS) porque:
- Es una capa de complejidad extra (diccionario de palabras, chequeo de colisiones) que no aporta valor real acá — la dirección de email generada no la escribe el usuario a mano, se copia y pega.
- UUID v4 tiene entropía muy superior, reduciendo a la práctica-cero la posibilidad de que alguien adivine la dirección de otro feed y le mande spam.
- Ya existe `IdGenerator`/`UuidIdGenerator` en el proyecto (`lib/core/utils/id_generator.dart`) usado exactamente para este propósito en otras entidades — aunque ese es del lado Flutter, el mismo criterio aplica del lado Deno con `crypto.randomUUID()` (disponible nativamente, sin dependencias nuevas).

La dirección de email generada es `<uuid>@<dominio-configurado>`, y el feed URL es `https://<supabase-project>.supabase.co/functions/v1/feed/<uuid>`.

### 2. Formato del feed servido: RSS 2.0
Se elige RSS 2.0 sobre Atom porque es el formato que ya devuelven las heurísticas de plataforma existentes (Substack, WordPress.com, Ghost Pro todas sirven RSS 2.0), manteniendo consistencia visual/estructural entre feeds "reales" y generados. `WebfeedFeedParser` (`lib/core/feed/webfeed_feed_parser.dart`) ya soporta ambos sin cambios, así que la elección no tiene impacto en el cliente.

El feed debe ser válido incluso con 0 items: `<channel>` con `<title>` (el `label` dado al crear el feed, o "Newsletter sin nombre" si no se dio ninguno) y `<link>` (apuntando al feed mismo), sin ningún `<item>`. Esto permite agregarlo como fuente inmediatamente después de crearlo, antes de que llegue el primer correo.

**Detalle de corrección crítico, encontrado durante la implementación:** `SyncSources` (`lib/features/inbox/domain/usecases/sync_sources.dart`) deduplica artículos por `item.link`, no por `guid`. Si todos los `<item>` de un feed generado compartieran el mismo `<link>` (por ejemplo, la URL del feed), solo el primer correo se sincronizaría — los siguientes se descartarían silenciosamente como "duplicados". Por eso cada `<item>` usa un `<link>` único: `<feedUrl>#<item.id>` (fragmento con el id del item). El contenido completo va en `<content:encoded>` (no en `<description>`, que `WebfeedFeedParser` mapea a `excerpt`, no a `contentHtml`) — de lo contrario cada email se trataría como "contenido truncado" sin poder mostrarse completo en el lector, ya que no existe una URL de artículo real para abrir en WebView como fallback.

### 3. Esquema de Postgres

```sql
create table generated_feeds (
  id uuid primary key default gen_random_uuid(),
  label text,
  created_at timestamptz not null default now()
);

create table feed_items (
  id uuid primary key default gen_random_uuid(),
  feed_id uuid not null references generated_feeds(id) on delete cascade,
  title text not null,
  content_html text not null,
  from_address text,
  received_at timestamptz not null,
  message_id text not null,
  unique (feed_id, message_id)
);

create index feed_items_feed_id_received_at_idx
  on feed_items (feed_id, received_at desc);
```

`unique (feed_id, message_id)` evita duplicados si ForwardEmail reintenta la entrega del mismo correo (usa `messageId` del email, no un id nuestro). El índice compuesto soporta el query principal del servidor de feed: "últimos N items de este feed_id, más nuevos primero".

### 4. Edge functions y sus rutas

- `POST /functions/v1/create-feed` — body `{ label?: string }`, devuelve `{ id, email, feedUrl }`. Inserta en `generated_feeds`.
- `POST /functions/v1/inbound-email?secret=<compartido>` — recibe el webhook del proveedor de email entrante configurado (ver Decisión 9). Extrae el `feed_id` del local-part de la dirección de destino, verifica que exista en `generated_feeds` (404 si no), inserta en `feed_items`.
- `GET /functions/v1/feed/:id` — genera XML RSS 2.0 on-demand a partir de los `feed_items` de ese `feed_id` (más recientes primero, sin límite artificial ya que la retención de 30 días ya acota el volumen). 404 si el `feed_id` no existe en `generated_feeds`.

Un cron job de Supabase (pg_cron, disponible en Postgres de Supabase) corre diariamente un `delete from feed_items where received_at < now() - interval '30 days'` — no requiere una edge function dedicada.

### 5. Autenticación del webhook `inbound-email`

Doble capa, en este orden (falla rápido si cualquiera de las dos no pasa):
1. **Secreto compartido**: el query param `secret` debe matchear un valor guardado como Supabase secret (`FORWARDEMAIL_WEBHOOK_SECRET`), configurado también como parte de la URL del TXT record de ForwardEmail (`forward-email=https://.../inbound-email?secret=...`). Sin esto, nadie puede invocar la función sin conocer el secreto, incluso si adivina la URL.
2. **IP allowlist**: la IP de origen del request (`x-forwarded-for` o el header que Supabase exponga) debe estar en el rango publicado por ForwardEmail para su servicio de webhooks. Esto es una capa adicional, no la única defensa (a diferencia del proyecto de referencia yl8976, que solo usa IP allowlist) — es defensa en profundidad ante la posibilidad de que ForwardEmail cambie sus rangos sin aviso.

### 6. Cliente Flutter: `EmailFeedGenerator`

Sigue el patrón exacto de `SummaryGenerator`/`GeminiSummaryGenerator`:

```dart
// lib/core/email_feed/email_feed_generator.dart
typedef GeneratedEmailFeed = ({String email, String feedUrl});

abstract class EmailFeedGenerator {
  /// Genera una dirección de email única y su feed RSS correspondiente.
  /// Lanza [EmailFeedGenerationException] si falla (red, backend caído).
  Future<GeneratedEmailFeed> generate({String? label});
}

class EmailFeedGenerationException implements Exception {
  final String message;
  const EmailFeedGenerationException(this.message);
}

// lib/core/email_feed/supabase_email_feed_generator.dart
class SupabaseEmailFeedGenerator implements EmailFeedGenerator {
  // mismo patrón que GeminiSummaryGenerator: URL + anon key hardcodeados,
  // llamado vía HttpClient existente.
}
```

Se ubica en `core/email_feed/` (no en `core/ai/`, que es específico del dominio de resúmenes) para mantener la separación de responsabilidades ya establecida en `core/`.

### 7. Integración en AddSourceScreen/AddSourceCubit

Nuevo estado `AddSourceFeedDiscoveryFailed` (en vez de tratar `FeedDiscoveryException` igual que cualquier otro `AddSourceError`), que lleva la URL original ingresada. `AddSourceScreen` muestra, además del mensaje de error existente, un botón "Generar dirección de email" que:
1. Llama a un nuevo use case `GenerateEmailFeed` (en `features/sources/domain/usecases/`), que a su vez llama a `EmailFeedGenerator.generate(label: <nombre que el usuario ingresó o dedujo de la URL>)`.
2. Muestra el email generado en un diálogo con botón "copiar" e instrucciones ("Suscribí el newsletter usando esta dirección; el primer correo puede tardar unos minutos en aparecer").
3. Al cerrar el diálogo, llama a `AddSource.execute(feedUrl)` con el `feedUrl` recién generado — mismo pipeline que cualquier otra fuente, sin cambios.

### 8. Riesgo de abuso del anon key

Documentado, no resuelto con auth completa (sería sobre-ingeniería para una app de uso personal sin sistema de cuentas). Mitigación mínima: rate limiting básico en `create-feed` (ej. usando la extensión `pg_net`/una tabla de contador simple en Postgres, o el rate limiting nativo de Supabase Edge Functions si está disponible) para evitar que alguien con el anon key extraído genere miles de filas en `generated_feeds`. El detalle exacto del mecanismo de rate limiting se resuelve durante la implementación (tasks.md lo incluye como tarea, no como decisión de diseño cerrada acá).

### 9. Abstracción del proveedor de email entrante (`EmailProvider`)

Durante la implementación se descubrió que ForwardEmail.net bloquea su plan gratuito para dominios "recién creados o transferidos" en registradores como Namecheap, GoDaddy y Hostgator (política anti-abuso no documentada de antemano en su pricing público) — el dominio de este proyecto (`image2svg.app`) cae en esa categoría, y requiere el plan pago Enhanced Protection ($3 USD/mes) para desbloquearse. Se evaluaron alternativas (ImprovMX: webhooks solo en plan pago, $9/mes; Cloudflare Email Routing + Workers: gratis pero requiere migrar los nameservers del dominio y escribir parseo MIME propio) y se decidió seguir con ForwardEmail pago, por ser la opción más económica de las viables.

Para no atarse a ForwardEmail específicamente, `inbound-email` se estructura detrás de una interfaz `EmailProvider`:

```ts
// supabase/functions/inbound-email/providers/email_provider.ts
interface NormalizedInboundEmail {
  toAddress: string;
  subject: string;
  contentHtml: string;
  fromAddress: string | null;
  receivedAt: Date;
  messageId: string;
}

interface EmailProvider {
  verifyRequest(req: Request): Promise<boolean>;
  parsePayload(json: unknown): NormalizedInboundEmail;
}
```

`ForwardEmailProvider implements EmailProvider` concentra todo lo específico de ForwardEmail (parseo del payload `recipients`/`from.value`/etc., IP allowlist + secreto). `index.ts` solo conoce `EmailProvider` y `NormalizedInboundEmail` — la lógica de negocio (buscar el feed, insertar el item) es 100% agnóstica del proveedor. Si en el futuro se reemplaza ForwardEmail por otro proveedor (ImprovMX, Cloudflare, o un servidor SMTP propio), solo hace falta escribir una nueva clase `XyzProvider` e intercambiar la instancia en `index.ts` — sin tocar el resto del handler.

## Risks / Trade-offs

- **[Riesgo] Dependencia de ForwardEmail.net como proveedor externo**: si cambia sus términos, límites del plan pago, o deja de operar, el mecanismo completo deja de funcionar. → Mitigación: la abstracción `EmailProvider` (Decisión 9) permite reemplazarlo sin rediseñar nada; el resto del sistema (feeds ya generados con items ya sincronizados localmente) sigue funcionando aunque ForwardEmail deje de andar, solo se pierde la capacidad de generar/recibir nuevos hasta migrar de proveedor.
- **[Riesgo] Sin firma HMAC verificable en el webhook de ForwardEmail**: la autenticación depende de un secreto en la URL + IP allowlist, no de una firma criptográfica del payload. → Mitigación: el secreto compartido ya es una barrera fuerte (no es adivinable), y la combinación con IP allowlist reduce further el riesgo de spoofing.
- **[Riesgo] `content_html` puede incluir HTML malicioso/tracking pixels** ya que viene de un tercero (el newsletter) sin sanitizar. → Mitigación: el `HtmlContentRenderer` existente (`core/widgets/`, ya usado para todo el contenido HTML de artículos de cualquier fuente) ya asume contenido no confiable — no es un riesgo nuevo introducido por este change, es el mismo trust model que ya existe para cualquier feed RSS externo.
- **[Riesgo] Rate limiting insuficiente en `create-feed`** ante el anon key expuesto → Mitigación: documentado explícitamente arriba; se implementa un mecanismo básico, no es un blocker para este change dado el perfil de uso personal.
- **[Riesgo] Costo mensual real, no cero**: ForwardEmail Enhanced Protection ($3 USD/mes), por el bloqueo de dominio nuevo descrito en la Decisión 9 (el plan gratuito no alcanzó, a diferencia de lo asumido originalmente en la exploración previa a este change). → Mitigación: sigue siendo la opción más barata evaluada; si en el futuro deja de ser aceptable, la abstracción `EmailProvider` permite migrar sin rediseño.

## Migration Plan

1. **Prerequisito manual (fuera de este change, antes de desplegar)**: usar el subdominio `inbox.image2svg.app` (del dominio ya existente `image2svg.app`), crear cuenta en ForwardEmail.net y activar el plan Enhanced Protection ($3/mes, requerido por la Decisión 9), configurar MX hacia ForwardEmail, TXT de SPF y del webhook (`forward-email=https://<url>/inbound-email?secret=...`).
2. Aplicar la migración SQL nueva (tablas `generated_feeds`, `feed_items`, índice, cron de limpieza) vía Supabase CLI (`supabase db push` o equivalente).
3. Configurar los secrets `FORWARDEMAIL_WEBHOOK_SECRET` y `EMAIL_DOMAIN=inbox.image2svg.app` en Supabase (mismo mecanismo que `GEMINI_API_KEY` ya usa para `summarize-articles`).
4. Desplegar las tres edge functions nuevas.
5. Deploy de la app Flutter con los cambios de `AddSourceScreen`/`AddSourceCubit` y el nuevo `EmailFeedGenerator`.

Sin necesidad de rollback especial: si algo falla, las edge functions nuevas simplemente no se invocan (el flujo existente de `AddSource` sin fallback sigue funcionando igual que hoy), y las tablas nuevas no afectan ninguna tabla/mecanismo existente.

## Open Questions

Ninguna pendiente — las decisiones técnicas que quedaron abiertas en la exploración (formato de id, RSS vs Atom, esquema de tablas, rutas de las edge functions, patrón del cliente Flutter) se resolvieron arriba.
