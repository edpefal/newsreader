## Context

`SettingsScreen` (`lib/features/settings/presentation/screens/settings_screen.dart`) es un único `StatefulWidget` sin sub-widgets propios; todo el árbol de UI vive inline en `build()`. Ver `proposal.md` para el porqué del cambio. El mockup de referencia validado con el usuario está en https://claude.ai/code/artifact/26ca5b00-e872-4907-aa98-f62584f1b66f.

`AppTheme` (`lib/presentation/theme/app_theme.dart`) ya define el vocabulario tipográfico a reutilizar — no se crea ningún estilo nuevo:
- `textTheme.titleMedium`: serif (Newsreader) w600 — usado hoy para los headers de sección existentes.
- `textTheme.bodyLarge`: sans (IBM Plex) 18px — el tamaño principal de contenido en el resto de la app (lector, tiles).
- `textTheme.bodyMedium`: sans 15px — texto secundario.
- `ReevoAccent.unreadFavoriteAccent`: acento óxido, ya usado explícitamente en `filledButtonTheme`/`floatingActionButtonTheme`, nunca vía `colorScheme.primary`.
- `colorScheme.outline` / `surfaceContainerHighest`: el hairline sutil (`_hairline`/`_darkHairline`) ya usado como color de división en el resto de la app.

## Goals / Non-Goals

**Goals:**
- Un único estilo de texto por rol (header de sección / texto principal de fila / texto secundario), aplicado sin excepción a las 3 secciones.
- Las 3 acciones de cuenta agrupadas bajo su propio header, en su propio bloque visual.
- Reutilizar exclusivamente tokens ya existentes en `AppTheme` — no se agregan colores, tamaños ni radios nuevos.

**Non-Goals:**
- No se cambia el comportamiento de exportar datos, cerrar sesión ni eliminar cuenta (mismos use cases, mismos diálogos de confirmación y manejo de errores).
- No se toca el selector de tema (`SegmentedButton` + `ThemeCubit`) más allá de que quede visualmente consistente con el resto de la pantalla.
- No se introduce ningún widget compartido en `core/widgets/` — el alcance es un solo archivo.

## Decisions

**Estilos normalizados como getters privados en `_SettingsScreenState`**, en vez de constantes sueltas repetidas 3 veces:
- `_sectionHeaderStyle` → `Theme.of(context).textTheme.titleMedium`.
- `_rowTextStyle` → `Theme.of(context).textTheme.bodyLarge` (reemplaza tanto el `bodyLarge` ad-hoc de la línea de plan como el estilo default de `ListTile.title` en las 3 acciones — ambos quedan iguales).
- `_secondaryTextStyle` → `Theme.of(context).textTheme.bodyMedium` con color `colorScheme.onSurfaceVariant` (ya el patrón usado hoy para el email).

Alternativa descartada: extraer un widget compartido `SettingsSectionHeader` en `core/widgets/`. Se descarta porque el uso es exclusivo de esta pantalla (una sola pantalla de Settings en la app) — crear una abstracción para un solo consumidor viola la regla de no diseñar para casos hipotéticos. Si en el futuro aparece una segunda pantalla con secciones agrupadas, se extrae en ese momento.

**Agrupación de filas de acción**: se envuelven las 3 filas (`ListTile`) de "Datos y sesión" en una `Column` con un `Divider(height: 1, thickness: 1, color: colorScheme.outline)` entre cada una (no después de la última), reemplazando el espaciado suelto actual. Mismo criterio ya usado en el resto de la app para separar sin usar `Card`/sombra.

**Orden de las filas**: Exportar mis datos → Cerrar sesión → Eliminar cuenta. Se mueve "Eliminar cuenta" al final (hoy está en el medio) siguiendo el patrón convencional de agrupar primero las acciones neutras y dejar la destructiva al final; sigue coloreada con `colorScheme.error` en icono y texto, pero ahora usando `_rowTextStyle.copyWith(color: colorScheme.error)` en vez de un `TextStyle` inline suelto sin relación con `_rowTextStyle`.

**Botón "Obtener Premium"**: pasa de `OutlinedButton` sin estilo (hereda el default de Material, no definido en `AppTheme`) a `OutlinedButton.styleFrom(foregroundColor: accent, side: BorderSide(color: accent))`, con `accent = Theme.of(context).extension<ReevoAccent>()!.unreadFavoriteAccent`. Consistente con cómo `FilledButton`/`FloatingActionButton` ya referencian ese color explícitamente en `AppTheme`.

**Nueva sección "Datos y sesión"**: nueva clave `settingsDataAndSessionSectionTitle` en los 3 `.arb`, siguiendo la convención `settings<Descripción>` ya usada por `settingsAccountTierSectionTitle` y `settingsThemeSectionTitle`.

**Orden de secciones**: "Tu cuenta" → "Apariencia" → "Datos y sesión" (última). Se decidió dejar las acciones de cuenta al final de la pantalla en vez de justo después de "Tu cuenta": así la primera pantalla visible al abrir Ajustes prioriza info + apariencia (lo que se consulta con más frecuencia) y las acciones, incluida la destructiva, quedan al fondo, no en el primer scroll.

**Badge de "Premium"**: cuando la cuenta es Premium, el label deja de ser texto plano y pasa a un chip (`Container` con `BoxDecoration(color: accent, borderRadius: 6)`) con el texto en mayúsculas, `labelLarge` w700, color `colorScheme.onPrimary` (mismo par de colores — `_paper`/`_darkSurface` — que ya usa `filledButtonTheme` como texto sobre fondo de acento, solo que referenciado vía token en vez de repetir el literal). "Free" se mantiene como texto plano con `_rowTextStyle`, sin badge — la asimetría es intencional: resalta el estado que vale la pena hacer notar (ya es premium), no el que invita a upgrade (ese ya tiene su propio botón).

## Risks / Trade-offs

- [Reordenar "Eliminar cuenta" al final cambia la posición muscular de un usuario acostumbrado al orden actual] → Riesgo bajo: la app tiene pocos usuarios activos en producción (ver memoria de contexto del proyecto) y el cambio de orden es la mejora de UX buscada (separar lo destructivo de lo neutral), no un efecto secundario accidental.
- [El delta spec de `settings-account-status` reemplaza un requisito agregado hace solo días] → Ya confirmado explícitamente con el usuario antes de escribir el proposal; no es un olvido.
