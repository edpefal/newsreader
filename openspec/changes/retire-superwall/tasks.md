## 1. Ya se puede hacer (1.11.0 publicada)

- [ ] 1.1 (a cargo del usuario) En App Store Connect, mover la URL de notificaciones del servidor de Apple a la de RevenueCat, para producción y sandbox, y comprobar en RevenueCat que empiezan a llegar notificaciones
- [ ] 1.2 Revisar la actividad de versiones anteriores a 1.11.0 en PostHog (`screen_view`, `$app_version`, `environment = production`) y en Sentry, una vez por semana, y anotar la última fecha vista

## 2. Cuando se cumpla el criterio (no antes del 2026-12-20)

- [ ] 2.1 Confirmar con PostHog y Sentry que ningún cliente 1.9.x/1.10.x tuvo actividad en los últimos 30 días, y acordar con el usuario ejecutar el retiro
- [ ] 2.2 (a cargo del usuario) Archivar el campaign y los paywalls en Superwall
- [ ] 2.3 Eliminar `superwall-webhook` de `reevo-dev` y, con confirmación del usuario, de `reevo`; borrar `SUPERWALL_WEBHOOK_SECRET` en ambos
- [ ] 2.4 Borrar `supabase/functions/superwall-webhook/` y su bloque `[functions.superwall-webhook]` de `supabase/config.toml`, y revisar el comentario de `supabase/functions/summarize-article/entitlement.ts`
- [ ] 2.5 Actualizar `CLAUDE.md` (fila de la tabla de Edge Functions y párrafo de orden de despliegue) y `README.md` (paywall, dependencias y árbol de funciones)
- [ ] 2.6 Correr `(cd supabase/functions/<nombre> && deno test --allow-env)` en las funciones restantes, `flutter analyze` y `flutter test`, y `openspec validate retire-superwall --strict`
- [ ] 2.7 (a cargo del usuario) Revocar la llave "Superwall" de App Store Connect
- [ ] 2.8 Archivar el change con `openspec archive retire-superwall --yes`
