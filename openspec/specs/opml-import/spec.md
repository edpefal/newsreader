# Capability: OPML Import

## Purpose

Permite al usuario importar múltiples fuentes RSS/Atom de una sola vez mediante un archivo OPML. El flujo cubre la selección del archivo, el parseo, la validación individual de cada feed, la previsualización con selección granular y la importación final con resumen de resultado.

---

## Requirements

### Requirement: El usuario puede seleccionar un archivo OPML
El sistema SHALL permitir al usuario seleccionar un archivo `.opml` o `.xml` desde el sistema de archivos del dispositivo al pulsar el botón "Importar desde OPML" en `AddSourceScreen`.

#### Scenario: Selección exitosa de archivo OPML
- **WHEN** el usuario pulsa "Importar desde OPML" y selecciona un archivo válido
- **THEN** el sistema navega a `ImportOpmlScreen` y muestra un indicador de carga mientras valida los feeds

#### Scenario: Usuario cancela el selector de archivos
- **WHEN** el usuario pulsa "Importar desde OPML" pero cancela sin seleccionar archivo
- **THEN** el sistema no navega y permanece en `AddSourceScreen`

---

### Requirement: El sistema parsea el archivo OPML y extrae URLs de feeds
El sistema SHALL extraer todos los elementos `<outline>` que contengan el atributo `xmlUrl` del archivo OPML, incluyendo los anidados dentro de carpetas (outlines sin `xmlUrl`).

#### Scenario: OPML con feeds directos y en carpetas
- **WHEN** el archivo contiene outlines en el nivel raíz y outlines anidados dentro de grupos
- **THEN** el sistema extrae las `xmlUrl` de todos ellos sin distinción de nivel de anidamiento

#### Scenario: OPML sin feeds válidos
- **WHEN** el archivo no contiene ningún outline con atributo `xmlUrl`
- **THEN** el sistema muestra un mensaje de error: "No se encontraron feeds en este archivo"

#### Scenario: Archivo con formato XML inválido
- **WHEN** el contenido del archivo no es XML válido o no tiene estructura OPML reconocible
- **THEN** el sistema muestra un mensaje de error: "El archivo no es un OPML válido"

---

### Requirement: El sistema valida cada feed antes de mostrar el preview
El sistema SHALL iniciar la validación de cada feed extraído del OPML de forma concurrente y mostrar cada resultado en la pantalla de preview tan pronto como esté disponible, sin esperar a que todos los feeds completen.

#### Scenario: Validación completada con feeds mixtos
- **WHEN** todos los feeds han terminado de validar, con una combinación de feeds válidos, duplicados y con error
- **THEN** la lista muestra el estado completo de cada feed y el botón de importar está habilitado si hay al menos un feed seleccionado

#### Scenario: Todos los feeds fallan validación
- **WHEN** todos los feeds extraídos del OPML fallan la validación HTTP o de parseo
- **THEN** la lista muestra todos marcados como error y el botón de importar está deshabilitado

---

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

---

### Requirement: El usuario puede seleccionar qué feeds importar
El sistema SHALL permitir al usuario activar o desactivar individualmente los feeds con estado "nuevo y válido" antes de confirmar la importación.

#### Scenario: Deseleccionar feeds individuales
- **WHEN** el usuario desmarca el checkbox de un feed válido
- **THEN** ese feed queda excluido de la importación al confirmar

#### Scenario: Importar sin ningún feed seleccionado
- **WHEN** el usuario desmarca todos los feeds válidos
- **THEN** el botón "Importar" queda deshabilitado

---

### Requirement: El sistema importa los feeds seleccionados y muestra el resultado
El sistema SHALL agregar cada feed seleccionado usando la misma lógica de `AddSource`, mostrar un resumen del resultado al finalizar, y disparar una sincronización automática del inbox para que los artículos de las fuentes importadas aparezcan sin intervención del usuario.

#### Scenario: Importación exitosa parcial o total
- **WHEN** el usuario confirma la importación con al menos un feed seleccionado
- **THEN** el sistema importa cada feed seleccionado, navega de regreso, muestra un snackbar con el resumen (ej. "3 fuentes importadas"), y dispara una sincronización del inbox en background

#### Scenario: Artículos aparecen en inbox sin pull-to-refresh
- **WHEN** el usuario regresa al inbox tras completar una importación OPML
- **THEN** los artículos de las fuentes recién importadas aparecen automáticamente sin necesidad de hacer pull-to-refresh

#### Scenario: Fallo durante la importación de un feed individual
- **WHEN** un feed falla durante la importación (error de red en el momento de guardar)
- **THEN** el sistema continúa con los demás feeds y el resumen refleja cuántos se importaron y cuántos fallaron
