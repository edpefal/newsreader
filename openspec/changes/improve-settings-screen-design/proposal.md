## Why

La pantalla de Ajustes mezcla estilos de texto sin normalizar (serif para headers, tamaños de 14/16/18px distintos según la fila) y las acciones de cuenta (exportar datos, cerrar sesión, eliminar cuenta) cuelgan sueltas debajo del bloque de email/plan sin ningún título de sección propio, lo que las hace ver como parte de la información de cuenta en vez de un grupo de acciones aparte. El diseño ya fue explorado y validado con un mockup (ver `design.md`).

## What Changes

- Se reordena la pantalla de Ajustes en 3 secciones con el mismo tratamiento de header: "Tu cuenta", "Datos y sesión" (nueva) y "Apariencia".
- La sección "Tu cuenta" pasa a mostrar solo email + estado del plan (Free/Premium) + botón de upgrade si aplica — ya no incluye las 3 acciones de cuenta.
- Se agrega la sección nueva "Datos y sesión" con las filas "Exportar mis datos", "Cerrar sesión" y "Eliminar cuenta" (en ese orden; la última en color de error), separadas entre sí por un hairline sutil, sin fondo de card.
- El botón "Obtener Premium" pasa de `OutlinedButton` sin estilo propio al acento de marca óxido (`ReevoAccent`).
- Se normaliza la tipografía de toda la pantalla: un único estilo para los 3 headers de sección, un único estilo para el texto principal de cada fila, un único estilo (más chico, `onSurfaceVariant`) para texto secundario. Se elimina el `TextStyle(color: error)` inline suelto del ítem de eliminar cuenta a favor del estilo normalizado + color de error.
- Se agrega la clave i18n `settingsDataAndSessionSectionTitle` ("Datos y sesión") en los 3 `.arb` (inglés, español neutro con tuteo, francés) y se corre `flutter gen-l10n`.
- **BREAKING** (a nivel de spec, no de API pública): reemplaza el requisito de `settings-account-status` que exigía que cuenta y acciones estuvieran unificadas en una sola sección.

Sin cambios de comportamiento: exportar datos, cerrar sesión y eliminar cuenta siguen disparando exactamente las mismas acciones (`ExportUserData`, `AuthClient.signOut` + `ClearLocalUserData`, `DeleteAccount`) que hoy.

## Capabilities

### New Capabilities
(ninguna — no se introduce una superficie de comportamiento nueva, solo se reestructura la presentación de comportamiento existente)

### Modified Capabilities
- `settings-account-status`: reemplaza el requisito "Sección de estado de cuenta visible primero en Ajustes" (que exigía que email, tier y acciones de cuenta estuvieran unificados en una sola sección) por uno que separa las acciones de cuenta en su propia sección "Datos y sesión", manteniendo el email/tier como la primera sección visible.

## Impact

- `lib/features/settings/presentation/screens/settings_screen.dart`: reestructuración de la UI en 3 secciones y normalización de estilos de texto.
- `lib/l10n/app_en.arb`, `app_es.arb`, `app_fr.arb`: nueva clave `settingsDataAndSessionSectionTitle`.
- `openspec/specs/settings-account-status/spec.md`: actualización del requisito de agrupación de secciones.
- Sin cambios en use cases, repositorios, ni en el comportamiento de exportar/cerrar sesión/eliminar cuenta.
