## Why

Hoy toda la app (local o de la store) pega contra un único proyecto de Supabase, con la URL hardcodeada en 5 archivos distintos. Cualquier sesión de desarrollo local consume la misma cuota de Gemini y escribe sobre la misma base de datos que algún día van a usar clientes reales. Con el lanzamiento a días de distancia y el plan de pagar una cuenta de Gemini para producción, hace falta poder desarrollar contra un backend separado (con la cuota gratuita de Gemini) sin arriesgar el backend de producción.

No se arman flavors de Flutter en este change (requiere duplicar configuración de Xcode/Android con más riesgo de setup justo antes de lanzar) — queda como mejora futura. Este change resuelve la separación con el mínimo cambio necesario: un solo punto de configuración en Dart, seleccionado explícitamente al buildear.

## What Changes

- Nuevo `AppConfig` (`lib/core/config/app_config.dart`) que expone `supabaseUrl` y `supabaseAnonKey`, decidiendo entre un par de valores "dev" o "prod" según el dart-define `APP_ENV` (`dev` por defecto si no se pasa nada — así un `flutter run` normal nunca pega a prod sin que alguien lo pida explícitamente).
- Los 5 lugares que hoy hardcodean la URL de Supabase (`main.dart`, `gemini_summary_generator.dart`, `supabase_email_feed_generator.dart`, `supabase_feed_sync_trigger.dart`, `delete_account.dart`) pasan a leer `AppConfig.supabaseUrl`/`AppConfig.supabaseAnonKey` en vez de la constante local duplicada.
- Se imprime al arrancar la app (una sola vez, por log) qué ambiente está activo — sin UI nueva, solo para poder confirmar rápido contra qué backend corre una build dada.
- **Fuera del código**: se crea un segundo proyecto de Supabase ("dev"), se le aplican las mismas migraciones, se despliegan las mismas Edge Functions, y se le configura `GEMINI_API_KEY` con la key de free tier existente (la de prod pasa a una key nueva de cuenta paga). El dominio/DNS de email-to-RSS no se duplica para dev — esa feature puntual queda sin recepción real de mails en dev, aceptado como limitación conocida.

## Capabilities

_(sin cambios de comportamiento observable para el usuario — mismo comportamiento, distinto backend de destino según cómo se compiló la app. `skip_specs: true` en `.openspec.yaml`.)_

## Impact

- `lib/core/config/app_config.dart` (nuevo)
- `lib/main.dart`
- `lib/core/ai/gemini_summary_generator.dart`
- `lib/core/email_feed/supabase_email_feed_generator.dart`
- `lib/core/feed/supabase_feed_sync_trigger.dart`
- `lib/features/account/domain/usecases/delete_account.dart`
- Proyecto Supabase nuevo ("dev"): migraciones, Edge Functions, secret `GEMINI_API_KEY`
- Proyecto Supabase existente: rotar `GEMINI_API_KEY` a la cuenta paga (pasa a ser "prod")
