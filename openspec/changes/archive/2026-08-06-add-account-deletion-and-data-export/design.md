## Context

Ver `proposal.md` para la motivación (compliance de tiendas). El sistema de auth actual (`core/auth/auth_client.dart` + `supabase_auth_client.dart`) expone `currentAccessToken` y `currentUserId`, usado hoy para invocar Edge Functions autenticadas como el usuario (ver `sync-feeds`). `ClearLocalUserData` (`lib/features/sync/domain/usecases/clear_local_user_data.dart`) ya borra todo lo local al cerrar sesión y es reutilizable tal cual para el borrado de cuenta. Las tablas `sources`, `articles` y `daily_summaries` tienen RLS por `user_id` (capability `cloud-sync`), pero el cliente no tiene permisos para borrar su propia fila de `auth.users` — eso requiere `service_role` key, que nunca debe vivir en el cliente.

## Goals / Non-Goals

**Goals:**
- Borrado de cuenta verificable: al terminar, no debe quedar ninguna fila del usuario en Postgres ni en `auth.users`.
- Exportación que funcione completamente offline, ya que los datos de fuentes y favoritos ya están en Hive.
- Reusar `ClearLocalUserData` sin duplicar su lógica.

**Non-Goals:**
- Exportar artículos leídos completos ni el contenido HTML de los artículos — el proposal y las specs solo cubren fuentes (OPML) y favoritos (JSON).
- Período de gracia o "cuenta desactivada temporalmente" antes del borrado definitivo — el borrado es inmediato tras la confirmación, sin estado intermedio.
- Exportar/borrar datos de `generated_feeds`/`feed_items` (email-to-RSS) — quedan fuera de este change; se puede evaluar como extensión futura.

## Decisions

- **Edge Function nueva `delete-account` con `service_role` key**, invocada por el cliente pasando su `access_token` en el header de autorización (mismo patrón que `sync-feeds`). La función: (1) valida el JWT y extrae `user_id`, (2) borra en cascada `sources`/`articles`/`daily_summaries` de ese `user_id` (o confía en `ON DELETE CASCADE` si las FKs ya están configuradas así — a verificar en la migración existente), (3) llama a `supabase.auth.admin.deleteUser(user_id)`. Alternativa descartada: hacer el borrado de filas desde el cliente vía RLS normal y solo usar la Edge Function para el paso de `auth.admin` — se descarta porque deja una ventana donde el usuario pierde sus filas de datos pero conserva su cuenta si el segundo paso falla; mejor una sola operación atómica del lado del servidor.
- **Orden de operaciones en el cliente:** confirmar diálogo → invocar `delete-account` → si responde éxito, ejecutar `ClearLocalUserData.execute()` → `AuthClient.signOut()` → redirect a `/login` (mismo patrón que el logout actual en `router.dart`). Si la Edge Function falla, no se toca nada local — evita el estado inconsistente de "datos locales borrados pero cuenta viva en el servidor".
- **Exportación 100% client-side, sin Edge Function.** Fuentes y favoritos ya están completos en Hive; no hay necesidad de ir a Supabase. El OPML se genera con el paquete `xml` ya presente en `pubspec.yaml` (usado por el parseo de import); el JSON con `dart:convert` (`jsonEncode`), ambos sin nueva dependencia.
- **Compartir vía nueva abstracción `core/widgets/` o `core/utils/` sobre un plugin de share** (ej. `share_plus`), siguiendo la regla de CLAUDE.md de no importar librerías de terceros fuera de `core/`. Se define una interfaz mínima (`ShareFile` o similar) con una sola implementación concreta, igual que `HttpClient`/`FeedParser`.
- **Un feature nuevo `lib/features/account/`** (no reutilizar `auth/` ni `sync/` para no mezclar responsabilidades), con cuatro use cases: `DeleteAccount` (invoca la Edge Function, orquesta `ClearLocalUserData` + `AuthClient.signOut()` tras el éxito remoto), `ExportSourcesOpml` y `ExportFavoritesJson` (generan cada formato por separado, testeables de forma aislada), y `ExportUserData` como orquestador delgado que llama a los dos anteriores y al `FileSharer`. Mantener la orquestación en el use case (no en el widget/router) es consistente con la regla de "no lógica de negocio en Cubits/widgets" — el `router.dart` solo llama a `getIt<ExportUserData>().execute()` y maneja el error.
- **`FileSharer` vive en un módulo nuevo `core/sharing/`** (no en `core/widgets/`, ya que no es un widget sino una operación imperativa sin UI propia), siguiendo el mismo patrón de interfaz + implementación única que `core/network/` (`HttpClient`/`HttpPackageClient`) o `core/auth/` (`AuthClient`/`SupabaseAuthClient`).

## Risks / Trade-offs

- [Riesgo] Si `auth.admin.deleteUser` tiene éxito pero el borrado de filas de datos falla a mitad de camino (o viceversa), la cuenta queda en un estado inconsistente. → Mitigación: ejecutar el borrado de filas de datos y el `deleteUser` dentro de la misma Edge Function, en el orden (datos primero, luego `auth.users`), y loggear cualquier fallo parcial para revisión manual — no hay transacción distribuida real entre Postgres y el servicio de Auth de Supabase, así que el orden importa: si falla el borrado de auth después de borrar los datos, el usuario pierde sus datos pero técnicamente podría reintentar el borrado de cuenta (que ya no tiene nada que borrar en datos) y solo le faltaría el paso de `auth.users`.
- [Riesgo] Confusión de UX entre "Cerrar sesión" y "Eliminar cuenta" si están visualmente muy cerca. → Mitigación: la spec exige confirmación explícita e irreversible; la implementación debe diferenciarlas visualmente (ej. color de advertencia en "Eliminar cuenta").
- [Riesgo] Nueva dependencia de terceros (`share_plus` o similar) para compartir archivos. → Mitigación: se abstrae en `core/` como cualquier otra librería de infraestructura, consistente con la tabla de CLAUDE.md.

## Open Questions

- ¿Las foreign keys de `sources`/`articles`/`daily_summaries` hacia `auth.users` ya tienen `ON DELETE CASCADE`? Si es así, borrar el usuario de `auth.users` podría bastar sin un borrado explícito de filas previo — a confirmar revisando `supabase/migrations/` durante la implementación (`tasks.md`), sin que esto cambie el comportamiento observable descrito en las specs.
