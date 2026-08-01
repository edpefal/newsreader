## Context

`lib/presentation/app/router.dart` define tres `GoRoute` que leen el objeto completo desde `state.extra` con un cast directo (`state.extra as Article`, `as NewsSource`, `as DailySummary`). `extra` es un valor en memoria de go_router: no sobrevive a la destrucción/recreación del `Element` tree que ocurre cuando Android mata el proceso en background y lo restaura, ni a un deep link que abra la ruta directamente. En esos casos `extra` es `null` y el cast lanza `_TypeError`, tirando abajo toda la navegación (ver stack trace: `MaterialApp` crashea completo, no solo la pantalla).

`ArticleRepository.getArticleById(String id)` ya existe. `SourceRepository` y `SummaryRepository` no tienen un método de lookup por id — solo devuelven listas completas (`getSources()`, `getAll()`).

## Goals / Non-Goals

**Goals:**
- Ninguna de las tres rutas debe crashear si `extra` es `null`; deben resolver el dato por su identificador de la URL.
- El camino feliz (navegación normal con `extra` presente) no debe agregar latencia ni parpadeo de loading — se sigue usando `extra` directo cuando está disponible.
- Un id/fecha que no corresponde a ningún registro local (dato borrado) redirige a `/` en vez de crashear o quedar en blanco.

**Non-Goals:**
- No se cambia cómo `extra` se pasa hoy al navegar (`context.push(..., extra: objeto)` se mantiene igual en los `onTap` de las listas) — sigue siendo el camino rápido.
- No se persiste ni serializa `extra` (no se adopta `RouteInformationParser` custom ni restauración de estado de Flutter) — seguimos resolviendo por id on-demand, más simple y suficiente.
- No se toca `/sources/import-opml` (recibe un `String` de XML generado en el momento, no un registro persistido — no tiene sentido "recuperarlo por id").

## Decisions

### 1. Widget genérico `RouteExtraResolver<T>` en `core/navigation/`
En vez de triplicar el patrón "si extra viene tipado, usarlo; si no, resolver async por id; si no existe, redirigir" en cada builder de `router.dart`, se extrae un widget compartido parametrizado por tipo:

```
RouteExtraResolver<Article>(
  extra: state.extra,
  resolve: () => getIt<ArticleRepository>().getArticleById(id),
  onNotFound: () => context.go('/'),
  builder: (context, article) => ReaderScreen(article: article, ...),
)
```

Internamente: si `extra is T`, construye `builder(context, extra)` de inmediato (sin `FutureBuilder`, cero latencia). Si no, usa un `FutureBuilder<T?>` que muestra un `Scaffold` con `CircularProgressIndicator` mientras resuelve, y al completar: si el resultado es `null` llama `onNotFound`, si no, `builder(context, data)`.

Alternativa descartada: repetir el `if (extra == null) { ... } else { ... }` en cada uno de los 3 builders. Se descarta por duplicar la misma lógica de resolución/loading/redirect 3 veces con el único cambio siendo el tipo y el repositorio — justo el caso donde una abstracción chica paga su costo.

### 2. Agregar `getSourceById`/`getById` a nivel de repositorio, filtrando la lista ya cargada
`SourceRepository.getSourceById(String id)` y `SummaryRepository.getById(String id)` se implementan reusando `getSources()`/`getAll()` (ya traen todo desde Hive a memoria) y filtrando por `id` en Dart, en vez de agregar un método nuevo a nivel de datasource con lookup directo por key de Hive.

Alternativa descartada: lookup directo por key en `SourceLocalDataSource`/`SummaryLocalDataSource`. Se descarta porque la key de Hive de `sources` es el `id` pero la de `daily_summaries` es una `dateKey(date)` derivada de la fecha, no el `id` — un lookup directo por key no funcciona para summaries sin primero mapear id→fecha (lo cual requeriría cargar todo igual). Filtrar la lista completa es más simple y el volumen de datos (fuentes suscritas, resúmenes diarios) es chico — no es un problema de performance real.

### 3. `onNotFound` redirige a `/`, no muestra una pantalla de error dedicada
Si el id no existe (artículo borrado, fuente eliminada, resumen purgado), la experiencia es simplemente volver al Inbox — no se justifica una pantalla de error nueva para un caso raro (dato borrado mientras la navegación estaba en el aire).

## Risks / Trade-offs

- **[Riesgo] El `FutureBuilder` introduce un frame de loading que no existía en el camino feliz** → Mitigado: solo se activa cuando `extra` no es del tipo esperado, que es exactamente el caso que hoy crashea — antes no había "camino feliz" ahí, había un crash.
- **[Riesgo] Filtrar `getSources()`/`getAll()` en memoria escala mal si el usuario tiene miles de fuentes/resúmenes** → Aceptado: son colecciones acotadas por naturaleza (fuentes suscritas por un humano, un resumen diario por día) — no se justifica una key secundaria en Hive para este volumen.

## Migration Plan

Sin migración de datos. Cambio de código puro y retrocompatible: el camino feliz (navegación con `extra`) es idéntico a hoy. Se puede desplegar sin coordinación con el backend.
