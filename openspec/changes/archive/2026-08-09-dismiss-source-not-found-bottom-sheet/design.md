## Context

`AddSourceScreen` (`lib/features/sources/presentation/screens/add_source_screen.dart`) escucha `AddSourceCubit` con un `BlocListener`. Cuando el estado es `AddSourceFeedDiscoveryFailed`, muestra un `SnackBar` vía `ScaffoldMessenger.of(context).showSnackBar(...)` con `backgroundColor: colorScheme.error` y una `SnackBarAction` "Generar email". Hoy ese `SnackBar` usa la duración por defecto de Flutter y no hay ningún código que lo oculte explícitamente. Ver proposal.md - Why.

## Goals / Non-Goals

**Goals:**
- Controlar explícitamente el ciclo de vida del `SnackBar` de error de detección: se cierra al reintentar, al salir de la pantalla, o al tocar una X, y no por timeout.

**Non-Goals:**
- No se cambia el mecanismo de UI (sigue siendo un `SnackBar` de Flutter, no un `MaterialBanner` ni un widget custom anclado).
- No se modifica el flujo de generación de email en sí (`AddSourceGeneratingEmailFeed`, `AddSourceEmailFeedGenerated`).

## Decisions

- **Mantener `SnackBar` en vez de migrar a un widget persistente propio**: es el mecanismo ya usado en el resto de la pantalla (éxito, error genérico), evita introducir un nuevo patrón de UI para un solo caso, y el problema reportado es de ciclo de vida (cuándo se oculta), no de mecanismo visual.
- **`duration: Duration(days: 1)` (efectivamente indefinida) en vez de la duración por defecto (4s)**: como el cierre pasa a ser explícito (submit, dispose, botón X), dejar la duración por defecto causaría que el aviso desaparezca solo antes de que el usuario llegue a decidir, contradiciendo el comportamiento pedido.
- **Cierre vía `ScaffoldMessenger.of(context).hideCurrentSnackBar()`**: es la API estándar de Flutter para ocultar un `SnackBar` activo sin depender de temporizadores propios.
  - En `_submit`: se llama antes de disparar `addSource` para limpiar cualquier aviso previo.
  - En `dispose()` de `_AddSourceViewState`: se llama para que el aviso no quede huérfano si el usuario navega fuera. `hideCurrentSnackBar` es seguro de llamar incluso si no hay `SnackBar` visible.
- **Ícono de cerrar como parte del `content` del `SnackBar`** (un `Row` con el texto y un `IconButton(Icons.close)` que llama a `hideCurrentSnackBar()`), en vez de la propiedad nativa `SnackBarAction`, porque el `SnackBar` ya usa esa propiedad para "Generar email" y Flutter solo permite una `action` por `SnackBar`.

## Risks / Trade-offs

- [Con duración larga, si `hideCurrentSnackBar()` no se invoca en algún camino no contemplado (ej. error deja el widget en un estado inesperado), el aviso podría quedar visible indefinidamente] → Mitigación: el ícono de cerrar manual siempre está disponible como salida de emergencia, y `dispose()` cubre cualquier forma de salir de la pantalla.
