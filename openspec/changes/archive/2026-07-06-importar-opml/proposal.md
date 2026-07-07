## Why

Agregar fuentes de una en una es lento cuando el usuario viene de otro lector de feeds con múltiples suscripciones. OPML es el formato estándar de exportación/importación entre lectores RSS — soportarlo elimina la fricción de migración y hace la app compatible con el ecosistema.

## What Changes

- Nueva abstracción `OPMLParser` en `core/opml/` que parsea un archivo OPML y extrae las URLs de feeds (`xmlUrl`)
- Nuevo use case `ImportOpml` en `features/sources/` que valida y agrega N feeds reutilizando `AddSource`
- Nueva pantalla `ImportOpmlScreen` accesible desde `AddSourceScreen` con flujo: selección de archivo → validación con spinner → lista de preview con checkboxes → importación confirmada
- Los feeds ya suscritos aparecen deshabilitados en la lista de preview
- Los feeds que fallan validación aparecen marcados como error en la lista de preview
- Nuevas dependencias: `file_picker` (selector de archivos del OS) y `xml` (parseo XML)
- Nueva ruta `/sources/import-opml`

## Capabilities

### New Capabilities

- `opml-import`: Permite al usuario seleccionar un archivo `.opml` o `.xml`, previsualizar los feeds encontrados con su estado (nuevo, ya suscrito, error de validación), seleccionar cuáles importar y ejecutar la importación en batch

### Modified Capabilities

- `source-management`: Se agrega punto de entrada a la importación OPML desde `AddSourceScreen`

## Impact

- **Nuevos archivos**: `core/opml/opml_parser.dart`, `core/opml/xml_opml_parser.dart`, `features/sources/domain/usecases/import_opml.dart`, cubit + estado + pantalla de importación
- **Archivos modificados**: `pubspec.yaml`, `core/di/injection.dart`, `presentation/app/router.dart`, `features/sources/presentation/screens/add_source_screen.dart`
- **Dependencias nuevas**: `file_picker ^8.0.0`, `xml ^6.0.0`
- **Sin cambios en entidades ni repositorios** — `ImportOpml` reutiliza `AddSource` directamente
