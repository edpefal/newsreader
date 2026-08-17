## Why

Hoy el flujo de email-to-RSS (`create-feed`/`inbound-email`) genera direcciones bajo `inbox.image2svg.app`, un dominio sin relación con el nombre de la app, comprado antes del rebrand a Reevo. En paralelo, `reevo-web` (Terms/Privacy, y futura landing) corre sobre el subdominio default de Vercel (`*.vercel.app`) porque no se configuró un dominio propio (decisión explícita de `reevo-web-legal-pages`, marcada ahí como mejora incremental). Registrar un solo dominio nuevo (`getreevo.co`) resuelve ambas cosas a la vez: reemplaza el nombre desalineado del email y le da a `reevo-web` una URL propia antes del lanzamiento, sin romper ningún feed existente (el feed RSS que consume la app vive en `*.supabase.co`, no en el dominio de email — cambiar el dominio solo afecta la dirección de forwarding hacia adelante). No hay usuarios reales todavía usando `inbox.image2svg.app`, así que es un corte limpio sin necesidad de período de transición.

## What Changes

- Se registra el dominio `getreevo.co`.
- El dominio raíz (`getreevo.co`) se conecta como dominio custom del proyecto Vercel de `reevo-web`, reemplazando el subdominio `*.vercel.app` para `/terms` y `/privacy`.
- El subdominio `inbox.getreevo.co` reemplaza a `inbox.image2svg.app` como dirección de recepción de email: se agrega el dominio nuevo a la cuenta existente de ForwardEmail.net, se configuran sus registros MX/SPF, y se recrea el catch-all + forwarding recipient hacia el mismo webhook (`inbound-email`), sin cambios en el código de la función.
- El secret `EMAIL_DOMAIN` del proyecto Supabase de producción pasa de `inbox.image2svg.app` a `inbox.getreevo.co`.
- Los links de Términos de Servicio / Política de Privacidad en el editor de Superwall se actualizan a las URLs del dominio nuevo.
- El dominio `image2svg.app` se deja vencer sin renovar (no se mantiene en paralelo ni se configura redirect, dado que no hay usuarios reales que dependan de él).

## Capabilities

_(sin cambios de comportamiento observable: mismo flujo de email-to-RSS, mismas páginas de Terms/Privacy, solo cambia el dominio de destino. `skip_specs: true` en `.openspec.yaml`.)_

### New Capabilities
(ninguna)

### Modified Capabilities
(ninguna — `email-to-rss-feeds` y `web-legal-pages` ya describen el dominio en términos genéricos, sin hardcodear `image2svg.app` ni `vercel.app`)

## Impact

- Registro de dominio nuevo: `getreevo.co` (fuera de este repo, en el registrador que use el usuario)
- Proyecto Vercel `reevo-web`: configuración de dominio custom
- Cuenta ForwardEmail.net: dominio nuevo agregado, DNS (MX/SPF) y catch-all reconfigurados
- Proyecto Supabase (prod): secret `EMAIL_DOMAIN`
- Dashboard de Superwall: links del footer del paywall publicado (`255848`)
- Ningún archivo de código en este repo cambia (`EMAIL_DOMAIN` ya se lee desde variable de entorno en `supabase/functions/create-feed/index.ts`)
