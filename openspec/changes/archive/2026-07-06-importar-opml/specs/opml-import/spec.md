## ADDED Requirements

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
El sistema SHALL intentar conectarse a cada feed extraído del OPML y parsear su contenido antes de mostrar la pantalla de preview, usando la misma lógica de validación que `AddSource`.

#### Scenario: Validación completada con feeds mixtos
- **WHEN** el proceso de validación termina con una combinación de feeds válidos, duplicados y con error
- **THEN** el sistema muestra la lista completa con el estado de cada feed y habilita el botón de importar si hay al menos un feed seleccionable

#### Scenario: Todos los feeds fallan validación
- **WHEN** todos los feeds extraídos del OPML fallan la validación HTTP o de parseo
- **THEN** el sistema muestra la lista con todos marcados como error y el botón de importar deshabilitado

---

### Requirement: La pantalla de preview muestra el estado de cada feed
El sistema SHALL mostrar una lista con cada feed encontrado en el OPML, indicando visualmente su estado: seleccionable (nuevo), deshabilitado (ya suscrito), o error (falló validación).

#### Scenario: Feed nuevo y válido
- **WHEN** el feed fue validado exitosamente y no existe en las fuentes del usuario
- **THEN** aparece con checkbox activado por defecto, mostrando nombre e ícono del feed

#### Scenario: Feed ya suscrito
- **WHEN** el feed ya existe en las fuentes del usuario
- **THEN** aparece deshabilitado con etiqueta "Ya suscrito", sin checkbox interactivo

#### Scenario: Feed con error de validación
- **WHEN** el feed falló la validación (timeout, URL rota, no es RSS válido)
- **THEN** aparece deshabilitado con etiqueta de error descriptiva, sin checkbox interactivo

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
El sistema SHALL agregar cada feed seleccionado usando la misma lógica de `AddSource` y mostrar un resumen del resultado al finalizar.

#### Scenario: Importación exitosa parcial o total
- **WHEN** el usuario confirma la importación con al menos un feed seleccionado
- **THEN** el sistema importa cada feed seleccionado, navega de regreso, y muestra un snackbar con el resumen (ej. "3 fuentes importadas")

#### Scenario: Fallo durante la importación de un feed individual
- **WHEN** un feed falla durante la importación (error de red en el momento de guardar)
- **THEN** el sistema continúa con los demás feeds y el resumen refleja cuántos se importaron y cuántos fallaron
