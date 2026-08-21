## Context

Ver `proposal.md` - Why. Puntos técnicos relevantes del estado actual:

- `MaterialApp` (`lib/presentation/app/app.dart`) no declara `locale`, `supportedLocales` ni `localizationsDelegates` hoy.
- El formateo de fechas está duplicado y hardcodeado en 5 lugares: `article_inbox_tile.dart` y `date_separator.dart` (cada uno con su propia lógica de "Hoy"/"Ayer" + fecha corta `día/mes`), `reader_screen.dart` (fecha larga `día/mes/año`), y `summary_detail_screen.dart` + `summary_list_item.dart` (cada uno con su propio array `_months` en español).
- 19 archivos de test construyen su propio `MaterialApp(...)` (sin helper compartido) para envolver el widget bajo prueba. Varios de ellos ya assertan contra texto literal en español (p. ej. `find.text('Sin favoritos aún')`, `find.text('Agregar mi primera fuente')`) — esos literales van a cambiar de forma (de `Text('...')` a `AppLocalizations.of(context)!.claveX`) y en algunos casos de contenido (limpieza de voseo).
- `core/utils/` ya es el lugar establecido en este proyecto para utilidades compartidas entre features (`IdGenerator`, `FeedContentChecker`), lo que da un lugar natural para una utilidad de formateo de fecha localizada.

## Goals / Non-Goals

**Goals:**
- Dejar `AppLocalizations` (generada vía `flutter gen-l10n`) como la única fuente de texto de UI en `presentation/`.
- Que el inglés (idioma por defecto) y el español (neutro) queden 100% completos; el francés queda con placeholders explícitos, no traducciones reales.
- Eliminar la duplicación de lógica de fecha (dos arrays de meses, dos implementaciones de "Hoy"/"Ayer") consolidándola en una sola utilidad reusable.
- Mantener la suite de tests determinística (no depender del locale de la máquina/CI) y verde.

**Non-Goals:**
- Traducir mensajes de `AppException` (Change 3, requiere primero que las excepciones dejen de cargar texto humano).
- Contenido real en francés (Change 2).
- Selector de idioma manual dentro de la app.
- Cualquier cambio de comportamiento funcional más allá de idioma/formato.

## Decisions

### 1. Ubicación de los `.arb` y salida generada: `lib/l10n/`
`l10n.yaml` en la raíz apunta `arb-dir: lib/l10n` y `output-dir: lib/l10n` (sin `synthetic-package`, que está deprecado). Los archivos `app_en.arb` (template), `app_es.arb`, `app_fr.arb` viven ahí, y `flutter gen-l10n` genera `app_localizations.dart` + variantes por idioma en el mismo directorio, importable directamente como `package:newsreader/l10n/app_localizations.dart`.

**Alternativa considerada**: usar el `synthetic-package` (comportamiento viejo, genera el código fuera de `lib/`, no importable directo). Se descarta por estar deprecado y por peor DX (no se puede "ir a definición" del lado del IDE tan fácil).

### 2. Claves ARB: planas, con prefijo de pantalla/feature, y un grupo `common*` para texto compartido
El formato `.arb` es un namespace plano (no soporta carpetas por feature). Se adopta una convención de nombres tipo `inboxEmptyStateTitle`, `sourcesAddFirstButton`, `readerOpenInBrowserTooltip`, y claves genéricas `commonCancel`, `commonDelete`, `commonEdit` para texto verdaderamente compartido entre features (botones de diálogos, etc.) para no traducir la misma palabra dos veces con dos claves distintas.

**Alternativa considerada**: una clave por string sin prefijo (`cancel`, `delete`, `title`). Se descarta por colisión de nombres y porque pierde la trazabilidad de "esto es de qué pantalla" al leer el `.arb`.

### 3. Fechas: `DateFormat` de `intl`, consolidado en una sola utilidad
Se agrega `core/utils/localized_date_formatter.dart` con funciones puras que reciben `Locale`/`BuildContext` + `DateTime` y devuelven el string ya formateado:
- Fecha corta (para `ArticleInboxTile` y `DateSeparator`): usa las claves `commonToday`/`commonYesterday` de `AppLocalizations` para los casos relativos, y `DateFormat.Md(localeName)` (o equivalente) para el resto.
- Fecha larga (para `ReaderScreen` y las pantallas de Resúmenes): `DateFormat.yMMMMd(localeName)`, que resuelve automáticamente nombres de mes y orden según el idioma activo — reemplaza los dos arrays `_months` hardcodeados.

