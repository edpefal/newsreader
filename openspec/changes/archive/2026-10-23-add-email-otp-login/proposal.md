## Why

Hoy la app solo permite entrar con Google o Apple. Un usuario sin una cuenta de esos proveedores (o que prefiere no usarlos) no puede usar la app, y no hay un método de acceso que no dependa de un tercero. Agregar un login con correo y código de un solo uso (OTP) cubre ese hueco sin introducir contraseñas ni deep links.

## What Changes

- Nuevo método de inicio de sesión con correo: el usuario escribe su correo, recibe un código de 6 dígitos (válido 10 minutos) y lo escribe en la app para obtener la sesión. Un correo sin cuenta la crea automáticamente, igual que Google y Apple.
- La pantalla de login agrega, bajo los botones de Google y Apple, un separador "o" y un botón de texto "Continuar con correo".
- El flujo vive como estados internos de `/login` (correo → código enviado) en el mismo `LoginCubit`, con soporte del botón atrás. No cambian el router ni el `redirect`.
- En la vista de código: reenvío con contador de 60 s, opción de cambiar el correo y autocompletado del código desde el correo en iOS.
- La vista de correo muestra un aviso para quien entró antes con Apple o Google (el correo oculto de Apple no se une con el correo real, y en ese caso se vería una cuenta vacía).
- Errores nuevos con mensaje localizado: código inválido o expirado, demasiados intentos o envíos, y correo inválido.
- Se registra el evento `login_completed` con `method: email`.
- Textos nuevos en los 3 `.arb` (en, es, fr).
- Configuración manual de infraestructura (no es código), en `reevo` y `reevo-dev`: SMTP propio con Resend sobre un subdominio de envío de `getreevo.co`, plantillas de correo con el código (por ahora solo en inglés), expiración del OTP en 10 minutos y revisión de los límites de envío. Queda como checklist en las tareas.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `user-auth`: nuevo requirement de inicio de sesión con correo y código (incluye creación automática de cuenta, reenvío, cambio de correo, aviso para cuentas de Apple/Google y errores), y la pantalla de login pasa a ofrecer tres métodos.

## Impact

- Código: `lib/core/auth/` (`AuthClient` y `SupabaseAuthClient`: pedir y verificar código), `lib/features/auth/presentation/` (`LoginCubit`, `LoginState`, `LoginScreen` y vistas nuevas), `lib/core/errors/` (códigos nuevos y su traducción), `lib/l10n/*.arb`.
- Tests: cubit, pantalla de login y `SupabaseAuthClient` (si hay cobertura), más el test de español neutro para los textos nuevos.
- Servidor: sin migraciones ni Edge Functions. Solo configuración de Supabase Auth (SMTP, plantilla, expiración) hecha a mano en el dashboard.
- Clientes ya publicados: sin impacto; no se elimina ni cambia ningún recurso que usen, así que no aplica la regla de orden de despliegue. Cambiar la plantilla Magic Link no afecta a nadie porque ningún cliente actual usa ese flujo.
- Dependencia externa: cuenta en Resend y DNS de `getreevo.co` (el dominio raíz ya recibe `support@getreevo.co`, por eso el envío va por un subdominio).
