## Context

`AddSourceScreen` (`lib/features/sources/presentation/screens/add_source_screen.dart`) hoy es un `StatefulWidget` (`_AddSourceViewState`) con: el formulario de URL, un `BlocListener<AddSourceCubit, AddSourceState>` que reacciona a los estados (`AddSourceSuccess`, `AddSourceError`, `AddSourceFeedDiscoveryFailed`, `AddSourceEmailFeedGenerated`), y un `TextButton.icon` para "Importar desde OPML". La generación de email usa `AddSourceCubit.generateEmailFeed()` → emite `AddSourceGeneratingEmailFeed` → `AddSourceEmailFeedGenerated`, y hoy se dispara solo desde la acción del `SnackBar` de `AddSourceFeedDiscoveryFailed`. Ver proposal.md - Why.

## Goals / Non-Goals

**Goals:**
- La card de email vive siempre en pantalla, independiente del resultado de la detección de feed.
- El estado expandido/colapsado de la card es local a la pantalla (no requiere nuevo estado en `AddSourceCubit`).
- Reutilizar el flujo de generación existente (`generateEmailFeed()`, diálogo con la dirección) sin cambios de comportamiento en esa parte.

**Non-Goals:**
- No se cambia el use case `GenerateEmailFeed` ni el backend de `email-to-rss-feeds`.
- No se cambia el comportamiento de "Importar desde OPML" (solo se reubica visualmente).
- No se agrega scroll automático ni highlight conectando el snackbar de error con la card (el snackbar queda como aviso puro, sin puntero visual hacia la card).

## Decisions

- **El expand/collapse de la card es estado local (`bool _emailCardExpanded`) en `_AddSourceViewState`, no estado del Cubit**: es puramente presentacional (no afecta lógica de negocio ni se necesita en otro widget), así que vive donde ya vive el resto del estado de UI de esta pantalla (`_controller`, `_focusNode`).
- **La card se construye como un widget propio `_EmailFeedCard`** (o similar, privado al archivo) en vez de inline en `build()`: mantiene `build()` legible y aísla el `AnimatedSize` + contenido condicional.
- **`AnimatedSize` envolviendo un `Column` con `mainAxisSize: MainAxisSize.min`**: es el patrón estándar de Flutter para expandibles con contenido variable, sin depender de `ExpansionTile` (cuyo estilo de Material no calza con el diseño de card con ícono+título+descripción ya bocetado).
- **Auto-colapso vía `setState` en los mismos puntos donde hoy se reacciona a éxito**: en el `BlocListener`, al recibir `AddSourceEmailFeedGenerated` (tras confirmar en el diálogo) y `AddSourceSuccess`, además de la lógica existente para esos estados, se resetea `_emailCardExpanded = false`.
- **El `SnackBar` de `AddSourceFeedDiscoveryFailed` pierde el segundo hijo de su `content` (la card de acción "Generar email") y su lógica asociada**: el `content` vuelve a ser solo el `Row` con el mensaje + ícono de cerrar (sin el `Align` con el `TextButton` de "Generar email" ni el `context.read<AddSourceCubit>().generateEmailFeed()` desde ahí).

## Risks / Trade-offs

- [Pantalla más larga por default (dos cards siempre visibles en vez de un `TextButton` + acción condicional) → puede requerir scroll en pantallas chicas cuando antes no hacía falta] → Mitigación: las cards son compactas (título + una línea de descripción cuando colapsadas), y el contenido por encima (formulario de URL) ya define la altura dominante; se verifica visualmente en un dispositivo real como parte de la implementación.
