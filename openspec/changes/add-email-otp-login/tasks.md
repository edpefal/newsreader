## 1. Configuración de infraestructura (manual, no es código)

- [x] 1.1 Crear la cuenta de Resend, agregar un subdominio de envío de `getreevo.co` (por ejemplo `auth.getreevo.co`) y verificar SPF y DKIM en el DNS, sin tocar los registros que ya sirven a `support@getreevo.co`
- [x] 1.2 Generar las credenciales SMTP de Resend y cargarlas en Supabase (Authentication → SMTP Settings) en `reevo-dev`, con remitente `no-reply` del subdominio verificado
- [x] 1.3 En `reevo-dev`: reemplazar las plantillas "Magic link or OTP" y "Confirm sign up" (un correo sin cuenta recibe esta última) por un correo solo en inglés con `{{ .Token }}` en lugar de `{{ .ConfirmationURL }}`, y fijar la expiración del OTP en 600 s (Authentication → Sign In / Providers → Email)
- [x] 1.4 En `reevo-dev`: revisar los límites de envío tras activar el SMTP propio (por defecto 30/hora) contra el tope de 100/día del plan gratuito de Resend
- [ ] 1.5 Repetir 1.2 a 1.4 en `reevo` (prod, con su propia API key de Resend `supabase-auth-prod`) antes de publicar una build con el login por correo

## 2. Cliente de autenticación

- [x] 2.1 Agregar a `AuthClient` los métodos `requestEmailCode(String email)` y `verifyEmailCode({required String email, required String code})`
- [x] 2.2 Implementarlos en `SupabaseAuthClient` con `signInWithOtp` y `verifyOTP(type: OtpType.email)`, mapeando los códigos de error de Supabase a `AppErrorCode` según el design
- [x] 2.3 Agregar los `AppErrorCode` `invalidEmailCode`, `tooManyAuthRequests` e `invalidEmail`, su traducción en `AppErrorCodeL10n` y los mensajes en `app_en.arb`, `app_es.arb` (español neutro con tuteo) y `app_fr.arb`
- [x] 2.4 Tests del mapeo de errores de `SupabaseAuthClient` (código inválido o expirado, límites, correo inválido, red) con un cliente de Supabase simulado

## 3. Estado y lógica del login

- [x] 3.1 Agregar a `LoginState` los estados de la vista de correo y de código (con `email` y `resendAvailableAt`), conservando `Equatable`
- [x] 3.2 En `LoginCubit`: abrir el flujo de correo, validar el formato del correo, pedir el código, verificarlo, reenviar (reinicia el contador de 60 s), cambiar de correo y volver atrás
- [x] 3.3 Registrar `login_completed` con `method: email` solo tras una verificación exitosa
- [x] 3.4 Tests de cubit (`bloc_test`) para cada transición: éxito, correo inválido, código inválido, límite de envíos, reenvío, cambiar correo, volver, y que un fallo no registra el evento

## 4. Pantalla de login

- [x] 4.1 En `LoginScreen`, agregar bajo Google y Apple el separador "o" y el botón de texto "Continuar con correo", y elegir la vista según el estado del cubit
- [x] 4.2 Crear la vista de correo (campo de correo, aviso para quien entró con Apple o Google, botón de enviar) y la vista de código (campo de 6 dígitos con teclado numérico y `autofillHints: oneTimeCode`, verificar, reenviar con contador, cambiar correo), un widget por archivo y en `presentation/`
- [x] 4.3 Interceptar el botón atrás con `PopScope` según el estado, sin interceptarlo en la vista inicial
- [x] 4.4 Mantener `kLoginMaxContentWidth` (400) en todas las vistas y razonar el comportamiento a ≥840dp: el login no pasa por el shell, así que no afecta rail ni master-detail
- [x] 4.5 Agregar los textos de la UI (botón, separador, etiquetas, aviso, contador, reenviar) en los 3 `.arb`, correr `flutter gen-l10n` y el test de español neutro
- [x] 4.6 Tests de widget: el login ofrece los tres métodos, navegación entre vistas, aviso visible, contador deshabilitado y luego habilitado, y el atrás del sistema

## 5. Verificación y cierre

- [x] 5.1 `flutter analyze` sin warnings y `flutter test` en verde
- [x] 5.2 `dart format` solo sobre los archivos tocados y revisar `git diff --stat`
- [x] 5.3 `openspec validate add-email-otp-login --strict`
- [ ] 5.4 Prueba manual del usuario en `reevo-dev`: correo nuevo (crea cuenta), correo de una cuenta de Google existente (misma cuenta), código incorrecto, reenvío, cambiar correo y atrás, probados el 2026-10-13 en simulador; pendiente solo el autocompletado del código desde Mail en un iPhone real
- [x] 5.5 Verificar con el MCP de Supabase en `reevo-dev`: los usuarios nuevos en `auth.users`, los logs de auth sin errores y los advisors
- [ ] 5.6 Abrir PR contra `main`, esperar `analyze-and-test` en verde y mergear; repetir la prueba contra `reevo` (prod) y archivar el change (`openspec archive add-email-otp-login --yes`) en el mismo PR final; borrar la rama
