## Context

`InboxCubit` tiene hoy dos estados: `InboxLoading` (pantalla completa, sin contenido) e `InboxLoaded` (con artículos). El resume desde background (`_AppState.didChangeAppLifecycleState` en `app.dart`) llama a `SyncUserData.execute()` y luego `inboxCubit.loadArticles()`, que emite `InboxLoading` — reemplazando temporalmente el contenido ya visible por un spinner a pantalla completa, o directamente sin ningún feedback si la resincronización es tan rápida que el usuario no llega a notar el flash.

En el caso de login (`syncAfterSignIn()`, agregado en el change anterior `sync-user-data-to-cloud`), usar `InboxLoading` con mensaje tiene sentido porque no hay contenido previo que preservar — la pantalla ya estaba vacía. En el caso de resume, sí hay contenido cargado, y reemplazarlo por un spinner a pantalla completa (o no mostrar nada) es peor UX que mantener el Inbox visible con un indicador no invasivo.

## Goals / Non-Goals

**Goals:**
- Mostrar un `LinearProgressIndicator` debajo del `AppBar` del Inbox mientras la sincronización de resume está en curso.
- No ocultar ni reemplazar los artículos ya renderizados mientras sincroniza.
- Ocultar el indicador automáticamente al terminar (éxito o error) sin necesitar acción del usuario.

**Non-Goals:**
- No se toca el pull-to-refresh (`syncAndReload()`), que ya tiene su propio `RefreshIndicator` nativo de Flutter — ese caso ya tiene feedback visual.
- No se toca el flujo de login (`syncAfterSignIn()`), que ya muestra su propio estado de carga con mensaje.
- No se agrega manejo de error visible distinto al que ya existe (si `SyncUserData` o el fetch de feeds fallan silenciosamente hoy, este change no cambia eso — solo la señal de "está en curso").

## Decisions

- **Nuevo campo `isSyncingInBackground` en `InboxLoaded`, en vez de un estado nuevo**: agregar un estado `InboxSyncing` obligaría a la UI a manejar un tercer caso en el árbol de estados, y duplicaría la lista de artículos que `InboxLoaded` ya carga (sería necesario copiar `articles`/`hasSources`/`readArticleId` al nuevo estado para no perder el contenido en pantalla). Un campo booleano en `InboxLoaded` (default `false`) es la mínima extensión: `InboxScreen` solo necesita leer `loaded.isSyncingInBackground` para decidir si renderiza el `LinearProgressIndicator`, sin cambiar el resto del árbol de estados ni el `buildWhen` existente.
  - Alternativa considerada: estado `InboxSyncing extends InboxLoaded` (subclase). Descartada por ser más código para el mismo resultado, y porque `InboxState` es `sealed` con pattern matching por tipo — una subclase de `InboxLoaded` complica el `switch`/`is` que ya usa `InboxScreen`.
- **Método explícito `syncInBackground()` en `InboxCubit`**, en vez de reutilizar `loadArticles()`: `loadArticles()` emite `InboxLoading` (pantalla completa) antes de recargar, que es exactamente el comportamiento que se quiere evitar en resume. El nuevo método emite `InboxLoaded(..., isSyncingInBackground: true)` a partir del estado actual, corre `SyncUserData.execute()`, y vuelve a recargar con `isSyncingInBackground: false`.
- **`app.dart` (`didChangeAppLifecycleState`) pasa a llamar a `syncInBackground()`** en vez de `SyncUserData.execute().then((_) => loadArticles())`, moviendo la orquestación adentro del cubit (consistente con `syncAfterSignIn()` y `syncAndReload()`, que ya viven ahí).

## Risks / Trade-offs

- [Riesgo] Si `_reload()` tarda en tener datos nuevos (red lenta), el `LinearProgressIndicator` puede quedar visible varios segundos → Mitigación: ninguna especial: es el comportamiento esperado de un indicador de progreso indeterminado; no se agrega timeout en este change.
- [Riesgo] Si el estado cambia a `InboxLoading` por otra razón mientras `isSyncingInBackground` está en `true` (por ejemplo, el usuario navega y vuelve disparando `loadArticles()`), se pierde la bandera junto con el resto del estado anterior — comportamiento aceptable: `loadArticles()` reemplaza el estado completo, y no hay dos sincronizaciones de resume concurrentes en la práctica (un solo `didChangeAppLifecycleState` a la vez).
