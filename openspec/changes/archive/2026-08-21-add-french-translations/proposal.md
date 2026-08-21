## Why

La spec `app-localization` (archivada en el Change 1) ya exige que la app muestre su interfaz completa en francés cuando el dispositivo esté configurado en ese idioma. Hoy no lo cumple: `lib/l10n/app_fr.arb` es una copia literal en inglés, dejada así deliberadamente como placeholder mientras se resolvía la infraestructura. Un usuario con dispositivo en francés ve la app en inglés, no en francés — el requisito ya declarado en la spec no se cumple todavía en la implementación.

## What Changes

- Traducir las ~85 claves de `lib/l10n/app_fr.arb` a francés estándar/internacional, con el mismo registro informal ("tu") usado en el español neutro (tuteo) para mantener consistencia de voz de marca entre idiomas.
- Mantener intacta la sintaxis ICU de plural/placeholders ya usada en las claves con `{count, plural, ...}` y `{name}`/`{date}` — las formas `=1{...}`/`other{...}` que ya usa el proyecto son coincidencias de valor exacto, válidas en cualquier locale ICU sin ajuste.
- Agregar un test de regresión que falle si alguna clave de `app_fr.arb` queda idéntica a su equivalente en `app_en.arb` (con una lista explícita de excepciones legítimas, como `appTitle`), para detectar traducciones olvidadas.
- Completar los tests de `LocalizedDateFormatter` que hoy asertan explícitamente que el francés devuelve el mismo string que el inglés (comportamiento esperado del placeholder, no el final).

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

Ninguna. La spec `app-localization` (Requirement: "Idiomas soportados") ya exige este comportamiento — este change completa la implementación para que la app cumpla lo que la spec ya declara, sin cambiar el texto de ningún requisito.

## Impact

- **Código afectado**: `lib/l10n/app_fr.arb` (contenido, no estructura de claves); `test/widget/core/utils/localized_date_formatter_test.dart` (aserciones que hoy esperan francés == inglés).
- **Nuevo test**: uno que compara `app_fr.arb` contra `app_en.arb` clave por clave.
- **Sin cambios de código Dart fuera de tests**: no se tocan pantallas, widgets, ni la infraestructura de i18n (`l10n.yaml`, `app.dart`, `AppLocalizations`).
- **Fuera de alcance**: refactor de `AppException` (Change 3), cualquier cambio a inglés o español, selector de idioma manual.
