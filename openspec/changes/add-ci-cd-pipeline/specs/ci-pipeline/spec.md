## Purpose

Detecta automáticamente regresiones de lint y de tests en cada cambio propuesto al repositorio, antes de que lleguen a `main`.

## ADDED Requirements

### Requirement: Verificación automática en cada push y pull request
El sistema SHALL ejecutar `flutter analyze` y `flutter test` automáticamente en cada push a `main` y en cada pull request dirigido a `main`, sin intervención manual.

#### Scenario: Push directo a main
- **WHEN** se pushea un commit a `main`
- **THEN** el sistema corre `flutter analyze` y `flutter test` sobre ese commit

#### Scenario: Pull request abierto o actualizado
- **WHEN** se abre o se actualiza un pull request contra `main`
- **THEN** el sistema corre `flutter analyze` y `flutter test` sobre el último commit del PR

### Requirement: El resultado de la verificación es visible antes de mergear
El sistema SHALL reportar el resultado (éxito o falla) de `flutter analyze` y `flutter test` de forma visible en el pull request, de modo que un fallo sea evidente antes de mergear.

#### Scenario: Analyze o tests fallan
- **WHEN** `flutter analyze` reporta errores/warnings o algún test de `flutter test` falla
- **THEN** el pull request muestra el chequeo como fallido

#### Scenario: Analyze y tests pasan
- **WHEN** `flutter analyze` no reporta errores/warnings y todos los tests de `flutter test` pasan
- **THEN** el pull request muestra el chequeo como exitoso

### Requirement: La verificación no depende de credenciales de firma ni de secretos de la app
El sistema SHALL ejecutar la verificación de CI sin requerir credenciales de firma de iOS/Android ni ningún secreto de infraestructura (Supabase, Sentry, PostHog, App Store Connect).

#### Scenario: Ejecución sin secretos configurados
- **WHEN** el workflow de CI corre sobre un push o pull request
- **THEN** completa `flutter analyze` y `flutter test` sin necesitar ninguna credencial externa
