## Context

Ver `proposal.md` - Why. Puntos técnicos relevantes:

- `app_fr.arb` tiene ~85 claves, todas hoy en inglés (copia literal de `app_en.arb`). 8 de ellas usan sintaxis ICU (`{count, plural, =1{...} other{...}}`) o placeholders simples (`{name}`, `{date}`).
- El equivalente en español (`app_es.arb`) ya resolvió la pregunta de registro: tuteo (informal, "tú"), no voseo ni tratamiento formal.
- `test/widget/core/utils/localized_date_formatter_test.dart` tiene una aserción explícita `expect(frResult, isNot(equals(esResult)))` en un test y comentarios `// placeholder fr = en` en otro — ambos escritos a propósito para el estado actual (placeholder), documentando que el comportamiento cambiaría en este change.

## Goals / Non-Goals

**Goals:**
- `app_fr.arb` completo en francés real, sin ninguna clave que siga siendo una copia del inglés (salvo excepciones legítimas explícitas).
- Mismo registro de voz que el español: informal ("tu"), consistente con el tono de marca ya establecido.

**Non-Goals:**
- No se re-evalúa la decisión de qué texto va en cada pantalla (eso ya se resolvió al escribir `app_en.arb`/`app_es.arb`); acá solo se traduce el contenido ya existente.
- No se agregan claves nuevas ni se cambia ninguna clave de inglés o español.
- No se traduce ningún mensaje de `AppException` (fuera de alcance, Change 3).

## Decisions

### 1. Francés estándar/internacional, registro informal ("tu")
Se traduce a un francés neutro apto para cualquier región francófona (Francia, Bélgica, Suiza, Canadá francófono), evitando vocabulario marcadamente regional (ej. "courriel" es más típico de Quebec; se usa "e-mail", entendido universalmente, igual que se mantuvo "email" como préstamo en español). Se usa el tuteo francés ("tu"/"ton"/"ta") en vez del tratamiento formal ("vous"), espejando la decisión ya tomada para el español neutro — mantiene una voz de marca consistente entre idiomas en vez de sonar más distante en francés que en español.

**Alternativa considerada**: usar "vous" (formal), más común en contextos corporativos/gubernamentales franceses. Se descarta porque el resto de la app (español tuteo, inglés informal por naturaleza) ya establece un tono cercano/casual; mezclar un registro formal solo en francés sería inconsistente con la voz de marca.

### 2. Sintaxis ICU: `=1{...}`/`other{...}` no necesita ajuste para francés
El francés en CLDR categoriza como "one" tanto `0` como `1` (a diferencia de español/inglés, donde "one" es solo `1`). Esto importaría si el proyecto usara las categorías nombradas (`one`/`other`), pero todas las claves con plural en este proyecto usan la forma explícita `=1{...}` (coincidencia de valor exacto), que en ICU MessageFormat es independiente del locale — siempre se evalúa antes que las categorías nombradas, en cualquier idioma. No hace falta agregar una rama `=0` porque ninguno de los casos de uso actuales (fuentes importadas, artículos, feeds pendientes) puede dar 0 en el punto donde se muestra el mensaje. Se traduce el texto dentro de cada rama `=1`/`other` sin tocar la estructura.

**Alternativa considerada**: reescribir los plurales usando categorías CLDR nombradas (`one`/`other`) en vez de `=1`/`other`. Se descarta: cambiaría el comportamiento también para inglés y español (fuera de alcance) y no aporta nada aquí, ya que `=1` ya cubre el caso exacto que le importa a la UI.

### 3. Test de regresión: comparación clave por clave contra `app_en.arb`, con lista de excepciones
Se agrega un test (`test/unit/l10n/french_translation_completeness_test.dart` o similar) que lee ambos `.arb`, itera las claves de `app_fr.arb`, y falla si el valor es idéntico al de `app_en.arb` para una clave que no esté en una lista explícita de excepciones esperadas (inicialmente: `appTitle`, que es el nombre de marca y debe ser igual en los tres idiomas).

**Alternativa considerada**: comparar todo el archivo o solo contar claves. Se descarta: no detecta el caso real (una clave puntual que quedó sin traducir en medio de un barrido grande), que es exactamente el riesgo que este test existe para prevenir.

## Risks / Trade-offs

- **[Riesgo] Una traducción al francés hecha sin revisión de un hablante nativo puede tener errores de matiz o gramática no triviales de detectar automáticamente.** → Mitigación: el test de completitud solo garantiza que "no quedó en inglés", no que la traducción sea idiomática; se deja una nota en `tasks.md` para que el usuario revise el `app_fr.arb` final si tiene manera de validarlo con un hablante nativo, sin bloquear el change por eso.
- **[Riesgo] Alguna clave nueva agregada en el futuro (Change 3 u otros) podría colar contenido en inglés en `app_fr.arb` sin que nadie lo note.** → Mitigación: el test de completitud de este change corre en cada `flutter test`, así que cualquier clave nueva sin traducir al francés lo va a detectar automáticamente de ahí en adelante — no es una protección de una sola vez.

## Migration Plan

- Cambio de una sola pasada: editar `app_fr.arb`, correr `flutter gen-l10n`, agregar el test de completitud, actualizar las dos aserciones de `localized_date_formatter_test.dart` que hoy esperan inglés, correr la suite completa.
- Rollback: revertir el commit; no hay migración de datos ni de esquema.
