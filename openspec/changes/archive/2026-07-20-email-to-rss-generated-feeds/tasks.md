## 1. Prerequisitos externos (manuales, antes de cualquier código)

- [x] 1.1 Registrar un dominio nuevo dedicado a esto (o un subdominio de uno existente). **Resuelto**: se usa el subdominio `inbox.image2svg.app` del dominio ya comprado en Namecheap (`image2svg.app`), en vez de registrar uno nuevo.
- [x] 1.2 Crear cuenta en ForwardEmail.net. **Actualizado**: el plan gratuito bloquea `inbox.image2svg.app` por ser un dominio "recién creado/transferido" en Namecheap (política anti-abuso de ForwardEmail) — hace falta activar el plan **Enhanced Protection ($3 USD/mes)** para desbloquearlo. Se evaluaron alternativas (ImprovMX $9/mes, Cloudflare Email Routing gratis pero con mucho más trabajo) y se decidió seguir con ForwardEmail pago por ser la más económica. Plan activado.
- [x] 1.3 Configurar registros MX del dominio hacia `mx1.forwardemail.net` / `mx2.forwardemail.net` (prioridad 10).
- [x] 1.4 Configurar TXT de SPF (`v=spf1 include:spf.forwardemail.net -all`).
- [x] 1.5 Definir el secreto compartido del webhook y configurar el TXT de ForwardEmail apuntando a `https://<supabase-project>.supabase.co/functions/v1/inbound-email?secret=<secreto>`.
- [x] 1.6 Verificar en el dashboard de ForwardEmail que el dominio está validado y el catch-all está activo. **Nota**: ForwardEmail desaconseja poner el webhook en texto plano en el TXT de DNS (`forward-email=...`) porque los registros TXT son legibles públicamente y expondrían el secreto; en su lugar se configuró el alias catch-all (`*@inbox.image2svg.app`) directamente en el dashboard de ForwardEmail, con la URL del webhook (incluyendo el `?secret=`) en "Forwarding Recipients". El TXT `forward-email=` se eliminó de Namecheap.
- [x] 1.7 Configurar el secret `EMAIL_DOMAIN=inbox.image2svg.app` en Supabase (usado por `create-feed` para armar la dirección `<uuid>@inbox.image2svg.app`). No estaba explícito como tarea separada en la redacción original; se agrega acá porque `supabase/functions/create-feed/index.ts` lo requiere.

## 2. Esquema de base de datos (Supabase Postgres)

- [x] 2.1 Crear migración SQL con las tablas `generated_feeds` y `feed_items` según el esquema definido en `design.md`.
- [x] 2.2 Agregar el índice `feed_items_feed_id_received_at_idx`.
- [x] 2.3 Configurar un cron job (pg_cron) que borre diariamente `feed_items` con `received_at` de más de 30 días.
- [x] 2.4 Aplicar la migración (`supabase db push` o equivalente) y verificar que las tablas existen en el proyecto.

## 3. Edge function `create-feed`

- [x] 3.1 Crear `supabase/functions/create-feed/index.ts`: recibe `POST` con body `{ label?: string }`, genera UUID v4, inserta en `generated_feeds`, devuelve `{ id, email, feedUrl }`.
- [x] 3.2 Implementar rate limiting básico (ver riesgo de abuso en `design.md`) para evitar generación masiva de feeds.
- [x] 3.3 Manejar errores (falta de conexión a la base, body inválido) devolviendo respuestas de error claras, siguiendo el patrón de `summarize-articles/index.ts`.

## 4. Edge function `inbound-email`

- [x] 4.1 Crear `supabase/functions/inbound-email/index.ts`: valida el query param `secret` contra el secret de Supabase `FORWARDEMAIL_WEBHOOK_SECRET`.
- [x] 4.2 Validar la IP de origen del request contra el rango publicado por ForwardEmail.
- [x] 4.3 Parsear el payload JSON de ForwardEmail (`recipients`, `from`, `subject`, `text`, `html`, `date`, `messageId`, `headerLines`), extrayendo el `feed_id` del local-part de `recipients[0]`.
- [x] 4.4 Decodificar encoded-words RFC 2047 en el `subject` si aplica.
- [x] 4.5 Si el `feed_id` no existe en `generated_feeds`, responder 404 sin guardar nada.
- [x] 4.6 Insertar en `feed_items` (preferir `html` sobre `text`, `message_id` desde `messageId`), respetando el `unique (feed_id, message_id)` para evitar duplicados en reintentos.
- [x] 4.7 Configurar el secret `FORWARDEMAIL_WEBHOOK_SECRET` en Supabase.
- [x] 4.8 Extraer la lógica específica de ForwardEmail (validación de secreto+IP, parseo del payload) detrás de una interfaz `EmailProvider` (`providers/email_provider.ts` + `providers/forward_email_provider.ts`), dejando `index.ts` agnóstico del proveedor — para poder reemplazar ForwardEmail en el futuro (otro proveedor, o un servidor SMTP propio) sin reescribir la lógica de negocio. Ver design.md Decisión 9.

