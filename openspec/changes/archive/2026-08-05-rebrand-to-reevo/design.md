## Context

Ver proposal.md - Why. El bundle id ya es `com.artlab.reevo` en ambas plataformas; solo falta que el texto visible y la documentación lo reflejen. Es un cambio de bajo riesgo técnico (reemplazo de strings literales), pero toca varias capas (UI, tests, docs, config nativa de Android/iOS) que conviene enumerar explícitamente para no dejar ninguna a medias.

## Goals / Non-Goals

**Goals:**
- Que ningún texto visible al usuario ni ninguna configuración de plataforma diga "Newsletter Hub" o el placeholder "newsreader"/"Newreader" al terminar el change.
- Mantener consistencia: un único nombre de marca ("Reevo") en todos los lugares donde hoy aparece cualquiera de los dos anteriores.

**Non-Goals:**
- No se cambia el nombre del paquete Dart (`name: newsreader`) ni ningún import `package:newsreader/...` — ver Non-Goal explícito en proposal.md.
- No se cambia el ícono de la app, el splash screen, ni ningún asset gráfico — este change es solo de texto/metadata.
- No se cambia el nombre del directorio del repositorio ni ningún identificador interno (ids de Hive, nombres de tabla en Supabase, etc.).

## Decisions

### Decisión 1: Reemplazo directo de literales, sin introducir una constante de marca

Los 4 lugares de UI (`login_screen.dart`, `inbox_screen.dart`, `router.dart`, `app.dart`) hoy tienen el string `'Newsletter Hub'` hardcodeado de forma independiente, sin una constante compartida. Se reemplaza cada literal por `'Reevo'` en el mismo lugar, sin extraer una constante nueva en `core/constants/app_constants.dart`.

**Alternativa considerada**: agregar `AppConstants.appName = 'Reevo'` y referenciarla desde los 4 lugares. Se descartó por ser una abstracción que el proyecto no pidió y que excede el alcance de un rename de texto — si en el futuro se necesita esa constante por otra razón, es un cambio de una línea agregarla entonces, no ahora.

### Decisión 2: El test de widget se actualiza al texto nuevo, no se generaliza

`inbox_screen_test.dart:80` hace `expect(find.text('Bienvenido a Newsletter Hub'), findsOneWidget)`. Se actualiza el string esperado a `'Bienvenido a Reevo'`, sin cambiar la estructura del test ni introducir un matcher menos específico (como `findsWidgets` con un `contains`). El test sigue verificando exactamente lo mismo que antes: que el onboarding vacío muestra el mensaje de bienvenida correcto.

### Decisión 3: Alcance de plataforma limitado a los campos de nombre de display, sin tocar bundle id ni firma

En Android, se cambia únicamente `android:label` en `AndroidManifest.xml`. En iOS, se cambian `CFBundleDisplayName` y `CFBundleName` en `Info.plist`. No se toca `applicationId`/`PRODUCT_BUNDLE_IDENTIFIER` (ya están correctos en `com.artlab.reevo`) ni ningún archivo de firma/provisioning.

## Risks / Trade-offs

- **[Riesgo] Cambiar `CFBundleName`/`android:label` requiere reinstalar la app en dispositivos de prueba para ver el nombre nuevo en el launcher** → Mitigación: no afecta usuarios en producción hasta el próximo release; es solo friction de desarrollo local, aceptable para este change.
- **[Riesgo] Cambiar el string de bienvenida podría romper snapshots visuales si existieran** → Mitigación: revisado — el proyecto no usa golden tests/snapshots para esta pantalla (solo el `expect(find.text(...))` en `inbox_screen_test.dart`), así que no hay ese riesgo.
- **[Trade-off] No extraer una constante de marca compartida (Decisión 1) significa que un futuro rename tendría que volver a tocar los mismos 4 lugares** → Aceptado: es la opción más simple para el alcance actual; no se justifica la abstracción por un evento (rename de marca) que no es frecuente.
