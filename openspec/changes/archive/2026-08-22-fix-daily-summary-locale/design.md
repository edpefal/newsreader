## Context

La app no tiene un selector de idioma propio ni un `LocaleCubit`: `MaterialApp.router` (en `presentation/app/app.dart`) no fija un `locale:` explícito, así que Flutter resuelve el idioma activo automáticamente a partir del locale del dispositivo, contra `supportedLocales: [en, es, fr]` (ver `app_localizations.dart`). Ese es el único idioma "activo" que existe en la app hoy — no hay un override guardado en Hive ni en el backend.

`GenerateDailySummary` (domain usecase) y `GeminiSummaryGenerator` (implementación de `SummaryGenerator`) no tienen acceso a `BuildContext`, así que no pueden leer el locale resuelto por Flutter directamente. El único punto de la cadena de llamada con `BuildContext` disponible es `SummariesScreen`, donde vive el botón que dispara `SummariesCubit.generateTodaySummary()`.

Ver `proposal.md` para la motivación completa.

## Goals / Non-Goals

**Goals:**
- El texto del resumen diario generado por la API de IA sale en el mismo idioma que la app le muestra al usuario en ese momento (en/es/fr).
- Si el idioma no se pudo determinar o no es uno de los 3 soportados, cae a inglés como default seguro, sin adivinar ni fallar la generación.
- El resto del comportamiento de `summarize-articles` (auth, entitlement, selección de contenido por artículo, formato de salida) queda exactamente igual.

**Non-Goals:**
- No se agrega un selector de idioma manual independiente del idioma de la app (el resumen sigue el mismo idioma que el resto de la UI, no un idioma elegido aparte).
- No se re-traducen resúmenes ya generados — solo las generaciones nuevas usan el locale activo al momento de generarse.
- No cambia la lógica de selección de contenido por artículo (`contentHtml` completo vs `excerpt`).

## Decisions

### 1. El locale viaja como parámetro explícito desde la UI, no se re-deriva del dispositivo en el backend ni en el usecase

`SummariesScreen` lee `Localizations.localeOf(context).languageCode` (el mismo valor que ya determina qué está viendo el usuario en pantalla) y lo pasa a `SummariesCubit.generateTodaySummary(languageCode)`, que lo threadea hacia abajo: `GenerateDailySummary.execute(languageCode)` → `SummaryGenerator.summarize(articles, languageCode)` → `GeminiSummaryGenerator` lo incluye en el body del POST a `summarize-articles` (`{ articles, language }`).

**Alternativa considerada**: leer `PlatformDispatcher.instance.locale` directo dentro de `GeminiSummaryGenerator`, sin threadear nada. Se descarta porque duplicaría la lógica de resolución de `supportedLocales` que ya hace Flutter internamente — un locale de dispositivo no soportado (ej. `de`) podría resolverse distinto por cada mecanismo, y terminaría generando el resumen en un idioma distinto al que la UI le muestra al usuario en ese mismo momento.

### 2. Se manda el código de idioma de 2 letras (`en`/`es`/`fr`), validado independientemente en el backend

El backend no confía ciegamente en lo que mande el cliente: valida `language` contra el mismo set de 3 códigos soportados y cae a `en` si no matchea o falta, sin romper la generación.

### 3. `buildPrompt` en `summarize-articles/index.ts` pasa a tomar el idioma como parámetro

El prompt entero (instrucciones de voz editorial, reglas de qué sí/qué no, y el ejemplo "MAL/BIEN" que ancla el tono) se escribe en las 3 versiones (en/es/fr), seleccionando la correspondiente según `language`. La estructura de reglas (formato de salida exacto, sin markdown, línea en blanco entre fuentes, etc.) es la misma en los 3 idiomas — solo cambia el idioma del texto de instrucción y del ejemplo.

### 4. No se persiste el locale usado en el `DailySummary`

`DailySummary.content` queda como texto plano igual que hoy, sin un campo que indique en qué idioma se generó. Si el usuario cambia el idioma de la app y regenera el resumen de hoy, el nuevo texto sobrescribe al anterior en el nuevo idioma (mismo mecanismo de sobrescritura que ya existe).

## Risks / Trade-offs

- **[Riesgo]** Mantener 3 versiones del prompt completo (incluido el ejemplo largo "MAL/BIEN") triplica el texto a actualizar si la voz editorial cambia en el futuro → **Mitigación**: es el mismo trade-off que ya existe hoy para toda la UI (`app_en.arb`/`app_es.arb`/`app_fr.arb`), coherente con el patrón ya establecido en el proyecto para i18n.
- **[Riesgo]** Un cliente viejo (versión de la app sin este change) no manda `language` en el request → antes de este ajuste el default caía a español (igual al comportamiento previo); ahora cae a inglés, así que un cliente viejo ve un cambio de idioma sin haber actualizado → **Mitigación**: aceptado a propósito — el rollout de este change se acompaña de la actualización del cliente que sí manda `language`, y el fallback a inglés es el default elegido para cualquier caso no determinado (no solo clientes viejos).
- **[Trade-off]** No hay forma de pedir el resumen en un idioma distinto al de la UI — se asume que el usuario quiere el resumen en el mismo idioma en el que lee el resto de la app. Non-goal explícito, no una limitación técnica.

## Migration Plan

Sin migración de datos — no hay cambios de esquema. Se despliega la nueva versión del edge function; durante el rollout, clientes con la versión vieja de la app simplemente no mandan `language` y el backend cae a inglés. Rollback: revertir el edge function a la versión anterior, sin ningún paso adicional.
