## Context

Ver `proposal.md` para la motivación. Estado actual relevante:

- `ReaderScreen._buildContent(article, theme)` (`lib/features/reader/presentation/screens/reader_screen.dart:167-182`) solo chequea `article.contentHtml != null` — no usa `FeedContentChecker.isTruncated()`, que ya existe y ya usa el umbral oficial de 500 caracteres (`AppConstants.articleTruncatedThreshold`), hoy solo consumido por `GenerateDailySummary`.
- El AppBar del lector ya tiene un botón siempre visible ("Ver en navegador", ícono `open_in_browser`) que navega a `context.push('/article/${article.id}/web', extra: article)` — la misma ruta que se quiere ofrecer también desde el aviso nuevo.

## Goals / Non-Goals

**Goals:**
- Que el usuario entienda, sin tener que descubrirlo por su cuenta, que hay una forma de leer el artículo completo cuando el feed no lo trae.
- Reusar `FeedContentChecker.isTruncated()` en vez de duplicar la lógica del umbral de 500 caracteres.

**Non-Goals:**
- No se cambia el ícono ni el comportamiento del botón "Ver en navegador" del AppBar — sigue existiendo igual, el aviso nuevo es un acceso adicional al mismo destino, no un reemplazo.
- No se hace fetch del contenido completo del lado del cliente ni se intenta ningún tipo de scraping — el WebView sigue siendo la única vía para ver el contenido completo cuando el feed no lo trae.

## Decisions

### 1. El aviso es tocable (navega al WebView), no solo texto informativo

Un mensaje puramente informativo ("este feed no trae el contenido completo, mirá arriba a la derecha") sigue dependiendo de que el usuario note el ícono del AppBar. Hacer el aviso mismo tocable, ejecutando la misma navegación (`context.push('/article/${article.id}/web', extra: article)`) que ya usa el botón del AppBar, es una mejora de UX de costo mínimo — no requiere lógica nueva, solo reusar la llamada existente desde un segundo lugar.

### 2. Un solo texto de aviso, sin distinguir "nada de contenido" vs. "contenido corto"

Se consideró un texto distinto para "sin excerpt ni HTML" vs. "hay un adelanto corto" (ej. "esto es un adelanto" vs. "no hay contenido"), pero se descarta por simplicidad: la acción que el usuario necesita tomar es la misma en ambos casos (ir al sitio original), y mantener un solo texto evita duplicar copy para una distinción que no cambia el flujo.

### 3. Se elimina el mensaje "Contenido no disponible en el feed."

Reemplazado íntegramente por el aviso nuevo, que cubre el mismo caso (nada de contenido) además del caso de contenido corto que antes no generaba ningún aviso. No hay razón para mantener ambos mensajes en el caso de "nada de contenido" — sería redundante.

## Risks / Trade-offs

- **[Riesgo] El aviso tocable podría confundirse con contenido real y generar taps accidentales** → Mitigación: se estiliza visualmente distinto al contenido del artículo (ej. ícono + texto en itálica o con menor énfasis, similar al mensaje que reemplaza), consistente con el patrón ya usado para el mensaje de fallback actual.
