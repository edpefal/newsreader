## ADDED Requirements

### Requirement: Push inmediato del estado "leído" de un artículo
El sistema SHALL intentar subir el estado (`isRead`, `readAt`, `updatedAt`) de un artículo a Supabase inmediatamente al marcarlo como leído, sin esperar al próximo trigger de sincronización completa (login, resume, o pull-to-refresh). Este push SHALL ser best-effort: no SHALL bloquear ni retrasar la actualización local del artículo ni la actualización de la interfaz, y cualquier falla (sin red, error del servidor) SHALL ignorarse silenciosamente sin propagarse a la interfaz. El push SHALL intentarse únicamente si hay una sesión de usuario activa.

#### Scenario: Marcar como leído con conexión disponible
- **WHEN** el usuario marca un artículo como leído y el dispositivo tiene conexión
- **THEN** el estado `isRead=true` se sube a Supabase sin que el usuario tenga que abrir la app de nuevo, hacer pull-to-refresh, o esperar a que la app pase a background y vuelva

#### Scenario: Marcar como leído sin conexión
- **WHEN** el usuario marca un artículo como leído sin conexión a internet
- **THEN** la actualización local (Hive) se completa igual, sin errores visibles para el usuario, y el estado queda pendiente de subir en la próxima sincronización completa

#### Scenario: Marcar como leído sin sesión activa
- **WHEN** el usuario marca un artículo como leído sin haber iniciado sesión
- **THEN** el sistema no intenta ningún push a la nube, y la actualización local se completa igual

#### Scenario: El push inmediato no retrasa la interacción del usuario
- **WHEN** el usuario marca un artículo como leído
- **THEN** la interfaz refleja el artículo como leído sin esperar la respuesta de red del push a la nube

#### Scenario: Falla el push inmediato pero la sincronización completa lo repara
- **WHEN** el push inmediato de un artículo falla (por ejemplo, por falta de conexión) y luego el dispositivo dispara una sincronización completa (login, resume, o pull-to-refresh)
- **THEN** el estado `isRead=true` de ese artículo se sube a la nube en esa sincronización completa, igual que cualquier otro cambio local pendiente
