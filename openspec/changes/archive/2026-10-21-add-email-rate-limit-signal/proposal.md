## Why

Los límites de envío de correos de Supabase Auth (30/h con SMTP propio) y de Resend (100/día en el plan gratuito) son **globales**, no por IP, y la anon key es pública: cualquiera puede llenarlos con un script y dejar sin login por correo a todos los usuarios. Un proxy con límite por IP no lo evita, porque el endpoint `/auth/v1/otp` sigue abierto. Mientras no haya señales de abuso real, se acepta una degradación controlada (Google y Apple siguen funcionando), pero hoy el usuario que choca con el límite solo ve "espera un momento", que no sirve si el tope dura horas, y nadie se entera de que está pasando.

## What Changes

- El mensaje de error `tooManyAuthRequests` pasa a ofrecer la salida: intentar más tarde o entrar con Google o Apple. Sin botón nuevo: la flecha atrás de los pasos del correo y del código ya lleva a los botones de Google y Apple. Texto nuevo en los 3 `.arb` (en, es, fr).
- `LoginCubit` reporta a Sentry un mensaje de advertencia `login_email_rate_limited: <step>` (`send`, `resend` o `verify`) cuando un envío, reenvío o verificación falla por `tooManyAuthRequests`. Cada paso es un issue distinto. Sin correo ni ningún dato personal.
- Paso manual: crear en Sentry una regla de alerta por correo sobre esos issues, solo para `send` y `resend` (tope global de correos) y en el entorno `production`. `verify` es el límite por IP al verificar y no cuenta como bloqueo global.
- Fuera de alcance, anotado en `design.md`: CAPTCHA nativo, Send Email Hook con cupos, chequeo programado del consumo y subir los topes de Supabase o el plan de Resend.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `user-auth`: nuevo requirement que exige que el aviso por límite de envíos ofrezca la alternativa de Google o Apple.
- `observability`: nuevo requirement para la señal `login_email_rate_limited` reportada a Sentry, con el paso en el mensaje.

## Impact

- Código: `lib/features/auth/presentation/cubit/login_cubit.dart`, `lib/l10n/app_en.arb`, `app_es.arb`, `app_fr.arb`, y sus tests (`login_cubit_test.dart`; `neutral_spanish_test.dart` cubre el `.arb` en español).
- Solo cliente: sin migraciones, Edge Functions ni cambios de servidor, y sin impacto en clientes ya publicados.
- Depende de que `add-email-otp-login` esté en `main` (ya mergeado, PR #70); no de que esté archivado, porque los requirements de este change son ADDED.
- Configuración manual fuera del repo: la regla de alerta en Sentry.
