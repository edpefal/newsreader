## Context

Es un cambio de copy puro, sin lógica nueva: reemplazar strings literales en widgets existentes y en documentación. Ver proposal.md - Why para la motivación y el criterio de qué se generaliza vs qué se mantiene.

## Goals / Non-Goals

**Goals:**
- Reemplazar el copy identificado en `sources_screen.dart`, `inbox_screen.dart`, `add_source_screen.dart` (solo el formulario principal), `pubspec.yaml`, `README.md` y `PRD.md`.
- Mantener sin cambios todo el copy específico de la card/diálogo de generación de email (email-to-RSS).

**Non-Goals:**
- No se cambia ningún ícono, ni el flujo de agregar fuente, ni ninguna lógica de negocio.
- No se toca `USER_STORIES.md` ni `SOLUTION_SPEC.md` (son locales, gitignored, fuera del alcance acordado con el usuario).
- No se renombra ninguna clase, archivo, ruta ni entidad de dominio — el código ya usa "Source"/"fuente" en sus identificadores; este cambio es solo de copy visible.

## Decisions

- **Reemplazo directo de strings, sin abstraer a constantes ni i18n**: el proyecto no usa un sistema de internacionalización (todos los strings están hardcodeados en español directamente en los widgets), así que no se introduce una capa nueva solo para este cambio.
- **"Fuente" como término de reemplazo, no "feed"**: la app ya usa "Fuentes" como nombre del tab/drawer y `NewsSource` como entidad de dominio; usar el mismo término evita introducir una tercera palabra para el mismo concepto.
- **La card y el diálogo de email-to-RSS quedan intactos**: mantienen "newsletter" porque ahí el término es preciso (esa feature es específicamente para newsletters sin feed propio), no una imprecisión a corregir.

## Risks / Trade-offs

- [Algún test de widget que use `find.text('...')` sobre el copy viejo empieza a fallar] → Mitigación: se actualizan como parte de las tasks de este change (ver tasks.md).
