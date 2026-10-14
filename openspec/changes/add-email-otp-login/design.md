## Context

El login vive en `LoginScreen` + `LoginCubit` (feature `auth`), que delega en `AuthClient` (`core/auth/`), implementado por `SupabaseAuthClient`. Hoy `AuthClient` expone `signInWithGoogle` y `signInWithApple`; el `LoginCubit` tiene los estados `LoginIdle`, `LoginInProgress` y `LoginError(AppErrorCode)`, y el router reacciona solo al cambio de sesión (`GoRouter.redirect` + `_AuthChangeNotifier`), por lo que ningún método de login navega a mano. Ver proposal.md para la motivación.

Hechos verificados que condicionan el diseño:
- `gotrue 2.27.2` expone `signInWithOtp(email:, shouldCreateUser:)` y `verifyOTP(email:, token:, type: OtpType.email)`. Los errores llegan como `AuthException` con `code` (`otp_expired`, `over_email_send_rate_limit`, `over_request_rate_limit`, `validation_failed`). Un código incorrecto y uno expirado devuelven el mismo `otp_expired` ("Token has expired or is invalid"): no se pueden distinguir.
- Supabase usa la misma plantilla para magic link y OTP: lo que decide qué recibe el usuario es si la plantilla "Magic Link" contiene `{{ .Token }}` o `{{ .ConfirmationURL }}`.
- El SMTP integrado de Supabase solo envía a miembros del equipo y a 2 correos/hora: sin SMTP propio, el flujo no funciona para usuarios reales.
- `AuthException` ya existe en la app (`core/auth/auth_client.dart`); `SupabaseAuthClient` importa Supabase con el prefijo `sb.`.

## Goals / Non-Goals

**Goals:**
- Login con correo y código, con el mismo contrato de `AuthClient` que los otros métodos (el cubit no conoce a Supabase).
- Cero cambios en el router y en el `redirect`.
- Que Google y Apple se comporten exactamente igual que hoy.

**Non-Goals:**
- Contraseñas, magic links, deep links o universal links.
- Vincular cuentas manualmente desde Ajustes (el caso de Apple con correo oculto solo recibe un aviso).
- Configurar Supabase Auth por código o por el MCP: el MCP de Supabase no administra Auth. La configuración es manual (ver tareas) y el MCP solo se usa para verificar.
- Distinguir "código incorrecto" de "código expirado" (el servidor no lo permite).

## Decisions

### 1. Estados internos de `/login`, mismo cubit

```
LoginIdle ──[Continuar con correo]──▶ LoginEmailEntry ──[enviar]──▶ LoginCodeSent(email, resendAvailableAt)
    ▲                                       ▲   ▲                          │
    └──────────── atrás ────────────────────┘   └──── cambiar correo / atrás ┘
```

`LoginState` suma `LoginEmailEntry` y `LoginCodeSent(email, resendAvailableAt)`. `LoginInProgress` y `LoginError` se mantienen; para no perder la vista actual al mostrar un error o un spinner, los estados de la vista de correo y de código llevan un flag `isLoading`/`error` en vez de depender solo de `LoginInProgress`. `LoginScreen` elige qué vista pintar con un `switch` sobre el estado. El `PopScope` intercepta el atrás: en `LoginCodeSent` vuelve a `LoginEmailEntry`, en `LoginEmailEntry` vuelve a `LoginIdle`, y en `LoginIdle` no intercepta.

*Alternativa descartada:* ruta propia `/login/email`. Da el botón atrás gratis, pero obliga a abrir una excepción en el `redirect` (hoy solo deja pasar `matchedLocation == '/login'`) y a compartir el cubit entre dos rutas.

### 2. Contrato de `AuthClient`

Se agregan `Future<void> requestEmailCode(String email)` y `Future<AuthResult> verifyEmailCode({required String email, required String code})`. `requestEmailCode` llama `signInWithOtp(email:)` (con `shouldCreateUser` por defecto, que crea la cuenta) y `verifyEmailCode` llama `verifyOTP(type: OtpType.email)`. No hay estado `cancelled` en este flujo; `verifyEmailCode` devuelve `AuthResult.success` o lanza `AuthException(AppErrorCode)`.

Mapeo de errores en `SupabaseAuthClient` (único lugar que conoce los códigos de Supabase):

| Supabase (`code`) | `AppErrorCode` nuevo |
|---|---|
| `otp_expired` (incluye código incorrecto) | `invalidEmailCode` |
| `over_email_send_rate_limit`, `over_request_rate_limit` | `tooManyAuthRequests` |
| `validation_failed` o correo con formato inválido | `invalidEmail` |
| error de red / timeout | `network` / `timeout` (existentes) |
| cualquier otro | `unknown` |

