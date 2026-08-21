## Why

Hoy Reevo está 100% hardcodeado en español, sin ningún mecanismo de localización (`MaterialApp` no declara `supportedLocales` ni `localizationsDelegates`), y el español mismo mezcla voseo rioplatense ("Tocá acá") con tuteo ("toca la estrella") de forma inconsistente entre pantallas. Esto bloquea a cualquier usuario que use el dispositivo en otro idioma y proyecta una variante regional en vez de un español neutro apto para toda Latinoamérica. Es el primer paso de un plan en tres partes (infra + español neutro → contenido en inglés/francés → traducción de mensajes de error) para que la app soporte múltiples idiomas de forma sostenible.

## What Changes

- Se agrega infraestructura oficial de i18n de Flutter: `flutter_localizations` + archivos `.arb` por idioma + `flutter gen-l10n` generando una clase `AppLocalizations` tipada.
- `MaterialApp` pasa a declarar `supportedLocales: [en, es, fr]` (inglés primero) y los `localizationsDelegates` correspondientes. El idioma se detecta automáticamente del dispositivo; si no coincide con ninguno de los tres soportados, la app cae a inglés por defecto (comportamiento nativo de Flutter al ordenar `en` primero, sin lógica custom).
- Todo el texto de UI hardcodeado (~40+ literales `Text()`, tooltips, labels, hints, contenido de SnackBars) en las pantallas de Inbox, Reader, Favoritos, Archivo, Fuentes (+ agregar/detalle/importar OPML), Resúmenes, Auth, Account, y el Drawer/AppBar compartido, pasa a resolverse vía `AppLocalizations`.
- El contenido en español se reescribe completo en variante neutra/latinoamericana con tuteo, eliminando el voseo existente.
- El contenido en inglés (`app_en.arb`) queda completo como archivo template — es el idioma por defecto y debe estar terminado en este change. El contenido en francés (`app_fr.arb`) queda con placeholders (duplicando el inglés) — su traducción real es un change futuro.
- El formateo de fechas hardcodeado (incluyendo dos arrays de nombres de mes en español, duplicados entre sí) se migra a `DateFormat` de `intl`, que resuelve automáticamente el idioma, orden y formato según el locale activo.
- **Fuera de alcance explícito**: los mensajes de `AppException` y sus subclases (`core/errors/app_exception.dart`) NO se tocan en este change — siguen hardcodeados en español; su traducción es un change futuro que primero requiere que las excepciones dejen de cargar texto humano y pasen a ser identificables por tipo/código.
- No se agrega selector de idioma manual dentro de la app; el idioma se determina únicamente por el locale del dispositivo.

## Capabilities

### New Capabilities

- `app-localization`: la app detecta el idioma del dispositivo y muestra su interfaz (texto de UI y formato de fechas) en inglés, español neutro o francés según corresponda, con inglés como idioma por defecto cuando el dispositivo usa un idioma no soportado.

### Modified Capabilities

Ninguna. `reader-scroll-indicator`, `article-lifecycle` y el resto de las specs existentes no cambian su comportamiento funcional — solo cambia el idioma/formato en que se presenta texto que ya existía.

## Impact

- **Código afectado**: `lib/presentation/app/app.dart` (configuración de `MaterialApp`); nuevo `l10n.yaml` y directorio `lib/l10n/` con `app_en.arb` / `app_es.arb` / `app_fr.arb`; prácticamente todas las pantallas y widgets bajo `lib/features/**/presentation/` y `lib/presentation/`; `lib/core/widgets/date_separator.dart`; `pubspec.yaml` (agrega `flutter_localizations` como SDK dependency y habilita `generate: true`).
- **Nueva dependencia**: `flutter_localizations` (parte del SDK de Flutter, sin versión propia). No se agrega ningún paquete de terceros.
- **Sin cambios de datos**: no afecta modelos de Hive, sincronización, ni contratos de use cases — es un cambio de presentación y formato.
- **Documentación**: se actualiza `CLAUDE.md` con la convención de i18n adoptada (dónde viven las claves, cómo se agregan nuevas, la regla de español neutro con tuteo).
