## ADDED Requirements

### Requirement: Sincronización del estado de descarte de daily_summaries
La tabla remota `daily_summaries` SHALL incluir una columna nullable `dismissed_at` con el instante en que el usuario abrió o descartó el resumen en el Inbox. Al subir cambios locales de `daily_summaries` en la sincronización completa, el sistema SHALL incluir ese valor en la fila enviada. Al bajar cambios remotos, el sistema SHALL reconstruir el `DailySummary` local con ese valor. Si el cambio remoto trae `dismissed_at` vacío pero el `DailySummary` local ya tiene un valor, el sistema SHALL conservar el valor local en vez de reemplazarlo. Un cliente que no envía `dismissed_at` al subir un resumen NO SHALL borrar un valor ya existente en el servidor.

#### Scenario: Subir un resumen descartado
- **WHEN** el sistema sube un `DailySummary` local con `dismissed_at`
- **THEN** la fila enviada incluye ese valor

#### Scenario: Bajar un resumen descartado en otro dispositivo
- **WHEN** el sistema baja un cambio de `daily_summaries` con `dismissed_at` definido
- **THEN** el `DailySummary` local queda con ese `dismissed_at`

#### Scenario: Un remoto sin dismissed_at no pisa el valor local
- **WHEN** el sistema baja un cambio remoto de un resumen con `dismissed_at` vacío y el resumen local ya tiene `dismissed_at`
- **THEN** el `DailySummary` local conserva su `dismissed_at`

#### Scenario: Un cliente anterior no borra el valor del servidor
- **WHEN** un cliente que no conoce `dismissed_at` sube un `DailySummary` hacia una fila que ya tiene `dismissed_at`
- **THEN** el valor de `dismissed_at` en el servidor permanece sin cambios

### Requirement: Push inmediato del descarte de un resumen
El sistema SHALL intentar subir `dismissed_at` (y `updated_at`) de un `DailySummary` a Supabase inmediatamente al descartarlo o abrirlo, sin esperar al próximo trigger de sincronización completa, actualizando solo esas columnas de la fila. Este push SHALL ser best-effort: no SHALL bloquear ni retrasar la actualización local ni la interfaz, y cualquier falla (sin red, error del servidor) SHALL ignorarse sin propagarse a la interfaz. El push SHALL intentarse únicamente si hay una sesión de usuario activa.

#### Scenario: Descartar con conexión disponible
- **WHEN** el usuario descarta o abre el resumen de hoy y el dispositivo tiene conexión
- **THEN** `dismissed_at` se sube a Supabase sin esperar a una sincronización completa

#### Scenario: Descartar sin conexión
- **WHEN** el usuario descarta o abre el resumen sin conexión
- **THEN** la actualización local se completa igual, sin errores visibles, y queda pendiente de subir en la próxima sincronización completa

#### Scenario: Descartar sin sesión activa
- **WHEN** el usuario descarta o abre el resumen sin sesión iniciada
- **THEN** el sistema no intenta ningún push, y la actualización local se completa igual

#### Scenario: El push inmediato no retrasa la interacción
- **WHEN** el usuario descarta la tarjeta
- **THEN** la interfaz refleja el descarte sin esperar la respuesta de red

#### Scenario: Falla el push inmediato pero la sincronización completa lo repara
- **WHEN** el push inmediato falla y luego el dispositivo dispara una sincronización completa
- **THEN** `dismissed_at` se sube en esa sincronización completa
