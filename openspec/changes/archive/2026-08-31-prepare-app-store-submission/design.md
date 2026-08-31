## Context

Este change toca dos repositorios: `newsreader` (Flutter, este repo) para el flag de export compliance, y `reevo-web` (Next.js/Vercel, `/Users/eder/Development/reevo-web`) para la nueva página `/support`, siguiendo el mismo patrón que `/terms` y `/privacy` (capability `web-legal-pages`, archivada en `2026-08-16-reevo-web-legal-pages`). Ver `proposal.md` para el porqué de cada gap.

## Goals / Non-Goals

**Goals:**
- Dejar la app y la ficha de App Store Connect en condiciones de pasar un submit real a revisión.
- Reusar la infraestructura web ya existente (`reevo-web`) en vez de crear un proyecto o dominio nuevo.

**Non-Goals:**
- Diseño visual o copy de marketing de `/support` — texto funcional mínimo, mismo tratamiento visual que `/terms`/`/privacy`.
- Automatizar la carga de metadata de App Store Connect (age rating, categoría, Support URL) vía API — se carga a mano en la UI de ASC, documentado como checklist en `tasks.md`.
- Screenshots, ASO, copy de la ficha — change separado.

## Decisions

- **`/support` en `reevo-web`, no un formulario nuevo con backend propio**: reusa el mismo proyecto Next.js/Vercel que ya sirve `/terms` y `/privacy`, misma decisión que tomó `web-legal-pages` de centralizar la presencia web ahí. Contenido mínimo viable: dirección de email de contacto (o mailto:), sin necesidad de un formulario con backend en este change — se puede añadir después sin romper la URL.
- **Export compliance declarado en Info.plist, no vía pregunta manual en cada submit**: `ITSAppUsesNonExemptEncryption = false` es la forma estándar de Apple de evitar la pregunta repetida de compliance de cifrado; es correcto porque Reevo no implementa criptografía propia, solo TLS estándar de las librerías de red que ya usa (Supabase, Superwall, Sentry, PostHog).
- **Age rating, categoría y App Review Notes como checklist en `tasks.md`, no como requirement de ninguna spec**: son configuración de la ficha de App Store Connect, no comportamiento del sistema — no hay código ni URL que verificar, por eso no generan un requirement con escenario testeable.

## Risks / Trade-offs

- [Declarar acceso a contenido web sin filtrar puede subir el age rating (p. ej. a 17+)] → Aceptado conscientemente: es la respuesta honesta dado que el usuario puede suscribir cualquier feed RSS/newsletter sin moderación editorial de Reevo; declarar lo contrario arriesga un rechazo o expulsión posterior si Apple lo prueba con un feed de contenido adulto.
- [`/support` sin formulario con backend puede sentirse mínimo] → Aceptable para pasar el submit; se puede reforzar en un change posterior si el volumen de soporte lo justifica.
