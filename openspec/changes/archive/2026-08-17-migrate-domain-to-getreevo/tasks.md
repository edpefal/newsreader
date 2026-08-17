## 1. Dominio y Vercel

- [x] 1.1 Registrar el dominio `getreevo.co` en Namecheap. **Hecho** — dominio ya comprado, DNS todavía sin configurar.
- [x] 1.2 En Namecheap, cambiar los nameservers de `getreevo.co` a `ns1.vercel-dns.com` y `ns2.vercel-dns.com` (delegación completa de DNS). **Hecho** — confirmado propagado vía `dig`/WHOIS contra Google (8.8.8.8) y Cloudflare (1.1.1.1); el check interno de `vercel domains inspect` puede tardar en reflejarlo (verificación por email pendiente), pero la propagación real ya está lista.
- [x] 1.3 Conectar `getreevo.co` como dominio custom del proyecto Vercel de `reevo-web`. **Hecho** (`vercel domains add getreevo.co reevo-web`) — pendiente de que se complete la delegación de nameservers (1.2) para que Vercel emita el certificado.
- [x] 1.4 Verificar que `https://getreevo.co/terms` y `https://getreevo.co/privacy` respondan correctamente (200, contenido correcto). **Hecho** — `curl` confirma 200 en `/`, `/terms` y `/privacy`.

## 2. ForwardEmail

- [x] 2.1 Agregar `inbox.getreevo.co` a la cuenta existente de ForwardEmail.net. **Hecho** — sin costo adicional visible, mismo plan Enhanced Protection.
- [x] 2.2 En el panel DNS de Vercel, agregar los registros MX y SPF/TXT de `inbox.getreevo.co` que pidió ForwardEmail. **Hecho** — 2 MX (`mx1`/`mx2.forwardemail.net`) + 1 TXT de verificación, vía `vercel dns add`.
- [x] 2.3 Configurar el catch-all (`*@inbox.getreevo.co`) en el dashboard de ForwardEmail, con el mismo forwarding recipient (URL del webhook `inbound-email` + `?secret=...`) ya usado para `image2svg.app`. **Hecho** — mismo secret, mismo endpoint (`.../functions/v1/inbound-email?secret=...`).
- [x] 2.4 Verificar en el dashboard que `inbox.getreevo.co` queda validado. **Hecho** — "Verify" pasó correctamente. Falta activar el catch-all (2.3).

## 3. Prueba de punta a punta antes de tocar producción

- [x] 3.1 Crear un feed de prueba descartable (`generated_feeds`, sin pisar el secret `EMAIL_DOMAIN` de producción). **Hecho** — id `67f51f88-33ca-456e-aaad-fc7a71107fee` (`inbound-email` solo usa la parte antes del `@`, así que sirve para probar `inbox.getreevo.co` sin depender del secret).
- [x] 3.2 Reenviar un email real a `67f51f88-33ca-456e-aaad-fc7a71107fee@inbox.getreevo.co`. **Hecho.**
- [x] 3.3 Confirmar que el email llega como `feed_item` en Supabase y que el feed RSS resultante sincroniza correctamente. **Hecho** — item "test reevo" de `edpefal@gmail.com` persistido y servido en el XML del feed (`GET /functions/v1/feed/<id>`).

## 4. Corte a producción

- [x] 4.1 Actualizar el secret `EMAIL_DOMAIN` a `inbox.getreevo.co` en el proyecto Supabase de producción. **Hecho** (`supabase secrets set`).
- [x] 4.2 Crear un feed real desde la app y confirmar que la dirección devuelta usa `inbox.getreevo.co`. **Hecho** — probado con `flutter run --dart-define=APP_ENV=prod` (el intento inicial falló porque `flutter run` sin dart-define apunta a `reevo-dev`, que nunca tuvo `EMAIL_DOMAIN` configurado — comportamiento esperado, no relacionado a esta migración).

## 5. Superwall

- [x] 5.1 Actualizar los links de Términos de Servicio / Política de Privacidad en el editor del paywall publicado (`255848`) a `https://getreevo.co/terms` y `https://getreevo.co/privacy`. **Hecho** vía `superwall-editor` (`set_click_behavior` sobre los nodos "Terms"/"Privacy", verificado con `get_node_info`).
- [x] 5.2 Republicar el paywall tocando el botón Publish real de la UI del editor (no vía API cruda). **Hecho** — confirmado con `get_paywall`: `updated_at` y `paywall_url` cambiaron tras publicar.
- [x] 5.3 Confirmar visualmente en el paywall que ambos links apuntan al dominio nuevo y funcionan. **Hecho** — screenshot del editor muestra "Terms"/"Privacy" en el footer (URLs ya actualizadas y verificadas por nodo en 5.1).

## 6. Cierre

- [ ] 6.1 Dejar `image2svg.app` sin renovar (no cancelar activamente; simplemente no renovar en su próximo vencimiento).
