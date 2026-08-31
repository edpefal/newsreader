## Purpose

Define qué debe estar listo antes de la primera UI interactiva de la app y cuándo desaparece la pantalla de arranque nativa, de forma que abrir la app no se sienta bloqueada por I/O de red.

## Requirements

### Requirement: Splash nativa no se extiende por I/O de red diferible
La pantalla de arranque nativa SHALL desaparecer apenas la primera pantalla (Inbox) está lista para pintarse con datos locales, sin esperar a que termine la sincronización con la nube (`SyncUserData`) ni la inicialización de analytics/observabilidad.

#### Scenario: Arranque en frío con red lenta
- **WHEN** el usuario abre la app con conexión lenta o inestable
- **THEN** la splash nativa desaparece en cuanto Hive y la inyección de dependencias mínima terminan, y el Inbox se muestra con los artículos ya cacheados localmente (o su estado vacío, si no hay caché)

### Requirement: Sincronización en background tras el primer frame
La sincronización con la nube (`SyncUserData`), las migraciones locales one-time, y la inicialización de analytics/observabilidad (PostHog) SHALL correr después de que la primera pantalla ya se pintó, sin bloquear al usuario.

#### Scenario: Sync corriendo mientras el usuario ya ve el Inbox
- **WHEN** el Inbox ya se muestra con datos locales y la sincronización en background todavía no terminó
- **THEN** el usuario puede interactuar con la lista mostrada (scroll, abrir un artículo) mientras un indicador no invasivo señala que se está sincronizando

#### Scenario: Sync termina después del primer frame
- **WHEN** la sincronización en background termina
- **THEN** el Inbox (y Favoritos/Archivo/Fuentes/Resúmenes) se actualizan con los datos ya sincronizados sin que el usuario tenga que refrescar manualmente
