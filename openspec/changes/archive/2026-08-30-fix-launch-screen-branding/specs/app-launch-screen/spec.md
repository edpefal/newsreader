## Purpose

Define la pantalla de arranque nativa (iOS y Android) que se muestra mientras Flutter inicializa, con el logo de Reevo y un fondo que respeta el tema del sistema.

## ADDED Requirements

### Requirement: Launch screen con logo de marca
La pantalla de arranque nativa (iOS launch screen / Android launch background) SHALL mostrar el logo de Reevo centrado en lugar del placeholder default de Flutter.

#### Scenario: Usuario abre la app en modo claro
- **WHEN** el sistema está en tema claro y el usuario abre la app
- **THEN** la pantalla de arranque muestra fondo blanco con el logo de Reevo centrado

#### Scenario: Usuario abre la app en modo oscuro
- **WHEN** el sistema está en tema oscuro y el usuario abre la app
- **THEN** la pantalla de arranque muestra fondo oscuro con el logo de Reevo centrado

### Requirement: Validación de assets de App Store Connect
Los assets de launch image de iOS SHALL ser imágenes reales y únicas (no el placeholder transparente de 1x1 px que genera el template de Flutter), de forma que la validación de "App Icon and Launch Image Assets" de App Store Connect no reporte el warning de imagen placeholder.

#### Scenario: Subida de build a App Store Connect
- **WHEN** se sube un build a App Store Connect y corre la validación de assets
- **THEN** no aparece el warning "Launch image is set to the default placeholder icon"
