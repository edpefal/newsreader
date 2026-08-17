## Why

El paywall de Superwall (change `gate-daily-summary-behind-superwall-paywall`) tiene dos links en el footer (Terms/Privacy) sin URL conectada — bloqueante para el submit a Apple, que exige links funcionales a Términos de Servicio y Política de Privacidad en cualquier app con suscripciones. Reevo no tiene ninguna presencia web hoy: no hay dominio, landing, ni páginas legales. Hace falta crear ese proyecto web ahora, con una base que sirva también para la landing de lanzamiento y, más adelante, una versión web de la app — sin tener que migrar de stack cuando llegue ese momento.

## What Changes

- Nuevo proyecto Next.js (`reevo-web`) en un repositorio separado del código Flutter (`/Users/eder/Development/reevo-web`), desplegado en Vercel.
- Páginas públicas `/terms` y `/privacy` con contenido legal real (borrador basado en el comportamiento actual de la app: auth vía Supabase, datos de fuentes/artículos/resúmenes del usuario, pagos vía Superwall/App Store — el usuario revisa y ajusta el texto antes de publicar).
- Estructura de proyecto estándar de Next.js (App Router), sin atajos que dificulten agregar rutas de landing o de la futura web app después.
- Conectar las URLs resultantes (`https://<dominio>/terms`, `https://<dominio>/privacy`) al footer del paywall publicado en Superwall vía la skill `superwall-editor`.
- Fuera de alcance de este change: contenido de landing page, versión web de la app, dominio personalizado final (se usa el dominio `.vercel.app` por defecto salvo que el usuario provea uno propio).

## Capabilities

### New Capabilities
- `web-legal-pages`: páginas públicas de Términos de Servicio y Política de Privacidad para Reevo, hosteadas en un proyecto Next.js/Vercel separado del código de la app, y conectadas al paywall de Superwall.

### Modified Capabilities

(ninguna — este change no toca requisitos de capacidades existentes de la app Flutter)

## Impact

- Nuevo repositorio/directorio fuera de este repo: `/Users/eder/Development/reevo-web` (Next.js + Vercel). No afecta código Flutter existente.
- `openspec/changes/gate-daily-summary-behind-superwall-paywall/tasks.md` sección 8.4 pasa de "Falta: Terms/Privacy sin URL real" a resuelto, una vez conectadas las URLs en el editor de Superwall.
- Sin cambios en Supabase, Superwall (fuera del click_behavior de los dos links del footer), ni en la app Flutter.
