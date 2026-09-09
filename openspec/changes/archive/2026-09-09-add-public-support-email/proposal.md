## Why

Las páginas públicas de Términos, Privacidad y Soporte exponen una dirección personal de Gmail. Reevo necesita un canal de contacto que conserve la marca y no revele el correo personal del responsable.

## What Changes

- Usar `support@getreevo.co` como dirección pública de contacto, entregada por el catch-all existente de ForwardEmail al buzón personal.
- Reemplazar `edpefal@gmail.com` por `support@getreevo.co` en las páginas públicas `/terms`, `/privacy` y `/support` de `reevo-web`.
- Mantener el flujo existente `inbox.getreevo.co` para email-to-RSS sin cambios.

## Capabilities

### New Capabilities
- `public-support-email`: dirección de soporte con dominio de Reevo, disponible para contacto público y entregada al responsable.

### Modified Capabilities

- Ninguna.

## Impact

- Configuración DNS de `getreevo.co` en Vercel y catch-all existente de ForwardEmail.
- Repositorio externo `reevo-web`: páginas `/terms`, `/privacy` y `/support`.
- Sin cambios en Flutter, Supabase ni el webhook de email-to-RSS.
