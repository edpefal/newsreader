## Why

Reevo ya tiene pipeline de build/firma/subida a TestFlight (`ios-testflight-deploy`), páginas legales (`web-legal-pages`), borrado de cuenta in-app (`account-deletion`) y entitlements de suscripción funcionando en producción — pero nunca se preparó un submit real a revisión de Apple. Quedan gaps concretos que bloquean o complican ese submit: falta declarar la exención de cifrado (Apple pregunta compliance de encriptación en cada subida si no está declarada), no existe ninguna página de soporte pública (App Store Connect exige un Support URL como campo obligatorio de la ficha) y varias decisiones de la ficha de App Store Connect (age rating, categoría, App Review Notes) nunca se tomaron ni documentaron.

## What Changes

- Declarar `ITSAppUsesNonExemptEncryption = false` en `ios/Runner/Info.plist`: Reevo solo usa HTTPS estándar (Supabase, Superwall, Sentry, PostHog), sin criptografía propietaria, por lo que califica como exenta bajo las reglas de export compliance de EE.UU.
- Nueva página pública `/support` en el sitio `reevo-web` (mismo proyecto Next.js/Vercel que ya sirve `/terms` y `/privacy`), con un método de contacto real para que el usuario reporte problemas, cumpliendo el campo obligatorio "Support URL" de App Store Connect.
- Documentar y ejecutar en App Store Connect (no código, checklist en `tasks.md`):
  - Age rating: declarar honestamente que la app da acceso a contenido web sin filtrar, porque el usuario puede suscribir cualquier feed RSS/newsletter sin moderación editorial de Reevo — decisión ya tomada, se documenta el porqué para no revisarla de nuevo en cada submit futuro.
  - Elegir categoría primaria de la ficha (candidatas: News o Productivity).
  - Completar "App Review Information / Notes" aclarando que no hace falta cuenta demo: el reviewer puede iniciar sesión con su propio Apple ID vía Sign in with Apple.
  - Cargar Support URL (`/support`) y confirmar Marketing URL opcional en la ficha.

Fuera de alcance de este change: screenshots, dirección de arte, copy de marketing, título/subtítulo/keywords (ASO) — quedan para un change separado una vez que la app sea apta para submit.

## Capabilities

### New Capabilities
- `web-support-page`: página pública de soporte/contacto para Reevo, hosteada en el proyecto `reevo-web` (fuera de este repo Flutter), con URL estable en `/support`, análoga a `web-legal-pages`.

### Modified Capabilities

(ninguna — este change no cambia comportamiento de capabilities existentes de la app Flutter; el flag de export compliance es metadata de submission, no comportamiento observable)

## Impact

- `ios/Runner/Info.plist`: un flag nuevo, sin impacto en comportamiento de la app.
- Repositorio externo `/Users/eder/Development/reevo-web` (Next.js + Vercel): nueva ruta `/support`. No afecta código Flutter.
- App Store Connect: cambios de configuración de ficha (age rating, categoría, App Review Notes, Support URL) — no versionados en ningún repo, se documentan como tareas de checklist en `tasks.md` para no perderlos.
- Sin cambios en Supabase, Superwall, ni en ningún flujo de la app Flutter.
