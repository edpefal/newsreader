## Context

Ver proposal.md. El código nativo de share_plus 10.1.4 rechaza un origen vacío cuando existe un popoverPresentationController. El mantenedor confirma que iOS 26 también lo exige en iPhone: https://github.com/fluttercommunity/plus_plugins/issues/3645. Settings solo captura AppException, por lo que este PlatformException no muestra un snackbar.

## Goals / Non-Goals

**Goals:** satisfacer el contrato nativo desde el adaptador de infraestructura.

**Non-Goals:** cambiar formatos, actualizar el plugin o rediseñar el manejo general de errores.

## Decisions

Enviar un rectángulo de 1 × 1 puntos en el origen de la vista. Es no vacío y está dentro de la vista del controlador. Mantiene la corrección aislada en core, sin pasar geometría Flutter por los casos de uso. Anclar al botón sería más preciso visualmente en iPad, pero requeriría ampliar el contrato de dominio para esta corrección.

La prueba interceptará el canal real del plugin y comprobará el origen, los nombres y los contenidos de los archivos temporales. Una respuesta de plataforma simulada no demuestra la presentación de UIKit.

## Risks / Trade-offs

- El popover de iPad queda anclado a la esquina superior izquierda → comprobar manualmente su presentación.
- La causa del incidente original sigue siendo probable sin el log del simulador → dejar pendiente la verificación manual del usuario, sin cerrar la tarea archivada.