## 5. Edge function del servidor de feed

- [x] 5.1 Crear `supabase/functions/feed/index.ts` (ruta `GET /functions/v1/feed/:id`): genera XML RSS 2.0 a partir de los `feed_items` del `feed_id` dado, ordenados por `received_at` descendente.
- [x] 5.2 Asegurar que el feed es válido (channel con title/link) incluso con 0 items.
- [x] 5.3 Devolver 404 si el `feed_id` no existe en `generated_feeds`.
- [x] 5.4 Verificar manualmente que el XML generado parsea correctamente contra `WebfeedFeedParser` (mismo criterio de verificación que se usó en el change anterior contra sitios reales). Encontrados y corregidos 2 bugs reales: (a) el contenido debía ir en `<content:encoded>`, no `<description>`, para que `contentHtml` no quede null; (b) cada `<item>` necesita un `<link>` único (no el del feed), porque `SyncSources` deduplica por `item.link` y todos los items hubieran colisionado.

## 6. Cliente Flutter: `EmailFeedGenerator`

- [x] 6.1 Crear `lib/core/email_feed/email_feed_generator.dart` con la interfaz `EmailFeedGenerator`, el typedef `GeneratedEmailFeed`, y `EmailFeedGenerationException`.
- [x] 6.2 Crear `lib/core/email_feed/supabase_email_feed_generator.dart` con `SupabaseEmailFeedGenerator implements EmailFeedGenerator`, siguiendo el patrón de `GeminiSummaryGenerator`.
- [x] 6.3 Registrar `EmailFeedGenerator` en `lib/core/di/injection.dart`.
- [x] 6.4 Escribir tests unitarios con mocktail para `SupabaseEmailFeedGenerator` (éxito, error de red, respuesta inválida del backend).

## 7. Integración en AddSourceScreen/AddSourceCubit

- [x] 7.1 Crear el use case `GenerateEmailFeed` en `lib/features/sources/domain/usecases/`, que llama a `EmailFeedGenerator.generate()`. (Nota: el llamado a `AddSource.execute()` con el `feedUrl` resultante se dejó como paso separado, disparado desde la UI recién cuando el usuario confirma en el diálogo — no dentro del use case — para poder mostrarle la dirección generada antes de comprometerse a agregarla como fuente. Coincide con lo que ya preveía design.md Decisión 7.)
- [x] 7.2 Agregar un nuevo estado (ej. `AddSourceFeedDiscoveryFailed`) a `AddSourceState` que se emite en lugar de/además de `AddSourceError` cuando la causa es `FeedDiscoveryException`.
- [x] 7.3 Actualizar `AddSourceScreen` para mostrar la opción "Generar dirección de email" cuando corresponda.
- [x] 7.4 Implementar el diálogo/pantalla que muestra el email generado, instrucciones, y botón de copiar.
- [x] 7.5 Conectar la confirmación del diálogo con `GenerateEmailFeed`/`AddSource`, mostrando el mismo SnackBar de éxito que ya existe para fuentes agregadas.
- [x] 7.6 Escribir/actualizar tests unitarios de `AddSourceCubit` y tests de widget de `AddSourceScreen` cubriendo el nuevo flujo.

## 8. Verificación

- [x] 8.1 Probar el flujo end-to-end manualmente: generar una dirección real, suscribir un newsletter real con ella, confirmar que el email llega, se convierte en item, y aparece en el feed servido. Verificado con TLDR: el email de confirmación de suscripción llegó al webhook, se guardó como `feed_item`, se sirvió en el XML del feed (`content:encoded` con el HTML completo), se agregó como fuente en la app corriendo en un emulador Android, y apareció en el Inbox tras sincronizar. También se corrigió el deploy: `feed` e `inbound-email` necesitaban `--no-verify-jwt` (no reciben un JWT de Supabase; su auth es el `secret` en la URL + IP allowlist).
- [x] 8.2 Correr `flutter analyze` y resolver cualquier warning.
- [x] 8.3 Correr `flutter test` sobre los módulos nuevos/modificados y confirmar que todo pasa.
- [x] 8.4 Documentar en el README o en un doc de operaciones el proceso de setup de dominio/ForwardEmail para que sea reproducible si hace falta migrar de dominio en el futuro.
