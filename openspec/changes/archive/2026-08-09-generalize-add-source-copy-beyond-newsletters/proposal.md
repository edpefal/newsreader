## Why

La app siempre soportó cualquier feed RSS/Atom (no solo newsletters), pero el copy de la UI y la documentación de producto hablan casi exclusivamente de "newsletter" — desde el título de la pantalla de agregar fuente hasta el tagline del `pubspec.yaml`. Eso limita cómo se percibe la app y no refleja lo que realmente hace. Se generaliza el lenguaje al flujo genérico de "fuente/feed", conservando "newsletter" únicamente donde es preciso: la card y el flujo de generación de dirección de email (email-to-RSS), que es una feature específicamente pensada para newsletters sin feed propio.

## What Changes

- `sources_screen.dart`: FAB tooltip, empty state y CTA cambian de "newsletter" a "fuente".
- `inbox_screen.dart`: empty state y CTA cambian de "newsletter" a "fuente".
- `add_source_screen.dart`: título del `AppBar` y el hint del formulario generalizan a "fuente"/"sitio". La card y el diálogo de generación de email (email-to-RSS) **no cambian** — siguen hablando de "newsletter" porque ahí es el término correcto.
- `pubspec.yaml`: el `description` deja de decir exclusivamente "newsletters" y menciona feeds RSS en general.
- `README.md`: la descripción de apertura generaliza a "fuentes RSS/Atom"; la sección de email-to-RSS no cambia (sigue siendo específica de newsletters).
- `PRD.md`: las menciones de "newsletter" que describen el flujo general de agregar fuentes se generalizan; las que describen específicamente la feature de email-to-RSS se mantienen sin cambios.

## Capabilities

### New Capabilities

_(ninguna)_

### Modified Capabilities

- `source-management`: el requirement "AddSourceScreen acepta URLs de newsletter además de feeds exactos" cita textualmente el copy actual de la pantalla ("Pega el link de tu newsletter..."); se actualiza para reflejar el nuevo copy generalizado.

## Impact

- `lib/features/sources/presentation/screens/sources_screen.dart`
- `lib/features/inbox/presentation/screens/inbox_screen.dart`
- `lib/features/sources/presentation/screens/add_source_screen.dart` (solo el formulario principal, no la card de email)
- `pubspec.yaml`
- `README.md`, `PRD.md`
- Tests que hagan `find.text(...)` sobre el copy actual en las pantallas afectadas.
