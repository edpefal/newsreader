## Context

`AdaptiveShell` (`lib/presentation/app/adaptive_shell.dart`) envuelve el `StatefulShellRoute.indexedStack` completo (las 5 branches) en un único `Scaffold` con su propio `appBar` (logo/título/buscador) y, en modo compact, `drawer`. Dentro de cada branch, `_adaptiveBranchShell` (`lib/presentation/app/router.dart:129`) decide si el `child` de esa branch (lista raíz, o el `ReaderScreen`/`SourceDetailScreen`/`SummaryDetailScreen` empujado) se muestra solo (compact, "push a pantalla completa") o dentro de `AdaptiveListDetailScaffold` (expanded, dos paneles). El bug: `AdaptiveShell` no sabe nada de esa decisión por-branch, así que en compact sigue mostrando su `appBar`/`drawer` exterior encima de cualquier pantalla de detalle empujada, incluso cuando esa pantalla ya trae su propio `AppBar` (ver proposal.md - Why).

Las 5 branches raíz son `/`, `/favorites`, `/archive`, `/sources`, `/summaries`. Solo esas rutas raíz (exactas) representan "la lista de la tab activa"; cualquier sub-ruta (`/article/:id`, `/favorites/article/:id`, `/sources/:id`, `/sources/:id/article/:articleId`, `/summaries/:date`, `/summaries/:date/article/:articleId`, y sus `/web`) es una pantalla de detalle empujada.

## Goals / Non-Goals

**Goals:**
- En modo compact, ocultar `appBar` y `drawer` de `AdaptiveShell` exactamente cuando la ruta activa dentro del `navigationShell` no sea la raíz de la branch actual.
- Que el chrome reaparezca de inmediato al volver a la raíz de la branch (push pop), sin depender de rebuilds manuales ni de listeners adicionales.
- Cubrir los tres flujos de detalle: artículo (Inbox/Favoritos/Archivo/Fuentes/Resúmenes), fuente (Fuentes) y resumen diario (Resúmenes).

**Non-Goals:**
- No cambia nada del modo expanded (el `AppBar` principal sigue siempre visible ahí, junto al `NavigationRail` y el layout de dos paneles) — ya cubierto por `adaptive-master-detail`.
- No introduce un mecanismo genérico de "rutas anidadas conocen su shell padre"; la solución se limita a lo que `AdaptiveShell` necesita para esta decisión puntual.
- No toca `ReaderScreen`, `SourceDetailScreen` ni `SummaryDetailScreen` — sus propios `AppBar` ya son correctos, el bug está en el shell exterior.

## Decisions

**Detectar "estamos en una raíz de branch" comparando el path actual contra las 5 raíces conocidas.**

`AdaptiveShell.build()` ya puede leer `GoRouterState.of(context)` (o el `Uri` vigente vía `GoRouter.of(context).routerDelegate.currentConfiguration`) para obtener el path actualmente resuelto. Se compara ese path contra la lista fija `['/', '/favorites', '/archive', '/sources', '/summaries']`: si coincide exactamente, se está en la lista raíz de la tab activa (chrome visible); cualquier otro path bajo la branch actual es una pantalla de detalle empujada (chrome oculto).

Alternativas consideradas:
- *Pasar un flag explícito desde cada `GoRoute` builder hasta `AdaptiveShell`*: requeriría un `InheritedWidget`/`ValueNotifier` compartido que cada ruta de detalle actualice al montarse, más código y más superficie para desincronizarse. Comparar el path resuelto es más simple porque go_router ya expone esa información sin estado adicional.
- *Que cada pantalla de detalle oculte el `AppBar` exterior "desde adentro"* (ej. con un `Scaffold` que se superponga): frágil, porque el `AppBar` exterior vive en un `Scaffold` ancestro distinto — no hay forma limpia de "apagarlo" desde un descendiente sin exponer un canal de comunicación igual de explícito que la opción anterior, con la ventaja adicional de que la comparación de paths ya resuelve el caso sin tocar las pantallas de detalle.

**Solo aplica en modo compact; en expanded la condición ni se evalúa.**

Coherente con que el bug y el requisito modificado son exclusivamente de compact (`WindowSizeClass.compact`); en expanded el `appBar` siempre se muestra sin condición, como ya hace el código actual.

## Risks / Trade-offs

- [Riesgo] La lista de raíces (`/`, `/favorites`, `/archive`, `/sources`, `/summaries`) queda hardcodeada en `AdaptiveShell`, duplicando el conocimiento de `rootPath` que ya usan `articleListBranch`/las branches de Fuentes y Resúmenes en `router.dart`. → Mitigación: extraer esa lista a una constante compartida (o derivarla de las mismas branches) en vez de repetirla como literal en dos archivos.
- [Riesgo] Si en el futuro se agrega una sub-ruta bajo una raíz que NO deba tratarse como "detalle a pantalla completa" (ej. un modal o tab secundaria dentro de una lista), la heurística de "cualquier path distinto a la raíz = ocultar chrome" la ocultaría incorrectamente. → Mitigación: no hay casos así hoy; si aparecen, la comparación puede evolucionar a una lista explícita de prefijos de detalle en vez de "todo lo que no es la raíz".
