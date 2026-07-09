## MODIFIED Requirements

### Requirement: El sistema valida cada feed antes de mostrar el preview
El sistema SHALL iniciar la validación de cada feed extraído del OPML de forma concurrente y mostrar cada resultado en la pantalla de preview tan pronto como esté disponible, sin esperar a que todos los feeds completen.

#### Scenario: Validación completada con feeds mixtos
- **WHEN** todos los feeds han terminado de validar, con una combinación de feeds válidos, duplicados y con error
- **THEN** la lista muestra el estado completo de cada feed y el botón de importar está habilitado si hay al menos un feed seleccionado

#### Scenario: Todos los feeds fallan validación
- **WHEN** todos los feeds extraídos del OPML fallan la validación HTTP o de parseo
- **THEN** la lista muestra todos marcados como error y el botón de importar está deshabilitado

### Requirement: La pantalla de preview muestra el estado de cada feed
El sistema SHALL mostrar progresivamente la lista de feeds del OPML a medida que cada uno termina su validación, indicando cuántos feeds quedan por validar mientras el proceso continúa.

#### Scenario: Feed nuevo y válido
- **WHEN** el feed fue validado exitosamente y no existe en las fuentes del usuario
- **THEN** aparece con checkbox activado por defecto, mostrando nombre e ícono del feed

#### Scenario: Feed ya suscrito
- **WHEN** el feed ya existe en las fuentes del usuario
- **THEN** aparece deshabilitado con etiqueta "Ya suscrito", sin checkbox interactivo

#### Scenario: Feed con error de validación
- **WHEN** el feed falló la validación (timeout, URL rota, no es RSS válido)
- **THEN** aparece deshabilitado con etiqueta de error descriptiva, sin checkbox interactivo

#### Scenario: Feeds pendientes de validación
- **WHEN** hay feeds que aún están siendo validados
- **THEN** la pantalla muestra los resultados ya disponibles junto con un indicador de cuántos feeds faltan por procesar
