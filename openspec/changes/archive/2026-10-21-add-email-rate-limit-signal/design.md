## Context

Supabase Auth aplica límites **globales** al envío de correos (30/h con SMTP propio, 360 OTP/h) y solo limita por IP la verificación (`/verify`). Resend free añade 100 correos/día y 3000/mes. La anon key va dentro de la app, así que cualquiera puede llamar a `/auth/v1/otp` directamente; un proxy con límite por IP (por ejemplo una Edge Function) no protege porque el endpoint original sigue abierto. Con peticiones a direcciones distintas, el intervalo de ~60 s por dirección tampoco ayuda: solo frena el bombardeo a una persona.

Consecuencia: un script puede llenar el tope y bloquear el login por correo de todos. Google y Apple no dependen de esos límites, así que el efecto es una degradación parcial, y quien ya tiene sesión no se ve afectado.

Hoy `mapEmailAuthError` ya convierte `over_email_send_rate_limit`, `over_request_rate_limit` y 429 en `AppErrorCode.tooManyAuthRequests`, y `LoginCubit` lo muestra con el texto "Demasiados intentos. Espera un momento e intenta de nuevo." (`errorTooManyAuthRequests`). Ese copy no ayuda si el tope dura horas, y nadie se entera de que ocurre.

## Goals / Non-Goals

**Goals:**
- Que el usuario bloqueado por el tope sepa que puede entrar con Google o Apple.
- Tener una señal medible, sin datos personales, de que usuarios reales están chocando con el límite, con la que se pueda configurar una alerta.

**Non-Goals:**
- Evitar el bloqueo. Solo un CAPTCHA lo hace de raíz; se decide que por ahora se acepta la degradación.
- Alertar *antes* de llegar al tope (chequeo programado del consumo).
- Cambiar topes de Supabase o el plan de Resend.

## Decisions

### 1. El aviso es solo texto, sin botón nuevo

El copy de `errorTooManyAuthRequests` pasa a sugerir intentar más tarde o entrar con Google o Apple. Los pasos del correo y del código ya tienen la flecha atrás (y el atrás del sistema), que llegan a la vista inicial con los botones. Un botón extra "usar Google o Apple" duplicaría `back()` y obligaría a distinguir un error especial en la UI.

Se reutiliza la misma clave, así que también aplica a `verify`, donde sugerir otro método sigue siendo válido: quien falla la verificación por límite por IP también puede entrar con Google o Apple.

*Alternativa descartada:* un `AppErrorCode` nuevo solo para el límite global. El cliente no puede distinguir con certeza el tope global del límite por IP al enviar (ambos llegan como 429/`over_*`), y el mismo mensaje sirve para los dos.

### 2. La señal va a Sentry como mensaje, desde `LoginCubit`

El cubit ya recibe `TelemetryClient`. En los tres puntos que capturan `AuthException` (`submitEmail`, `verifyCode`, `resendCode`) se llama `captureMessage('login_email_rate_limited: <step>', level: warning)` cuando `e.code == AppErrorCode.tooManyAuthRequests`, con `step` igual a `send`, `verify` o `resend`. Se hace en el cubit y no en `SupabaseAuthClient` porque el cubit conoce el paso.

Sentry agrupa los mensajes por su texto, así que cada paso es un issue distinto sin necesidad de añadir tags ni cambiar `TelemetryClient`. Eso permite alertar solo sobre `send` y `resend` (el tope global de correos) y dejar `verify` (el límite por IP al verificar: alguien que se equivocó muchas veces o una red compartida) fuera de la alerta.

*Por qué Sentry y no PostHog:* se evaluó un evento de producto en PostHog, pero Sentry es mejor para alertar: las reglas de alerta por frecuencia son su función principal y avisan sin esperar al ciclo de evaluación de una insight; además el `environment` (`development`/`production`) ya es un campo nativo, mientras que PostHog tiene un solo proyecto para dev y prod y la alerta dependería de filtrar bien una super property. Lo que se pierde es ver la tendencia junto a `login_completed`; si hace falta, se puede añadir después el evento `trackEvent` sin cambiar nada más.

La señal solo se emite para `tooManyAuthRequests`: `SupabaseAuthClient` sigue reportando a Sentry únicamente los errores `unknown`, así que no hay duplicados.

### 3. La alerta es un paso manual en Sentry

Una regla de alerta de issues en el proyecto de Sentry: cuando un issue con el mensaje `login_email_rate_limited: send` o `login_email_rate_limited: resend` ocurre 3 o más veces en una hora, en el entorno `production`, avisar por correo. Es configuración en el panel, igual que las plantillas de Auth, y queda en `tasks.md` como paso manual. Se avisa cuando ya hay usuarios afectados (síntoma), no antes del tope; es una elección consciente por el tamaño actual.

## Fuera de alcance (anotado para más adelante)

| Opción | Cuándo retomarla |
|---|---|
| CAPTCHA nativo de Supabase (Turnstile o hCaptcha) | Si aparece abuso real. Es la única barrera efectiva contra scripts; exige WebView o widget en el login |
| Send Email Hook con cupos (reservar cupo a cuentas existentes) | Si el CAPTCHA no es aceptable. Complejo; no trae la IP |
| Chequeo programado del consumo (por ejemplo sobre `auth.one_time_tokens`) | Cuando haya más tráfico y haga falta avisar antes del tope |
| Subir el tope de correos/h de Supabase | Decisión de configuración del usuario; solo encarece el ataque (30 → 300/h son ~5 peticiones/min) |
| Resend Pro (~20 USD/mes: 50 000/mes, sin tope diario) | Cuando 100/día se quede corto. Con abuso, el bloqueo pasa a ser un gasto |

## Risks / Trade-offs

- [El bloqueo sigue siendo posible] → Aceptado: Google y Apple siguen funcionando y quien tiene sesión no se ve afectado; la alerta y el mensaje reducen el impacto, no lo eliminan.
- [La alerta llega tarde, cuando alguien ya chocó con el límite] → Aceptado por el tamaño actual; el chequeo del consumo queda anotado.
- [El mensaje también aparece por el límite por IP al verificar y sugiere otro método] → Es correcto y no engaña: entrar con Google o Apple sigue disponible.
- [Falsos positivos de la alerta por usuarios que reenvían demasiado] → El cooldown de 60 s del reenvío ya limita ese caso y el umbral de la alerta se calibra con datos reales.
