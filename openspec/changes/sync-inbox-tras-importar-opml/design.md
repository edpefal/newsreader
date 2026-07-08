## Context

`ImportOpmlScreen` escucha el estado `ImportOpmlDone` y llama `Navigator.of(context).pop(true)`. `InboxCubit` está provisto en el root del árbol de widgets (en `App` via `MultiBlocProvider`), por lo que es accesible desde cualquier pantalla vía `context.read<InboxCubit>()`.

El flujo actual no dispara ninguna señal al inbox al completar la importación. La solución es mínima: una línea adicional en el handler existente de `ImportOpmlDone`.

## Goals / Non-Goals

**Goals:**
- Al completar una importación OPML, el inbox se sincroniza automáticamente sin intervención del usuario

**Non-Goals:**
- Modificar el flujo de `AddSource` (fuente individual) — tiene comportamiento diferente y aceptable
- Mostrar progreso de sync dentro de `ImportOpmlScreen` — el usuario ya regresó al home cuando el sync corre

## Decisions

### Llamar syncAndReload() directamente desde ImportOpmlScreen

**Decisión:** En el `BlocListener` de `ImportOpmlScreen`, cuando el estado es `ImportOpmlDone`, llamar `context.read<InboxCubit>().syncAndReload()` antes de `Navigator.pop()`.

**Alternativa considerada:** Pasar un callback desde el exterior o usar un event bus. Descartado — `InboxCubit` ya es accesible en el contexto y el patrón `context.read<X>()` se usa en otras pantallas (e.g., `SourcesScreen` accede a `SourcesCubit`).

**Alternativa considerada:** Disparar el sync en `AddSourceScreen` al detectar que `import-opml` regresó con `true`. Descartado — requeriría añadir `await` a `context.push` y propagar la señal un nivel más; más frágil y más código.

## Risks / Trade-offs

- **[Trade-off] syncAndReload() corre en background mientras el usuario ya está en el home** → Aceptable. El InboxBloc actualiza la UI reactivamente cuando el sync termina, sin bloquear al usuario.
- **[Riesgo menor] Si el usuario navega fuera del home antes de que el sync termine** → No hay problema, el sync actualiza Hive y al volver al inbox el estado ya es correcto.