El formato del correo también se valida en el cubit antes de llamar al servidor (regex simple); el servidor sigue siendo la fuente de la verdad. Los tres códigos nuevos llevan su traducción en los 3 `.arb`.

### 3. Contador de reenvío en el cubit

`LoginCodeSent` guarda `resendAvailableAt` (hora absoluta). La UI muestra los segundos restantes con un `Timer` local del widget; el cubit no emite cada segundo. Reenviar vuelve a llamar `requestEmailCode` y reinicia `resendAvailableAt = ahora + 60 s`. Si el servidor rechaza con un límite más estricto que 60 s, el error `tooManyAuthRequests` se muestra tal cual y el contador se reinicia.

### 4. Aviso para cuentas de Apple/Google

Un texto fijo en la vista de correo (clave nueva en los 3 `.arb`). No se intenta detectar el caso: el correo oculto de Apple no tiene relación con el correo real y `signInWithOtp` no revela si un correo existe. Hoy hay 1 identidad Apple con correo `privaterelay` en `reevo`, así que el caso es real pero acotado.

### 5. Textos del correo y configuración de Supabase (manual)

Las plantillas "Magic link or OTP" y "Confirm sign up" se reemplazan por el mismo correo en inglés con `{{ .Token }}` (un correo sin cuenta recibe, según lo que se conoce de Supabase, la de "Confirm sign up"; la documentación no lo confirma de forma explícita, así que se comprueba en la prueba con un correo nuevo) (asunto con el código y la marca; cuerpo corto que indica que el código vence en 10 minutos). El correo va solo en inglés por ahora: las plantillas de Supabase son únicas por proyecto, y localizarlo exigiría conocer el idioma del usuario antes del login (queda como mejora futura). La expiración del OTP se fija en 10 minutos (Authentication → Providers → Email). El envío sale por SMTP de Resend con un subdominio verificado de `getreevo.co` (por ejemplo `auth.getreevo.co`, remitente `no-reply`), para no chocar con los registros MX/SPF que ya sirven a `support@getreevo.co`. Al activar el SMTP propio, Supabase subió el límite de envío de 2 a 30 correos/hora (confirmado en los logs de auth de `reevo-dev`), que se mantiene por debajo del tope de 100/día del plan gratuito de Resend en la escala actual.

### 6. Telemetría

`LoginCubit` ya registra `login_completed` con `method`; el flujo de correo registra `method: email` solo tras `verifyEmailCode` exitoso. No se agregan eventos por paso. `product-analytics` ya cubre "iniciar sesión" en general, así que no requiere delta.

### 7. Presentación y compatibilidad

El formulario mantiene `kLoginMaxContentWidth` (400) en todos los pasos, así que en iPad sigue centrado y no afecta rail ni master-detail (el login no pasa por el shell). El campo de código usa teclado numérico, `autofillHints: [AutofillHints.oneTimeCode]` y `maxLength: 6`. Todos los widgets reciben el cubit por `BlocProvider` y sin lógica de negocio.

## Risks / Trade-offs

- [Sin SMTP propio el flujo no funciona para usuarios reales] → Tarea de configuración previa a probar en dispositivo; el código puede probarse con correos de miembros del equipo mientras tanto.
- [Código incorrecto y expirado indistinguibles] → Un solo mensaje ("inválido o expirado") que sugiere pedir uno nuevo.
- [Dos cuentas para quien usó Apple con correo oculto y luego el correo real] → Aviso en la vista de correo; no se vincula automáticamente.
- [Tope de 100 correos/día en Resend gratis] → Suficiente a la escala actual; el reenvío con 60 s limita el abuso; subir a plan de pago si se acerca.
- [Plantilla de usuarios nuevos y tipo de verificación] → Si un correo nuevo recibe el código pero `verifyOTP(type: email)` lo rechaza, se prueba con `OtpType.signup` para ese caso. Se confirma en dispositivo con un correo sin cuenta (tarea 5.4).
- [PKCE de `signInWithOtp`] → `signInWithOtp` genera un `code_challenge` PKCE; el OTP se verifica con `verifyOTP`. Se confirma en dispositivo que el código llega y entra (tarea de verificación), por si algún ajuste de la plantilla hiciera falta.
- [Más estados en `LoginState`] → Se cubren con tests de cubit para cada transición y con un test de widget por vista.

## Migration Plan

1. Configurar Resend, el DNS y Supabase (SMTP, plantilla, expiración) primero en `reevo-dev` y probar un ciclo completo.
2. Repetir en `reevo` (prod) antes de publicar una build con el login por correo.
3. Verificar con el MCP de Supabase: usuarios nuevos en `auth.users`, logs de auth y advisors.
4. Rollback: ocultar el botón (revertir el PR); los usuarios creados por correo siguen existiendo y no afectan a los demás métodos.
