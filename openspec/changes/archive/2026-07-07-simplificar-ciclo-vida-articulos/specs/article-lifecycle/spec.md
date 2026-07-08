## MODIFIED Requirements

### Requirement: Los artículos no leídos permanecen en el inbox indefinidamente
Los artículos no leídos SHALL permanecer en el inbox hasta que el usuario los abra. El sistema no SHALL mover ni eliminar artículos automáticamente por antigüedad.

#### Scenario: Artículo no leído después de 30 días
- **WHEN** un artículo no leído tiene más de 30 días de antigüedad
- **THEN** el artículo permanece en el inbox sin cambios

#### Scenario: Artículo no leído después de 60 días
- **WHEN** un artículo no leído tiene más de 60 días de antigüedad
- **THEN** el artículo permanece en el inbox sin cambios

### Requirement: Un artículo se mueve a "Leídos" al ser abierto
El sistema SHALL marcar un artículo como leído (`isRead=true`, `readAt=now`) cuando el usuario lo abre en ReaderScreen. El artículo SHALL desaparecer del inbox y aparecer en "Leídos" inmediatamente.

#### Scenario: Usuario abre un artículo desde el inbox
- **WHEN** el usuario toca un artículo en el inbox
- **THEN** el artículo desaparece del inbox y aparece en "Leídos"

#### Scenario: Artículo ya leído no se vuelve a marcar
- **WHEN** el usuario abre un artículo que ya tiene `isRead=true`
- **THEN** el sistema no modifica el artículo

### Requirement: "Leídos" muestra los artículos que el usuario ha abierto
El sistema SHALL mostrar en "Leídos" todos los artículos con `isRead=true`, ordenados por `readAt` descendente (más reciente primero). Los artículos leídos SHALL permanecer en "Leídos" indefinidamente.

#### Scenario: Artículo leído aparece en "Leídos"
- **WHEN** el usuario abre un artículo
- **THEN** ese artículo aparece en "Leídos" al navegar a esa pantalla

#### Scenario: Orden por fecha de lectura
- **WHEN** el usuario navega a "Leídos"
- **THEN** los artículos aparecen ordenados por cuándo fueron leídos, el más reciente primero

#### Scenario: Artículos leídos no expiran
- **WHEN** un artículo lleva más de 30 días en "Leídos"
- **THEN** el artículo permanece en "Leídos" sin cambios

## REMOVED Requirements

### Requirement: Auto-archivado de artículos no leídos
**Reason:** El usuario quiere un modelo simple donde los artículos solo se mueven cuando él los lee. El auto-archivado causaba confusión: artículos no leídos aparecían en "Leídos" y artículos sí leídos no aparecían ahí.
**Migration:** Los artículos con `isArchived=true` existentes en Hive serán eliminados en la migración de startup (`MigrateArchivedArticles`).

### Requirement: Auto-eliminación de artículos leídos después de 30 días
**Reason:** Simplificación del ciclo de vida. Los artículos leídos permanecen indefinidamente en "Leídos".
**Migration:** No se requiere acción. Los artículos leídos existentes en Hive simplemente dejan de ser candidatos para eliminación.
