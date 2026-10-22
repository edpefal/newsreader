## 1. Mensaje con la alternativa

- [x] 1.1 Actualizar `errorTooManyAuthRequests` en `lib/l10n/app_en.arb`, `app_es.arb` (español neutro con tuteo) y `app_fr.arb`, sugiriendo intentar más tarde o entrar con Google o Apple
- [x] 1.2 Correr `flutter gen-l10n` y ajustar los tests de widget o de errores que comparen el texto anterior

## 2. Telemetría del límite

- [x] 2.1 En `LoginCubit`, reportar con `captureMessage` (nivel advertencia) `login_email_rate_limited: send` en `submitEmail`, `login_email_rate_limited: verify` en `verifyCode` y `login_email_rate_limited: resend` en `resendCode` cuando el error es `AppErrorCode.tooManyAuthRequests`
- [x] 2.2 Tests de `LoginCubit` con `bloc_test`: cada paso reporta su mensaje con nivel advertencia; otros errores (código inválido, correo inválido, red, desconocido) no lo reportan; el mensaje no incluye el correo

## 3. Verificación

- [x] 3.1 Correr `flutter analyze` y `flutter test` sin warnings ni fallos
- [x] 3.2 Formatear solo los archivos tocados y revisar `git diff --stat`
- [x] 3.3 Prueba manual del usuario (simulador o dispositivo, contra `reevo-dev`): provocar el límite (varios códigos seguidos con distintos correos o reenvíos) y comprobar el mensaje con la alternativa y que aparece el issue `login_email_rate_limited: send` en Sentry con entorno `development`

## 4. Configuración manual (fuera del repo)

- [x] 4.1 En Sentry, crear una regla de alerta de issues para los mensajes `login_email_rate_limited: send` y `login_email_rate_limited: resend` (3 o más ocurrencias en una hora), solo en el entorno `production`, con aviso por correo; excluir `verify`. Creada como "Email login rate limit (send/resend)" (id 6170178, proyecto `reevo-prod`, aviso por correo a tu usuario, como máximo una vez por hora)
- [x] 4.2 Anotar en la memoria del proyecto los topes vigentes (Supabase 30 correos/h, Resend free 100/día) y las opciones descartadas para retomarlas si aparece abuso

## 5. Cierre

- [x] 5.1 Archivar el change con `openspec archive add-email-rate-limit-signal --yes` en el mismo PR final
