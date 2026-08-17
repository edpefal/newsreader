## 1. Setup del proyecto

- [x] 1.1 Crear proyecto Next.js (App Router, TypeScript) en `/Users/eder/Development/reevo-web`.
- [x] 1.2 Inicializar repositorio Git separado del repo Flutter.
- [x] 1.3 Confirmar autenticación de Vercel CLI (`vercel whoami`) y vincular el proyecto (`vercel link`) — proyecto `artlabstudio/reevo-web`.

## 2. Contenido legal

- [x] 2.1 Redactar borrador de Términos de Servicio, basado en el comportamiento real de la app (auth Supabase, gestión de fuentes/artículos, resúmenes con IA, suscripción vía Superwall/App Store).
- [x] 2.2 Redactar borrador de Política de Privacidad, cubriendo qué datos se recolectan, con qué proveedores se comparten (Supabase, Superwall/Apple, Gemini para los resúmenes), y cómo el usuario puede borrar su cuenta/datos.
- [x] 2.3 Confirmar con el usuario que revisó/ajustó ambos textos antes de publicar. Ajustes pedidos y aplicados: sin nombre personal, lenguaje neutral de plataforma (no específico a iOS/App Store, ya que se planea Android/desktop/web a futuro), y corregida la afirmación desactualizada de archivo automático a los 30 días (verificado en `openspec/specs/article-lifecycle/spec.md` y `migrate_archived_articles.dart` que esa política ya no existe).

## 3. Páginas

- [x] 3.1 Página `/terms` que renderiza el contenido de Términos de Servicio.
- [x] 3.2 Página `/privacy` que renderiza el contenido de Política de Privacidad.
- [x] 3.3 Layout mínimo compartido (header/footer simple) sin construir la landing page todavía — build local verificado (`npm run build`), rutas `/terms` y `/privacy` generadas como estáticas.

## 4. Deploy y verificación

- [x] 4.1 Deploy a producción en Vercel (`vercel --prod` o vía dashboard) — alias `https://reevo-web.vercel.app`.
- [x] 4.2 Confirmar que `/terms` y `/privacy` responden 200 en el dominio `.vercel.app` asignado.
- [x] 4.3 Anotar las URLs finales para el siguiente paso: `https://reevo-web.vercel.app/terms`, `https://reevo-web.vercel.app/privacy`.

## 5. Conectar con Superwall

- [x] 5.1 Conectar con la skill `superwall-editor` al paywall publicado (`255848`).
- [x] 5.2 Setear el `click_behavior` de los links "Terms" y "Privacy" del footer a las URLs de producción (`open-url`, `urlType: in-app-browser`) → `https://reevo-web.vercel.app/terms` y `/privacy`.
- [x] 5.3 Republicar el paywall desde el botón Publish de la UI del editor. Confirmado vía `get_paywall`: nuevo document id, `products` sigue poblado.
- [x] 5.4 Confirmar visualmente (Web Inspector o tap en dispositivo) que los links abren las páginas correctas. Confirmado por el usuario 2026-08-16: ambos links funcionan bien en el paywall real.

## 6. Cierre

- [x] 6.1 Actualizar `openspec/changes/gate-daily-summary-behind-superwall-paywall/tasks.md` sección 8.4 marcando el punto de Terms/Privacy como resuelto.
