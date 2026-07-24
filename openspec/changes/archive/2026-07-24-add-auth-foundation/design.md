## Context

Hoy no existe ningún cliente de Supabase en el proyecto: `create-feed`, `inbound-email`, `summarize-articles` y `feed` se llaman con HTTP plano vía la abstracción `HttpClient` (`core/network/`), usando la anon key hardcodeada. No hay noción de sesión, usuario, ni token que no sea esa anon key compartida.

Este change agrega la primera identidad de usuario real del proyecto. Es explícitamente una fundación: no toca Hive, no sincroniza `Source`/`Article`/`DailySummary` a ningún backend, y no implementa cuota ni paywall — esas son exploraciones/changes futuros que dependen de que esta base exista.

## Goals / Non-Goals

**Goals:**
- Login obligatorio (Google Sign-In + Sign in with Apple) antes de acceder a cualquier pantalla de la app.
- Sesión persistida entre aperturas de la app (no volver a pedir login cada vez).
- Abstracción `AuthClient` en `core/auth/`, sin que ningún SDK de terceros (Supabase Auth, `google_sign_in`, `sign_in_with_apple`) se use fuera de esa capa.
- Punto de logout accesible desde la UI.

**Non-Goals:**
- No se sincroniza ningún dato existente (fuentes, artículos, favoritos, resúmenes) a la cuenta — siguen 100% en Hive local, sin relación con el `user_id` todavía.
- No se implementa cuota, entitlements, ni RevenueCat — eso es un change posterior que consume esta fundación.
- No se agrega login por email/contraseña (decisión ya tomada: solo Google/Apple).
- No se migra ningún dato de usuarios que ya usaban la app en modo anónimo (no existía tracking de usuario antes, no hay nada que migrar).

## Decisions

### Usar el SDK oficial `supabase_flutter`, no llamadas REST a mano
El resto del proyecto evita SDKs de terceros a favor de HTTP plano vía `HttpClient` (tabla de abstracciones de `CLAUDE.md`). Para auth se hace una excepción deliberada: `supabase_flutter` maneja persistencia de sesión, refresh de tokens, y el flujo `signInWithIdToken` (necesario para intercambiar el ID token nativo de Google/Apple por una sesión de Supabase) de forma robusta y ya probada. Reimplementar refresh de tokens y persistencia de sesión a mano es exactamente el tipo de superficie propensa a bugs de seguridad que conviene no reinventar. La excepción se mantiene acotada: `supabase_flutter` se usa **solo** dentro de `core/auth/SupabaseAuthClient`, nunca importado directamente en `domain/` o `presentation/` — mismo principio de abstracción que ya sigue el resto del proyecto, aplicado a un SDK en lugar de a HTTP plano.

**Alternativa considerada**: llamar a mano los endpoints REST de Supabase Auth (`/auth/v1/token`, etc.) reutilizando `HttpClient`. Se descarta por el riesgo de manejar mal el refresh token o la expiración de sesión — a diferencia de las demás llamadas del proyecto (stateless, un request-response), auth es inherentemente stateful y de larga duración.

### Flujo de login: ID token nativo → `signInWithIdToken`
- **Google**: paquete `google_sign_in` obtiene el ID token nativo del usuario; se lo pasa a `supabase.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: ...)`.
- **Apple**: paquete `sign_in_with_apple` obtiene el ID token de Sign in with Apple; mismo intercambio con `OAuthProvider.apple`.
- Ambos flujos quedan detrás de `AuthClient.signInWithGoogle()` / `AuthClient.signInWithApple()`, sin que `LoginScreen` conozca ningún detalle de Supabase ni de los SDKs nativos.

### Gate de acceso vía `redirect` de go_router
`appRouter` agrega un `redirect` a nivel raíz que consulta el estado de sesión actual (expuesto por `AuthClient` como stream/listenable) y redirige a `/login` si no hay sesión activa, para cualquier ruta. Se usa `refreshListenable` (o el equivalente) enganchado al stream de cambios de sesión de `AuthClient`, para que el router reaccione automáticamente a login/logout sin necesitar `context.go` manual desde cada pantalla.

**Alternativa considerada**: chequear sesión en cada pantalla individualmente (ej. un wrapper widget). Se descarta porque go_router ya tiene un mecanismo de primera clase para esto (`redirect`), y evita tener que acordarse de envolver cada nueva pantalla futura.

### Logout: entrada en el `NavigationDrawer` existente
No existe hoy ninguna pantalla de "Configuración" en la app — el `NavigationDrawer` en `_ScaffoldWithNavBar` (`router.dart`) es el único lugar de navegación persistente. Se agrega una entrada "Cerrar sesión" al final del drawer, sin crear una pantalla de Settings nueva solo para esta única acción.

**Alternativa considerada**: crear una pantalla de Settings dedicada. Se descarta por ahora (YAGNI) — si en el futuro se necesita más de una preferencia de cuenta, se puede introducir esa pantalla como su propio change.

### Modelo de datos: ninguno nuevo en Hive, ninguno nuevo en Postgres (todavía)
Esta fundación no requiere tablas nuevas en Supabase — Supabase Auth ya gestiona `auth.users` internamente. No se toca Hive. El único estado nuevo del lado del cliente es la sesión en memoria/persistida por `supabase_flutter` y un `AuthCubit`/estado equivalente en `features/auth/presentation/` que el router consulta.

## Risks / Trade-offs

- **[Riesgo] Bloquear el acceso anónimo es un cambio de UX radical para cualquier usuario actual de la app** → Mitigación: es una decisión de producto explícita y ya confirmada por el usuario, no un descuido. Se documenta como **BREAKING** en el proposal.
- **[Riesgo] Configuración externa (Google Cloud Console, Apple Developer) puede traer bloqueos no anticipados**, como ya pasó con ForwardEmail en el change de email-to-RSS (política anti-abuso no documentada de antemano) → Mitigación: se listan como tareas manuales explícitas en `tasks.md`, para poder descubrir bloqueos temprano y ajustar en vivo, en vez de asumir que el setup será directo.
- **[Riesgo] iOS exige ofrecer Sign in with Apple si se ofrece cualquier otro login social** (regla de App Store Review) → Mitigación: ya contemplado desde el inicio — se implementan ambos (Google y Apple), no solo Google.
- **[Trade-off] Se introduce un SDK pesado (`supabase_flutter`) rompiendo el patrón "HTTP plano" del resto del proyecto** → Aceptado conscientemente por la complejidad real de manejar sesiones/tokens de forma segura a mano (ver Decisión 1).

## Migration Plan

No hay datos que migrar (no existía ningún concepto de usuario antes). Pasos de despliegue:
1. Configurar Google OAuth (Cloud Console) y Sign in with Apple (Apple Developer) — manual, fuera del código.
2. Habilitar los providers Google y Apple en Supabase Auth (dashboard).
3. Agregar las dependencias (`supabase_flutter`, `google_sign_in`, `sign_in_with_apple`) y el código de `core/auth/`, `features/auth/`.
4. Agregar el `redirect` al router y la entrada de logout al drawer.
5. Verificar manualmente el flujo completo: login con Google, login con Apple, persistencia de sesión al reabrir la app, logout, y que cualquier ruta sin sesión redirige a `/login`.

Sin plan de rollback de datos — si hay que revertir, es simplemente revertir el código (quitar el `redirect` y las pantallas), ya que no se persiste nada nuevo del lado del servidor que dependa de este change.
