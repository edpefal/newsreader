## 1. Cliente: normalizar el título del bloque (Flutter)

- [x] 1.1 Crear el helper puro `lib/features/summaries/domain/summary_block_title.dart` con la normalización: quitar un prefijo `^\s*(fuente|source)\s*:\s*` sin distinguir mayúsculas, devolver el resto sin espacios sobrantes, y devolver el título original si el resto quedaría vacío. Sin importar nada de infraestructura.
- [x] 1.2 Test unitario del helper (`test/unit/features/summaries/domain/`): `Fuente: TechCrunch`, `fuente: TechCrunch`, `Source: Stratechery`, `Source : Stratechery`, `TechCrunch` (sin etiqueta, igual), `Reuters: World News` (no empieza con la etiqueta, igual), `Fuente:` solo (queda el original), y espacios alrededor.
- [x] 1.3 En `summary_detail_screen.dart`, hacer que `_matchingSourceBlock` intente primero la igualdad exacta con el título crudo y, si no empareja, reintente con el título normalizado (ver design, Decisión 1).
- [x] 1.4 En `_SummaryBlockView`, mostrar en negrita el título normalizado en vez del crudo, sin tocar el árbol de widgets ni el layout.
- [x] 1.5 Test de widget en `test/widget/features/summaries/summary_detail_screen_test.dart`: un `DailySummary` con `content` que empieza `Fuente: TechCrunch` y `sourceBlocks` con `TechCrunch` y 2 artículos resueltos muestra `TechCrunch` en negrita (sin la etiqueta) y un link por cada artículo; y un caso en el que el bloque con etiqueta no emparejado con ninguna fuente igual muestra el título normalizado sin links.
- [x] 1.6 Verificar que no se rompen los escenarios que ya existían en ese archivo de tests (título en negrita, link directo con 1 artículo, varios links, sin agrupación, artículo ya no existe).

## 2. Servidor: limpiar la etiqueta antes de persistir (Edge Function)

- [x] 2.1 Crear `supabase/functions/generate-daily-summaries/strip_source_label.ts` con la función pura descrita en design (Decisión 2): recibe el texto del modelo y la lista de nombres de fuente conocidos, divide en bloques por línea en blanco, y reescribe la primera línea de un bloque de `<etiqueta> <nombre>` a `<nombre>` solo si `<nombre>` es exactamente una de las fuentes conocidas; no toca nada más y reconstruye el texto con la misma separación.
- [x] 2.2 Tests de Deno `strip_source_label_test.ts`: etiqueta quitada cuando el resto es una fuente conocida, texto sin etiqueta sin cambios, `Fuente: desconocida` sin cambios, la palabra "Fuente:" en una línea interna del párrafo sin cambios, varios bloques mezclando bloques con y sin etiqueta, y la regla de etiquetas en es/en/fr (`Fuente:`, `Source:`, `Source :`).
- [x] 2.3 En `generate-daily-summaries/index.ts`, llamar a esa función justo antes de guardar con los nombres de `sourceBlocks` y guardar el resultado en `content` (en lugar de `summaryText.trim()` crudo), sin cambiar el prompt ni la solicitud a Gemini.
- [x] 2.4 Correr `(cd supabase/functions/generate-daily-summaries && deno test --allow-env)` y confirmar que pasa todo, incluidos los tests existentes (`prompt_test.ts` no debe cambiar).

## 3. Verificación

- [x] 3.1 Correr `flutter analyze` y dejarlo sin warnings.
- [x] 3.2 Correr `flutter test` completo en verde.
- [x] 3.3 Razonar (sin lanzar el simulador, ver CLAUDE.md) que el cambio no toca el árbol de widgets de `SummaryDetailScreen` y por tanto no afecta el master-detail de iPad ≥840dp ni el ancho máximo de lectura; dejarlo anotado al cerrar el change.
- [x] 3.4 Confirmar que no se agregó ningún texto visible al usuario, así que no hay claves nuevas en los `.arb`.
- [x] 3.5 Revisar a mano que ningún texto en español nuevo (comentarios de código no cuentan, sí cualquier string de usuario o prompt) use voseo.

## 4. Despliegue y cierre

- [x] 4.1 Confirmar con el usuario a cuál(es) proyecto(s) de Supabase desplegar `generate-daily-summaries` (`reevo` prod / `reevo-dev` con `--project-ref xgwnxhpdcrghrtdbrmpn` / ambos) antes de dar el change por terminado (ver CLAUDE.md); no asumir que solo uno basta. (Confirmado: ambos.)
- [x] 4.2 Desplegar la Edge Function al/los proyecto(s) confirmado(s) y anotar cuál(es) quedaron actualizados. (Desplegada a `reevo` prod el 2026-10-03 13:55 UTC y a `reevo-dev`, ambas en la versión 2. Nota: `config.toml` no declara `verify_jwt` para esta función, así que el CLI la dejó en `verify_jwt: true`; la v1 de dev estaba en `false`. El cron la invoca con la clave `service_role` de Vault, un JWT válido, igual que `sync-feeds`, que ya corre con `verify_jwt: true`. Se verifica con la corrida del cron de las 14:00 UTC, ver 4.3.)
- [x] 4.3 Verificar tras el despliegue en el/los proyecto(s) elegido(s), con el siguiente resumen diario que se genere, que el `content` guardado empieza cada bloque con el nombre de la fuente sin etiqueta (consulta a `daily_summaries`), o dejar documentado que aún no se generó uno. (Todavía no se generó un resumen nuevo: el de hoy ya existía, así que la limpieza del `content` se confirma con el de mañana. Sí se verificó que la v2 responde bien en ambos proyectos: la corrida del cron de las 14:00 UTC devolvió 200 con `{"evaluated":1,"generated":0}` en prod y en dev.)
- [x] 4.4 Evaluar con el usuario si el cliente necesita un bump de versión en `pubspec.yaml` para el siguiente build de Codemagic (si la versión actual ya fue aprobada por Apple, el publish falla con 90062); si hace falta, hacerlo como commit `chore` en el mismo PR o aparte según prefiera el usuario. (No hace falta: el usuario confirmó que 1.9.0 aún no sale en la App Store, así que el siguiente build de Codemagic con `1.9.0` no choca con el error 90062.)
- [ ] 4.5 Abrir PR contra `main`, esperar el check `analyze-and-test` en verde, mergear, volver a `main`, actualizarla y borrar la rama (local y remota); cerrar `tasks.md` y archivar el change en el mismo PR final (`/opsx:archive`).
