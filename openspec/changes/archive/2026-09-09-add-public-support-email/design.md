## Context

`getreevo.co` sirve el sitio público desde Vercel. La cuenta existente de ForwardEmail ya recibe `inbox.getreevo.co` para el flujo email-to-RSS y reenvía esos mensajes al webhook de Supabase. Las tres páginas legales de `reevo-web` hoy publican `edpefal@gmail.com`.

## Goals / Non-Goals

**Goals:**

- Crear una dirección de contacto pública de Reevo sin crear un buzón nuevo.
- Reemplazar el correo personal en todas las páginas públicas que lo exponen.
- Preservar la entrega y el webhook de `inbox.getreevo.co`.

**Non-Goals:**

- Enviar correo saliente como `support@getreevo.co`.
- Construir formulario de soporte, sistema de tickets o automatizaciones de respuesta.
- Cambiar el flujo email-to-RSS, Supabase o Flutter.

## Decisions

### Reutilizar el catch-all existente de ForwardEmail

El dominio raíz `getreevo.co` se agrega a la cuenta existente de ForwardEmail. Su catch-all activo (`*@getreevo.co`) ya reenvía correo a `edpefal@gmail.com`, por lo que acepta `support@getreevo.co` sin crear un alias adicional. Este catch-all se preserva porque participa en el flujo existente de email-to-RSS.

Se descarta contratar Google Workspace o Zoho Mail porque este alcance solo requiere recepción y reenvío; ambos añaden un buzón y costo recurrente que no aportan comportamiento necesario.

### Separar registros web y de correo en Vercel DNS

Los registros MX y TXT de ForwardEmail se agregarán al dominio raíz administrado por Vercel. Estos registros coexisten con los registros web que sirven `getreevo.co`; no se modifican los registros de `inbox.getreevo.co`.

### Unificar el correo público

`reevo-web` usará `support@getreevo.co` en `/terms`, `/privacy` y `/support`. Un único canal simplifica contacto y evita inconsistencias entre documentos legales y soporte.

## Risks / Trade-offs

- [La cuenta o plan de ForwardEmail no permite agregar el dominio raíz sin costo] → Confirmar la capacidad y costo en el dashboard antes de cambiar DNS.
- [MX o TXT mal configurados pueden impedir recibir correo] → Verificar dominio y alias en ForwardEmail; enviar correo de prueba desde una cuenta distinta.
- [El responsable necesita responder como la dirección pública] → Añadir SMTP o un proveedor de buzón en un change posterior.

## Migration Plan

1. Confirmar que la cuenta existente de ForwardEmail admite `getreevo.co`.
2. Agregar `getreevo.co` y sus registros MX/TXT requeridos, preservando el catch-all existente.
3. Enviar correo de prueba a `support@getreevo.co` y confirmar recepción.
4. Actualizar las tres páginas de `reevo-web`, desplegar y verificar enlaces `mailto`.
5. Si la configuración falla, eliminar alias y registros nuevos; las páginas continúan mostrando la dirección anterior hasta el despliegue del cambio web.
