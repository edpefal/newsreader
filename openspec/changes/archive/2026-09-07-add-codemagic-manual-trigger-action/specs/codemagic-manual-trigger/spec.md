## Purpose

Permitir disparar un build de Codemagic (App Store Connect / TestFlight) desde la pestaña Actions de GitHub, sin necesidad de acceder al dashboard de Codemagic ni de manejar el token de API a mano en una terminal.

## ADDED Requirements

### Requirement: Disparo exclusivamente manual
El workflow de GitHub Actions que lanza un build de Codemagic SHALL activarse únicamente por disparo manual (`workflow_dispatch`), nunca automáticamente por `push`, `pull_request` u otro evento del repositorio.

#### Scenario: Push a una rama no dispara el build de Codemagic
- **WHEN** se pushea un commit a cualquier rama del repositorio
- **THEN** el workflow de disparo de Codemagic no se ejecuta

#### Scenario: Disparo manual desde la pestaña Actions
- **WHEN** un colaborador con permisos de escritura en el repo dispara el workflow manualmente desde GitHub (UI o `gh workflow run`)
- **THEN** el workflow se ejecuta y llama a la API de Codemagic para iniciar el build

### Requirement: Rama configurable con default a main
El disparo manual SHALL aceptar como input la rama a buildear en Codemagic, con `main` como valor por defecto si no se especifica otra.

#### Scenario: Disparo sin especificar rama
- **WHEN** un colaborador dispara el workflow sin indicar una rama
- **THEN** Codemagic recibe la solicitud de build sobre la rama `main`

#### Scenario: Disparo especificando una rama distinta
- **WHEN** un colaborador dispara el workflow indicando una rama específica (ej. una rama de feature)
- **THEN** Codemagic recibe la solicitud de build sobre esa rama indicada

### Requirement: El token de API nunca se expone en logs
El workflow SHALL leer el token de autenticación de Codemagic desde un secret de GitHub Actions, y SHALL evitar que ese valor aparezca en la salida de los logs del job (ni impreso directamente, ni por eco de comandos que lo incluyan en texto plano).

#### Scenario: Log del job sin el token visible
- **WHEN** se revisa el log de una ejecución del workflow, exitosa o fallida
- **THEN** el valor del token de Codemagic no aparece en ningún paso del log

### Requirement: Falla visible ante error de la API de Codemagic
Si la API de Codemagic responde con un error (código HTTP de error o payload sin `buildId`), el job del workflow SHALL terminar en estado de fallo con un mensaje que indique el problema, en vez de terminar en verde.

#### Scenario: Codemagic responde con error de autenticación
- **WHEN** el secret `CODEMAGIC_API_TOKEN` es inválido o expiró
- **THEN** el job termina en fallo y el log indica que la autenticación con Codemagic fue rechazada

#### Scenario: Build disparado exitosamente
- **WHEN** la API de Codemagic acepta la solicitud y devuelve un `buildId`
- **THEN** el job termina exitosamente y el log muestra el `buildId` obtenido (dato no sensible)
