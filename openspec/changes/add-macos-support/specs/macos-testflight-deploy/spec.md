## Purpose

Da un camino repetible y manual para compilar, firmar y subir un build de macOS de producción a TestFlight, sin pasos manuales de firma ni de subida, equivalente al de iOS.

## ADDED Requirements

### Requirement: Disparo manual del build de macOS
El sistema SHALL requerir una acción manual explícita para compilar y distribuir un build de macOS, y SHALL NOT dispararlo automáticamente en cada push o merge a `main`. El disparo SHALL poder hacerse desde la pestaña Actions de GitHub con el mismo mecanismo que el build de iOS, eligiendo cuál de los dos workflows lanzar.

#### Scenario: Push a main sin acción manual
- **WHEN** se pushea o mergea un commit a `main`
- **THEN** no se dispara ningún build de macOS

#### Scenario: Disparo manual del build de macOS
- **WHEN** un colaborador dispara el workflow de macOS desde GitHub o desde Codemagic
- **THEN** el sistema compila la app de macOS a partir de la rama indicada, con `main` por defecto

### Requirement: Build de producción de macOS
El sistema SHALL compilar el build de macOS con `--dart-define=APP_ENV=prod`, en modo release, como binario universal (Apple Silicon e Intel), con la misma versión de Flutter que fija el CI.

#### Scenario: Build manual iniciado
- **WHEN** se inicia el build de macOS
- **THEN** el binario resultante usa `APP_ENV=prod` y corre tanto en Apple Silicon como en Intel

### Requirement: Firma automática sin certificados en el repositorio
El sistema SHALL firmar el build de macOS con los certificados y perfiles de Mac App Store (aplicación e instalador) obtenidos por la integración con la App Store Connect API, sin que ningún certificado ni perfil se almacene en el repositorio.

#### Scenario: Build firmado
- **WHEN** se compila el build de macOS
- **THEN** el sistema firma la app y empaqueta el instalador con certificados obtenidos de la integración configurada en Codemagic, sin leer ninguno del repositorio

### Requirement: Build number incremental por plataforma
El sistema SHALL asignar al build de macOS un número de build mayor al último subido a TestFlight para macOS de la misma app, sin requerir cambiar el número a mano en `pubspec.yaml`, e independiente de la numeración de los builds de iOS.

#### Scenario: Segunda subida sin bump manual
- **WHEN** ya existe un build de macOS en TestFlight y se inicia uno nuevo sin cambiar el build number en `pubspec.yaml`
- **THEN** el sistema calcula un build number mayor al último de macOS y la subida no se rechaza por duplicado

### Requirement: Distribución a TestFlight
El sistema SHALL subir el instalador firmado a TestFlight tras un build exitoso, sin enviarlo a revisión de la Mac App Store ni publicarlo a grupos externos.

#### Scenario: Build exitoso
- **WHEN** el build de macOS termina sin errores
- **THEN** el instalador queda disponible en TestFlight para el grupo interno, sin enviarse a revisión

#### Scenario: Build fallido
- **WHEN** la compilación o la firma del build de macOS falla
- **THEN** el sistema no sube nada a TestFlight y el log del build conserva el error
