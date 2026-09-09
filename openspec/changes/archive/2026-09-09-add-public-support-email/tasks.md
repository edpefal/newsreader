## 1. Configuración de correo

- [x] 1.1 Confirmar en ForwardEmail que el plan actual admite agregar `getreevo.co` y registrar el dominio raíz en la cuenta existente.
- [x] 1.2 Agregar en Vercel DNS los registros MX y TXT requeridos por ForwardEmail para `getreevo.co`, sin modificar los registros de `inbox.getreevo.co`.
- [x] 1.3 Confirmar que el catch-all activo `*@getreevo.co` reenvía `support@getreevo.co` a `edpefal@gmail.com`, sin modificarlo.
- [x] 1.4 Enviar un correo de prueba desde una cuenta distinta y confirmar recepción en el buzón de destino.

## 2. Sitio público

- [x] 2.1 En `reevo-web`, reemplazar cada aparición pública de `edpefal@gmail.com` por `support@getreevo.co` en `/terms`, `/privacy` y `/support`, incluidos enlaces `mailto`.
- [x] 2.2 Ejecutar el build de `reevo-web` y desplegar el sitio en producción.
- [x] 2.3 Verificar que `/terms`, `/privacy` y `/support` muestran el correo nuevo y que sus enlaces `mailto` lo usan.

## 3. Verificación final

- [x] 3.1 Confirmar que `inbox.getreevo.co` conserva su routing MX hacia ForwardEmail; no se modificó su catch-all ni webhook de email-to-RSS.
