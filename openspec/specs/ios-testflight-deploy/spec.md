## Purpose

Da un camino repetible y manual para compilar, firmar y subir un build de iOS de producción al grupo interno de TestFlight, sin pasos manuales de firma ni de subida.

## Requirements

### Requirement: Disparo manual del build de distribución
El sistema SHALL requerir una acción manual explícita (iniciar el build desde la interfaz de Codemagic) para compilar y distribuir un build de iOS. El sistema SHALL NOT disparar automáticamente este build en cada push o merge a `main`.

#### Scenario: Push a main sin acción manual
- **WHEN** se pushea o mergea un commit a `main`
- **THEN** no se dispara ningún build de distribución de iOS

#### Scenario: Build iniciado manualmente
- **WHEN** el usuario inicia un build desde la interfaz de Codemagic
- **THEN** el sistema compila la app iOS a partir del commit seleccionado

### Requirement: Build de producción
El sistema SHALL compilar la app con la configuración `--dart-define=APP_ENV=prod`, de modo que el build apunte al backend de Supabase de producción.

#### Scenario: Build manual iniciado
- **WHEN** se inicia un build de distribución
- **THEN** el binario resultante usa `APP_ENV=prod`

### Requirement: Firma automática sin certificados en el repositorio
El sistema SHALL firmar el build de iOS automáticamente usando una integración con la App Store Connect API, sin requerir que certificados o provisioning profiles se almacenen en el repositorio de código.

#### Scenario: Build firmado
- **WHEN** se compila un build de distribución
- **THEN** el sistema lo firma usando la integración de App Store Connect configurada en Codemagic, sin leer ningún certificado del repositorio

### Requirement: Build number incremental
El sistema SHALL asignar al build un número de build (`CFBundleVersion`) mayor al último build number subido a TestFlight para la misma app, sin requerir que el número de build se actualice a mano en `pubspec.yaml` antes de cada subida.

#### Scenario: Segunda subida sin bump manual
- **WHEN** ya existe un build previo en TestFlight y se inicia un nuevo build sin haber cambiado el build number en `pubspec.yaml`
- **THEN** el sistema calcula un build number mayor al último subido y la subida no es rechazada por número de build duplicado

### Requirement: Distribución al grupo interno de TestFlight
El sistema SHALL subir el build firmado al grupo interno de TestFlight tras un build manual exitoso, sin publicarlo a ningún grupo externo ni enviarlo a revisión de App Store.

#### Scenario: Build y firma exitosos
- **WHEN** el build de distribución compila y se firma correctamente
- **THEN** el sistema lo sube al grupo interno de TestFlight

#### Scenario: Build o firma fallidos
- **WHEN** la compilación o la firma fallan
- **THEN** el sistema no sube ningún build a TestFlight y reporta el error
