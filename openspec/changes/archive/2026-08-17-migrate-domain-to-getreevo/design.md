## Context

Ver `proposal.md` para la motivación. Datos relevantes para el approach:

- La dirección de email (`<uuid>@<EMAIL_DOMAIN>`) no se persiste en ningún lado: `create-feed` (`supabase/functions/create-feed/index.ts`) la arma en el momento de la respuesta, leyendo `Deno.env.get("EMAIL_DOMAIN")` cada vez. Solo el `id` (UUID) se guarda en `generated_feeds`. Esto significa que actualizar el secret no requiere ninguna migración de datos — el próximo feed creado usa el dominio nuevo automáticamente.
- El feed RSS que la app sincroniza vive en `<SUPABASE_URL>/functions/v1/feed/<id>` — dominio de Supabase, no del dominio de email. Ese dato tampoco se ve afectado.
- `EMAIL_DOMAIN` solo está configurado en el proyecto Supabase de producción (`split-dev-prod-backend-config` dejó dev sin esta feature, aceptado como limitación conocida).
- `reevo-web` hoy no tiene dominio custom configurado en Vercel (`reevo-web-legal-pages` lo dejó explícitamente para un change incremental).
- El plan Enhanced Protection de ForwardEmail.net ya está pago sobre la cuenta usada para `image2svg.app`; se asume (a confirmar al ejecutar) que permite agregar un dominio adicional sin cargo extra, dado que el pago es por cuenta/plan y no por dominio individual en su modelo actual.

## Goals / Non-Goals

**Goals:**
- Un solo dominio (`getreevo.co`) sirviendo tanto `reevo-web` (root) como el email-to-RSS (`inbox.` subdominio).
- Cero cambios de código: todo el trabajo es configuración externa (DNS, ForwardEmail, Vercel, Supabase secret, Superwall).
- Corte limpio: sin redirect ni período de convivencia entre `image2svg.app` y `getreevo.co`.

**Non-Goals:**
- No se registra un dominio propio para nada más allá de `reevo-web` + email (p.ej. no se arma email corporativo tipo `hola@getreevo.co`).
- No se automatiza el registro de DNS ni la conexión a Vercel/ForwardEmail — son pasos manuales ejecutados una sola vez, igual que el criterio ya usado en `email-to-rss-generated-feeds`.
- No se migra ningún dato: no hay direcciones ni feeds existentes que dependan de `image2svg.app` (confirmado: sin usuarios reales todavía).

## Decisions

### 1. Dominio único compartido entre `reevo-web` y email-to-RSS
Se descarta mantener dos dominios separados (uno para el sitio, otro dedicado solo al email) porque no hay ninguna razón técnica para separarlos — Vercel controla los registros del dominio raíz (A/CNAME/ALIAS) y ForwardEmail solo necesita MX/TXT en el subdominio `inbox.`, sin colisión entre ambos. Un solo dominio también es más barato (una sola renovación anual) y más simple de recordar/comunicar.

### 2. Reusar la cuenta existente de ForwardEmail, agregando el dominio nuevo
En vez de crear una cuenta nueva, se agrega `getreevo.co` a la cuenta ya paga (Enhanced Protection) usada para `image2svg.app`. Mismo dashboard, mismo webhook de destino, mismo `FORWARDEMAIL_WEBHOOK_SECRET` — solo cambia el dominio de origen del catch-all. Si el plan actual no permite múltiples dominios sin costo adicional (a confirmar en el dashboard al ejecutar), el fallback es sumar el costo incremental que corresponda; no cambia el approach.

### 3. Corte limpio, sin redirect del dominio viejo
Dado que no hay usuarios reales usando `inbox.image2svg.app` (confirmado con el usuario), no se justifica mantenerlo activo en paralelo ni configurar un redirect — se deja de renovar cuando corresponda. Si en el futuro apareciera evidencia de un usuario real afectado, sería un fix puntual (reactivar el dominio temporalmente), no algo que este change necesite prevenir de antemano.

### 4. Orden de ejecución: validar el dominio nuevo antes de tocar el secret de producción
Se configura y verifica `inbox.getreevo.co` en ForwardEmail (incluyendo un email de prueba de punta a punta) **antes** de actualizar `EMAIL_DOMAIN` en Supabase. Así, si algo falla en la configuración de DNS/ForwardEmail, la feature en producción sigue funcionando con el dominio viejo hasta que el nuevo esté confirmado.

## Risks / Trade-offs

- **[Riesgo] El plan de ForwardEmail podría no incluir múltiples dominios sin costo adicional** → Mitigación: se revisa el dashboard/pricing antes de comprometerse; el costo incremental (si existe) es aceptable dado que ya se paga por esta infraestructura.
- **[Riesgo] Actualizar `EMAIL_DOMAIN` en producción sin haber validado antes el dominio nuevo dejaría la feature rota para cualquier feed creado en el medio** → Mitigación: Decisión 4 (validar primero, cambiar el secret después).
- **[Trade-off] Dejar vencer `image2svg.app` en vez de mantenerlo con redirect** → Aceptado porque no hay usuarios reales; si aparece un caso real más adelante, se resuelve puntualmente.

## Migration Plan

1. Registrar `getreevo.co`.
2. Conectar `getreevo.co` como dominio custom en el proyecto Vercel de `reevo-web`; verificar `/terms` y `/privacy` sirviendo desde el dominio nuevo.
3. Agregar `getreevo.co` a la cuenta de ForwardEmail; configurar MX/SPF de `inbox.getreevo.co` y el catch-all + forwarding recipient hacia el webhook existente de `inbound-email` (mismo secret compartido).
4. Probar de punta a punta: crear un feed de prueba (`create-feed` en un ambiente donde se pueda apuntar `EMAIL_DOMAIN=inbox.getreevo.co` manualmente o vía script), reenviar un email real a la dirección resultante, confirmar que aparece como `feed_item` y sincroniza en la app.
5. Actualizar el secret `EMAIL_DOMAIN` en el proyecto Supabase de producción a `inbox.getreevo.co`.
6. Actualizar los links de Terms/Privacy en el editor de Superwall (paywall `255848`) a las URLs del dominio nuevo, tocando el botón Publish real de la UI.
7. Confirmar visualmente el paywall con los links nuevos.
8. Dejar `image2svg.app` sin renovar (no se cancela activamente, simplemente no se renueva en su próximo vencimiento).

No hace falta rollback de datos (nada se migra); si algo falla, el rollback es simplemente no actualizar `EMAIL_DOMAIN` y seguir un paso más tarde.