Todos los call sites (`article_inbox_tile.dart`, `date_separator.dart`, `reader_screen.dart`, `summary_detail_screen.dart`, `summary_list_item.dart`) pasan a llamar esta utilidad en vez de tener su propia lógica.

**Alternativa considerada**: dejar cada widget con su propia llamada a `DateFormat` sin consolidar. Se descarta porque no resuelve la duplicación ya identificada (dos arrays de meses idénticos) y perpetúa el problema para el próximo formato de fecha que se necesite.

### 4. Helper de test compartido, con locale fijo por defecto
Se agrega `test/support/pump_localized_app.dart` con una función (p. ej. `wrapWithApp(Widget child, {Locale locale = const Locale('es')})`) que arma el `MaterialApp`/`MaterialApp.router` con `localizationsDelegates: AppLocalizations.localizationsDelegates` y `supportedLocales: AppLocalizations.supportedLocales`, fijando el locale a español por defecto (así las aserciones de texto existentes, ya migradas a español neutro, siguen siendo válidas sin depender del locale de la máquina que corre los tests). Los 19 archivos de test que hoy arman su propio `MaterialApp` pasan a usar este helper. Los tests nuevos específicos de la capability `app-localization` pasan un `locale` explícito distinto para verificar inglés/francés y el fallback.

**Alternativa considerada**: dejar que cada test siga armando su propio `MaterialApp` y agregarle los parámetros de localización a mano. Se descarta por la duplicación (19 lugares idénticos) y el riesgo de que alguno quede mal configurado y falle de forma no obvia (`AppLocalizations.of(context)` devuelve `null`).

### 5. Test de regresión anti-voseo
Se agrega un test unitario que instancia `AppLocalizationsEs` (o itera sus getters conocidos) y verifica que ningún valor matchee un patrón de voseo (`tocá`, `agregá`, `mirá`, `dale`, `che`, `vos` como palabra suelta, etc.). Esto convierte el requisito "español neutro" del proposal en algo que no puede regresar silenciosamente en el futuro.

**Alternativa considerada**: revisión manual únicamente, sin test. Se descarta porque el problema original (mezcla de voseo/tuteo) apareció precisamente por falta de un chequeo automatizado, y agregar uno es barato.

## Risks / Trade-offs

- **[Riesgo] El barrido real de literales de texto es más grande que los ~40 `Text('...')` detectados por grep simple** (tooltips, hints, labels, contenido de SnackBars, y `Text` con argumento sin comillas simples quedan fuera de ese conteo). → Mitigación: la tarea de verificación final incluye una revisión manual pantalla por pantalla, no solo el grep inicial.
- **[Riesgo] Francés con placeholders significa que un usuario con dispositivo en francés ve contenido en francés que en realidad es una copia del inglés**, no traducción real, hasta el Change 2. → Mitigación: aceptado explícitamente en el proposal; no es peor que el estado actual (hoy el francés ni siquiera está soportado).
- **[Riesgo] Los mensajes de `AppException` siguen en español hardcodeado tras este change**, generando una experiencia inconsistente para usuarios en inglés/francés (la UI está en su idioma, pero un error de red aparece en español). → Mitigación: ninguna en este change — es deuda conocida y documentada, resuelta en el Change 3 ya planeado.
- **[Riesgo] Migrar 19 archivos de test + docenas de aserciones de texto es mecánico y fácil de dejar a medias**, dejando tests rotos o, peor, tests que pasan por accidente comparando contra el string equivocado. → Mitigación: el helper de test compartido reduce el riesgo de mala configuración; la tarea de verificación final corre la suite completa y exige 0 fallos antes de cerrar el change.

## Migration Plan

- Orden de implementación sugerido (ver `tasks.md`): (1) infra i18n (`l10n.yaml`, `pubspec.yaml`, `MaterialApp`) con `app_en.arb`/`app_es.arb`/`app_fr.arb` mínimos para validar que compila, (2) helper de test compartido y migración de los 19 archivos de test a usarlo, (3) migración pantalla por pantalla del texto de UI (con las claves ARB reales en inglés y español neutro, y placeholders en francés), actualizando las aserciones de test en el mismo paso que cada pantalla, (4) utilidad de fecha localizada + migración de los 5 call sites, (5) test de regresión anti-voseo, (6) actualización de `CLAUDE.md`, (7) verificación final (`flutter analyze`, `flutter test`, prueba manual en simulador cambiando el idioma del dispositivo entre los 3 idiomas soportados y uno no soportado).
- Rollback: revertir el commit/PR; no hay migración de datos ni de esquema que deshacer.
