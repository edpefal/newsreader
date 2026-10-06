## Context

Ver `proposal.md` (Why) para el síntoma y la causa. Estado actual relevante:

- `supabase/functions/generate-daily-summaries/prompt.ts` (`buildPrompt`) rotula cada grupo de entrada como `Fuente: <nombre>\n- <título>: <extracto>…` y la instrucción de salida le pide a Gemini "el nombre de la fuente tal cual aparece abajo (sin la palabra "Fuente:")". `prompt_test.ts` fija ese rótulo de entrada.
- `index.ts` guarda `content: summaryText.trim()` tal como lo devuelve Gemini y, por separado, `source_blocks` (`buildSourceBlocks`, determinista, desde las filas de artículos). `source_blocks` nunca depende del texto del modelo.
- El cliente (`summary_detail_screen.dart`) deriva el título de cada bloque de la primera línea del texto (`_parseBlocks`) y busca su agrupación con `sourceName.trim() == title` (`_matchingSourceBlock`). Los links y chips salen exclusivamente de ese emparejamiento.
- El resumen se genera una sola vez por día y usuario (capability `daily-summaries`, "Un único resumen por día, sin regeneración"): un resumen ya guardado con un encabezado malo no se corrige regenerándolo.

## Goals / Non-Goals

**Goals:**
- Que el emparejamiento de la pantalla de detalle sea robusto a una etiqueta `Fuente:`/`Source:` delante del nombre, también en resúmenes ya guardados.
- Que los resúmenes nuevos se persistan con el encabezado limpio, sin depender de que el modelo obedezca la instrucción.

**Non-Goals:**
- Cambiar el prompt, el modelo o la solicitud a Gemini (el comportamiento del modelo no es determinista ni verificable offline).
- Reescribir o migrar los `content` ya guardados en `daily_summaries`.
- Cambiar el layout de la pantalla de detalle o su embebido en el master-detail de iPad.
- Resolver el caso de varios renglones de encabezado o de markdown (`**TechCrunch**`) en el texto del modelo: no se observó, y el prompt ya lo prohíbe.

## Decisions

**1. Normalizar en el cliente, y emparejar primero por igualdad exacta.**
Un helper puro (`lib/features/summaries/domain/summary_block_title.dart`) expone la normalización del título: quita un prefijo `^\s*(fuente|source)\s*:\s*` sin distinguir mayúsculas (cubre `Fuente:`, `Source:` y `Source :` del francés) y devuelve el resto sin espacios sobrantes; si el resto quedaría vacío, devuelve el título original. `_matchingSourceBlock` intenta primero la igualdad exacta con el título crudo y solo si falla reintenta con el título normalizado. El título que se muestra en negrita es el normalizado.
- *Por qué exacto primero:* una fuente cuyo nombre real empieza con "Fuente:" o "Source:" (poco probable, pero posible) sigue emparejando como hoy; la normalización solo actúa donde antes no había emparejamiento, así que no puede romper un caso que ya funcionaba.
- *Alternativa descartada — emparejar por posición con `sourceBlocks`:* depende de que el modelo respete el orden y la cantidad de bloques; si no lo hace, asigna links a la fuente equivocada, un error peor que no mostrar links.
- *Alternativa descartada — `contains`/`endsWith`:* `"TechCrunch Daily"` también terminaría emparejando `"Daily"`.

**2. Limpiar en el servidor solo cuando el resto coincide con una fuente conocida.**
Una función pura nueva (`strip_source_label.ts`) recibe el texto del modelo y los nombres de fuente del resumen (`sourceBlocks.map(b => b.sourceName)`), divide el texto en bloques por línea en blanco, y por cada bloque, si la primera línea es `<etiqueta> <nombre>` y `<nombre>` es exactamente uno de los nombres conocidos, la reescribe como `<nombre>`. Se llama en `index.ts` justo antes de guardar. Todo lo demás (párrafos, líneas internas, bloques sin etiqueta) queda intacto, y los bloques se vuelven a unir con la misma línea en blanco que traían.
- *Por qué exigir un nombre conocido:* evita un falso positivo que dejaría el texto sin emparejar (p. ej. el modelo escribe `Fuente: desconocida` y se vuelve `desconocida`, que ya no coincide con nada de todos modos, pero la intención es no tocar texto que no entendemos).
- *Alternativa descartada — cambiar el rótulo de entrada del prompt:* el modelo copió la etiqueta aun con una instrucción explícita en contra; cualquier otro rótulo puede copiarse igual (corchetes, markdown), no hay forma de probarlo offline y rompería los tests actuales de `prompt_test.ts` por una mejora no verificable. Se deja como posible iteración futura, medida con datos reales.
- *Alternativa descartada — reconstruir el texto desde `sourceBlocks`:* descarta la voz y el orden que produjo el modelo; es un cambio de comportamiento mayor.

**3. Dos capas con propósitos distintos, ambas necesarias.**
La capa del cliente repara los resúmenes que ya están guardados (como el de hoy en prod) y cubre cualquier fallo futuro del servidor; la del servidor evita que el dato malo se persista. Solo con el cliente, el `content` seguiría sucio para cualquier otro consumidor; solo con el servidor, no se repararía lo ya guardado.

**4. Sin migración de datos, sin claves de i18n, sin cambios de layout.**
No hay texto nuevo visible. `SummaryDetailScreen` conserva su estructura (`Scaffold` actual del push de pantalla completa o del panel derecho, sin cambios), por lo que la compatibilidad con el master-detail de iPad y el ancho máximo de lectura no se ven afectados; el razonamiento sobre ≥840dp no cambia porque no se toca el árbol de widgets, solo los strings que reciben título y emparejamiento.

## Risks / Trade-offs

- [El modelo copia otra etiqueta distinta (p. ej. `Fuente -`, `Source de`)] → No cubierta por la lista actual; queda con el comportamiento previo (sin links, título en negrita). Mitigación: Sentry no ve esto (no es una excepción), así que se detecta solo mirando resúmenes en prod; la lista se amplía con una línea en el helper y su test si aparece.
- [Una fuente real se llama `Fuente: algo`] → El emparejamiento exacto va primero en el cliente; el servidor solo quita si el resto es un nombre conocido distinto del original. Riesgo residual despreciable.
- [El cambio del cliente solo llega con un build nuevo] → Los usuarios con un build anterior siguen sin ver links en resúmenes con etiqueta; el del servidor sí corrige a todos los resúmenes que se generen después del despliegue, sin esperar a un build.
- [Dos implementaciones de la misma regla (Dart y TypeScript)] → Mantener la lista de etiquetas igual en ambos y con tests espejo. Se prefiere duplicar una regex de una línea a introducir un contrato compartido entre runtimes.

## Migration Plan

1. Implementar y probar cliente (Flutter) y servidor (Deno) en la rama del change; correr `flutter analyze`, `flutter test` y `deno test --allow-env` en `generate-daily-summaries`.
2. Desplegar la Edge Function `generate-daily-summaries` **solo después de confirmar con el usuario a cuál(es) proyecto(s)** (`reevo` prod linkeado por defecto, `reevo-dev` con `--project-ref xgwnxhpdcrghrtdbrmpn`). Es retrocompatible: si no hay etiqueta, el texto no cambia.
3. El cliente se distribuye con el siguiente build de Codemagic. Si la versión actual de `pubspec.yaml` ya fue aprobada por App Store, el build necesita un bump de versión (ver el error 90062 del build #13); se evalúa al cerrar el change.
4. Rollback: revertir el PR; el servidor deja de limpiar y el cliente vuelve al emparejamiento exacto. Nada que revertir en la base de datos.
