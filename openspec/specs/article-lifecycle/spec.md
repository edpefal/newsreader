# Spec: Article Lifecycle

## Purpose

Define how articles move between states (inbox → leídos) and when they are retained or removed. The lifecycle is intentionally simple: articles move only when the user explicitly opens them; no automatic archiving or deletion occurs.

## Requirements

### Requirement: Los artículos no leídos permanecen en el inbox indefinidamente
Los artículos no leídos SHALL permanecer en el inbox hasta que el usuario los abra. El sistema no SHALL mover ni eliminar artículos automáticamente por antigüedad.

#### Scenario: Artículo no leído después de 30 días
- **WHEN** un artículo no leído tiene más de 30 días de antigüedad
- **THEN** el artículo permanece en el inbox sin cambios

#### Scenario: Artículo no leído después de 60 días
- **WHEN** un artículo no leído tiene más de 60 días de antigüedad
- **THEN** el artículo permanece en el inbox sin cambios

---

### Requirement: Un artículo se mueve a "Leídos" al ser abierto
El sistema SHALL marcar un artículo como leído (`isRead=true`, `readAt=now`) cuando el usuario lo abre en ReaderScreen. El artículo SHALL desaparecer del inbox y aparecer en "Leídos" inmediatamente.

#### Scenario: Usuario abre un artículo desde el inbox
- **WHEN** el usuario toca un artículo en el inbox
- **THEN** el artículo desaparece del inbox y aparece en "Leídos"

#### Scenario: Artículo ya leído no se vuelve a marcar
- **WHEN** el usuario abre un artículo que ya tiene `isRead=true`
- **THEN** el sistema no modifica el artículo

---

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
