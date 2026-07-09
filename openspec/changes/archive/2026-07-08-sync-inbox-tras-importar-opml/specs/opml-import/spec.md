## MODIFIED Requirements

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
