## Why

La app hoy no tiene ningún concepto de usuario: todo funciona en modo anónimo local (Hive), y las pocas llamadas a Supabase usan una anon key compartida por todos los installs. Para poder ofrecer un esquema freemium con cuota real de resúmenes diarios (explorado por separado), primero hace falta una identidad de usuario real y verificable — sin esto, ningún límite de uso puede hacerse cumplir de forma seria. Este change sienta esa base: login obligatorio, sin tocar todavía cómo se generan/guardan fuentes, artículos o resúmenes.

## What Changes

- **BREAKING** (de cara al usuario): la app deja de permitir uso anónimo. Al abrir la app sin sesión activa, se muestra una pantalla de login antes de llegar al Inbox o cualquier otra sección.
- Se agrega autenticación vía Supabase Auth, con **Google Sign-In y Sign in with Apple únicamente** (sin email/contraseña).
- Nueva abstracción `core/auth/AuthClient` (interfaz + implementación concreta), siguiendo el mismo patrón de abstracciones ya usado en el proyecto (`HttpClient`, `SummaryGenerator`, `EmailFeedGenerator`, etc.) — ninguna librería de terceros (Supabase Auth SDK, `google_sign_in`, `sign_in_with_apple`) se usa fuera de esa abstracción.
- Nueva pantalla de login (`features/auth/presentation/`) con los dos botones de inicio de sesión, mostrada como pantalla inicial cuando no hay sesión.
- El resto de la app (Inbox, Fuentes, Favoritos, Leídos, Resúmenes) sigue funcionando exactamente igual que hoy una vez logueado — sin cambios en Hive, en los use cases existentes, ni en ningún dato local. Esta fundación solo agrega la puerta de entrada; no sincroniza datos a la cuenta (eso es un change futuro separado) ni implementa ninguna cuota o paywall (también futuro).
- Se agrega la posibilidad de cerrar sesión (logout) desde algún lugar de la app (a definir en design.md).
- Requiere setup externo antes de poder probar: proyecto OAuth en Google Cloud Console (client IDs Android/iOS), y Sign in with Apple en Apple Developer (cuenta paga) — habrá una serie de tareas manuales similares a las del change `email-to-rss-generated-feeds` con ForwardEmail.

## Capabilities

### New Capabilities
- `user-auth`: autenticación de usuario vía Google/Apple Sign-In sobre Supabase Auth, con la app requiriendo sesión activa para cualquier uso.

### Modified Capabilities
(ninguna — no se toca ningún requirement existente de `source-management`, `article-lifecycle`, `daily-summaries`, etc.; esos siguen funcionando igual, solo que ahora detrás de una pantalla de login)

## Impact

- `lib/core/auth/`: nueva abstracción `AuthClient` + implementación concreta sobre Supabase Auth.
- `lib/features/auth/`: nueva pantalla de login, cubit/estado asociado.
- `lib/presentation/app/router.dart`: se agrega lógica de redirect — sin sesión activa, cualquier ruta redirige a la pantalla de login.
- `lib/core/di/injection.dart`: registro del nuevo `AuthClient`.
- `pubspec.yaml`: nuevas dependencias (SDK de Supabase Auth o llamadas REST directas, `google_sign_in`, `sign_in_with_apple` — a definir en design.md).
- Configuración externa: Google Cloud Console (OAuth client IDs), Apple Developer (Sign in with Apple), Supabase Auth providers.
- Sin cambios en Hive, en `core/domain/`, ni en ningún use case de features existentes.
