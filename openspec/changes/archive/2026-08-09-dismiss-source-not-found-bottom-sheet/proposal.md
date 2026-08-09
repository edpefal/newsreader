## Why

Cuando falla la detección automática de feed en `AddSourceScreen`, se muestra un `SnackBar` rojo con la opción "Generar email". Ese `SnackBar` no se oculta al intentar agregar otra fuente ni al salir de la pantalla, y no tiene forma explícita de cerrarlo, por lo que queda pegado en la UI de forma confusa mientras el usuario sigue interactuando con la app.

## What Changes

- Al reintentar agregar una fuente (nuevo submit) desde `AddSourceScreen`, se oculta explícitamente el `SnackBar` de error de detección si estaba visible.
- Al salir de `AddSourceScreen` (dispose), se oculta explícitamente el `SnackBar` de error de detección si estaba visible.
- El `SnackBar` de error de detección deja de auto-ocultarse por duración fija y pasa a requerir cierre explícito (por las condiciones anteriores o por el nuevo botón de cerrar).
- Se agrega un ícono de cerrar (X) al `SnackBar` de error de detección para que el usuario pueda descartarlo manualmente.

## Capabilities

### New Capabilities

_(ninguna)_

### Modified Capabilities

- `source-management`: el requirement "AddSourceScreen ofrece generar un email cuando falla la detección automática" se amplía con el comportamiento de cierre del aviso de error (reintento, salida de pantalla, cierre manual).

## Impact

- `lib/features/sources/presentation/screens/add_source_screen.dart`: lógica del `SnackBar` de `AddSourceFeedDiscoveryFailed` (duración, cierre en submit/dispose, ícono de cerrar).
