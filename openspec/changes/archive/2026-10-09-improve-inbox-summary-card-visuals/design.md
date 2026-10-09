## Context

`InboxSummaryCard` (`features/inbox/presentation/widgets/`) pinta avatares con la inicial de `SummarySourceBlock.sourceName`, sin imagen. `InboxCubit._reload` ya llama a `GetSources.execute()` en cada recarga (para `hasSources`) y descarta la lista. El resumen pendiente también se actualiza por un `Stream` (`_onPendingSummaryChanged`) sin recargar fuentes. Ver `proposal.md` para la motivación.

Restricciones: un feature no importa de otro (inbox no puede usar `ResolveSummarySources` de `summaries`); `inbox_cubit.dart` ya depende de `GetSources`, así que no se agrega ninguna dependencia nueva.

## Goals / Non-Goals

**Goals:**
- Mostrar el ícono real de las fuentes del resumen en la tarjeta sin consultas extra ni acoplar features.
- Mantener intactos el swipe, la accesibilidad, el estado seleccionado y el CTA.

**Non-Goals:**
- No cambiar el CTA, los textos, el conteo, ni la lógica de qué resumen se muestra.
- No agregar un use case nuevo ni mover `ResolveSummarySources` a `core/`.

## Decisions

**1. Mapa `sourceId → iconUrl` en `InboxLoaded`.**
`_reload` ya tiene la lista de fuentes; se deriva de ahí `Map<String, String?> summarySourceIcons` y se guarda en el estado (con `Equatable`). La tarjeta lo recibe por constructor desde `InboxScreen`. Alternativas: (a) reutilizar `ResolveSummarySources` moviéndolo a `core/` — más superficie y toca otro feature por un mapa que el cubit ya puede construir; (b) leer fuentes desde el widget — viola la regla de no lógica de datos en presentación.

**2. Mapa completo de fuentes o solo las del resumen.**
Se guarda solo el subconjunto de fuentes presentes en `pendingSummary.sourceBlocks`, no todas las fuentes: el estado queda pequeño y el `Equatable` no cambia por fuentes ajenas al resumen.

**3. Actualizaciones por el `Stream` del resumen.**
Si llega un resumen nuevo por sincronización, `_onPendingSummaryChanged` conserva el mapa actual cuando todos los `sourceId` del resumen ya están en él; si falta alguno, vuelve a leer las fuentes (`GetSources`, local) antes de emitir. Así una fuente nueva no queda con la inicial hasta la siguiente recarga completa.

**4. Avatar con imagen y fallback.**
El avatar usa `CachedNetworkImageWidget` (abstracción de `core/widgets`) recortado en círculo, con el anillo de 2px del color del relleno. El `placeholderBuilder` conserva el aspecto actual (inicial sobre círculo translúcido), que también cubre fuente sin ícono, eliminada o con la imagen fallando. Alternativa: reutilizar el `SummarySourceAvatar` de `summaries` — descartada por la regla entre features, y porque su fallback usa un óxido sólido que desaparecería sobre el óxido de la tarjeta.

**5. Tamaños.**
Avatar 34 (antes 28) con solape de 10; radio 14 también en el borde seleccionado y en `_SwipeDismissBackground`, para que el swipe no deje esquinas distintas. El destello es `Icons.auto_awesome_outlined` (el mismo de la lista de resúmenes), de 16, y queda fuera del árbol semántico (la tarjeta ya usa `excludeSemantics`).

## Risks / Trade-offs

- [Ícono de fuente óxido sobre la tarjeta óxido: el avatar se funde] → El anillo de 2px del color del relleno lo recorta; si en la práctica no basta, se pasa a un anillo del color de texto de la tarjeta. Se revisa en el simulador, en claro y oscuro.
- [El mapa agrega un campo al estado y `InboxLoaded` se construye en varios lugares] → Se propaga en todos los `copy`/`emit` existentes (hay ~8) y lo cubren los tests del cubit.
- [Imagen que tarda en cargar] → El placeholder (inicial) se muestra mientras tanto, sin salto de tamaño porque el avatar tiene tamaño fijo.

## Migration Plan

Solo cliente, sin migración. Rollback: revertir el PR.
