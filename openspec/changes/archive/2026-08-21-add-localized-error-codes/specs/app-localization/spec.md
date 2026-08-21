## ADDED Requirements

### Requirement: Mensajes de error localizados
Los mensajes de error visibles para el usuario (fallas de red, validación de datos, fallas al agregar/importar fuentes, generar resúmenes, o gestionar la cuenta) SHALL presentarse en el idioma activo de la app, con el mismo criterio de idiomas soportados e idioma por defecto que el resto de la interfaz.

#### Scenario: Error de red en el idioma activo
- **WHEN** la app está en un idioma soportado y ocurre un error de conectividad al agregar una fuente
- **THEN** el mensaje de error mostrado está en ese idioma, no hardcodeado en español

#### Scenario: Error con detalle dinámico del backend
- **WHEN** ocurre un error cuyo detalle específico proviene de una respuesta del backend (por ejemplo, un mensaje de error arbitrario de una Edge Function)
- **THEN** la app muestra un mensaje genérico localizado para ese tipo de error, en vez de mostrar el texto sin traducir devuelto por el backend
