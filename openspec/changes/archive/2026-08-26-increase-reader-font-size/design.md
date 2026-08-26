## Context

`FwhHtmlContentRenderer` (`lib/core/widgets/fwh_html_content_renderer.dart:422-452`) ya define dos estilos de texto según el flag `readerMode`:
- `readerMode: true` → `theme.textTheme.bodyLarge` con `fontSize: 18`, `height: 1.7`, `letterSpacing: 0.2`.
- `readerMode: false` (default) → `theme.textTheme.bodyMedium` (`fontSize: 15`, `height: 1.5`, definido en `app_theme.dart:146-147`).

`ReaderScreen` (`lib/features/reader/presentation/screens/reader_screen.dart:187-190`) construye `FwhHtmlContentRenderer` sin pasar `readerMode`, por lo que hoy usa siempre la rama `bodyMedium` (15px) — la rama de 18px nunca se ejecuta en producción. Ver proposal.md - Why.

## Goals / Non-Goals

**Goals:**
- Que el cuerpo de un artículo abierto en el lector se muestre con un tamaño de fuente notablemente mayor al actual (15px).
- Reusar y activar el mecanismo `readerMode` ya existente en vez de introducir un estilo paralelo.

**Non-Goals:**
- No se agrega una preferencia de usuario para elegir el tamaño de fuente (fuera de alcance de este change).
- No se modifica el tamaño de fuente de las listas de artículos ni de otros usos de `bodyMedium`/`bodyLarge` en la app.
- No se toca el renderizado de HTML crudo de email (`_RawEmailWebView`), que no pasa por `textStyle`.

## Decisions

- **Activar `readerMode: true` en `ReaderScreen` en vez de cambiar `bodyMedium` directamente.** `bodyMedium` se usa en otras partes de la UI (listas, previews) que no deben crecer. El flag `readerMode` ya existe para separar el estilo del lector del resto de la app; solo falta conectarlo.
- **Aumentar el `fontSize` del branch `readerMode` de 18 a 20px**, manteniendo `height: 1.7` y `letterSpacing: 0.2`. 20px da un salto perceptible sobre el tamaño actual (15px efectivo) sin llegar a un tamaño exagerado para pantallas de teléfono. Alternativa considerada: subir solo a 19px — descartada por ser un cambio poco perceptible respecto al problema reportado.
- **No introducir un nuevo campo de tema ni constante compartida.** El valor sigue viviendo como constante local en `FwhHtmlContentRenderer`, consistente con cómo ya estaba definido antes de este change.

## Risks / Trade-offs

- [Texto más grande podría causar que imágenes o elementos embebidos con dimensiones fijas en el HTML del artículo se vean desproporcionados respecto al texto] → Mitigación: el layout de `HtmlWidget` maneja el texto de forma independiente al tamaño de imágenes/iframes; no se esperan regresiones, pero se debe revisar visualmente un artículo con imágenes durante la verificación manual.
- [Un artículo con texto ya cercano al límite de una pantalla pequeña ahora requiere más scroll] → Aceptado como trade-off esperado de mejorar la legibilidad; no requiere mitigación adicional.
