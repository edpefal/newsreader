## Why

La exportación no abre el menú de compartir en el simulador de iPhone. El adaptador omite el origen que el plugin exige en iOS 26, una causa compatible con el síntoma pendiente del cambio de Ajustes.

## What Changes

- Enviar un origen válido al compartir los archivos.
- Verificar el contrato con el canal nativo mediante una prueba de regresión.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `data-export`: explicitar que la presentación nativa funciona en iPhone con iOS 26 y iPad.

## Impact

Adaptador `SharePlusFileSharer` y sus pruebas. Sin cambios de dependencias ni formatos exportados.
