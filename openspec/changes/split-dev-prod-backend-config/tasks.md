## 1. AppConfig en el cliente

- [x] 1.1 Crear `lib/core/config/app_config.dart`: clase estática (constructor privado, patrón `AppConstants`) con `isProd` (`const String.fromEnvironment('APP_ENV', defaultValue: 'dev') == 'prod'`), `supabaseUrl` y `supabaseAnonKey` (par de valores hardcodeados dev/prod, elegidos según `isProd`).
- [x] 1.2 `lib/main.dart`: usar `AppConfig.supabaseUrl`/`AppConfig.supabaseAnonKey` en `Supabase.initialize`; loguear una vez al arrancar qué ambiente está activo (`debugPrint('Ambiente: ${AppConfig.isProd ? 'prod' : 'dev'}')` o similar).
- [x] 1.3 `lib/core/ai/gemini_summary_generator.dart`: reemplazar la URL hardcodeada por `'${AppConfig.supabaseUrl}/functions/v1/summarize-articles'`; quitar la constante local.
- [x] 1.4 `lib/core/email_feed/supabase_email_feed_generator.dart`: mismo cambio para `create-feed`.
- [x] 1.5 `lib/core/feed/supabase_feed_sync_trigger.dart`: mismo cambio para `sync-feeds`.
- [x] 1.6 `lib/features/account/domain/usecases/delete_account.dart`: mismo cambio para `delete-account`.

## 2. Proyecto Supabase "dev" (infraestructura)

- [x] 2.1 Crear el proyecto Supabase nuevo para dev (vía dashboard o MCP).
- [x] 2.2 Aplicar las 9 migraciones existentes al proyecto dev (`supabase link` + `supabase db push`, o vía MCP). (En la práctica son 10 -- se sumó `add_entitlements` después de escrito este proposal.)
- [x] 2.3 Desplegar las 6 Edge Functions al proyecto dev. (En la práctica son 7 -- se sumó `superwall-webhook` después de escrito este proposal.)
- [x] 2.4 Configurar el secret `GEMINI_API_KEY` del proyecto dev con la key de free tier actual. **Requiere que el usuario provea el valor** (no es legible desde el código ni desde las herramientas — solo se puede *escribir* un secret nuevo, no leer el existente).
- [x] 2.5 Completar `AppConfig` con la URL y anon key reales del proyecto dev recién creado.

## 3. Rotar prod a cuenta paga de Gemini

- [x] 3.1 **Acción del usuario**: crear/activar una cuenta de Gemini de pago y obtener una API key nueva. (Vinculada a "My Billing Account" compartida en pospago -- el usuario decidió no bloquearse en aislar/prepagar la billing account por ahora, ver conversación.)
- [x] 3.2 Actualizar el secret `GEMINI_API_KEY` del proyecto existente (ahora "prod") con la key nueva de pago.
- [x] 3.3 Confirmar en `AppConfig` que los valores de "prod" siguen apuntando al proyecto Supabase existente (no cambian, solo cambia su secret de Gemini).

## 4. Verificación

- [x] 4.1 Correr `flutter analyze` sin warnings.
- [x] 4.2 Correr `flutter test` y confirmar que toda la suite pasa.
- [ ] 4.3 `flutter run` (sin flags) y confirmar en el log que arranca en modo "dev", contra el proyecto dev — probar agregar una fuente y generar un resumen sin que afecte al proyecto prod.
- [x] 4.4 `flutter run --dart-define=APP_ENV=prod` y confirmar en el log que arranca en modo "prod", contra el proyecto existente. (Requirió subir `minSdk` a 26 por superwallkit_flutter, ver commit aparte.)
