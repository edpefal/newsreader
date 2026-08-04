## 1. Base de datos

- [x] 1.1 Crear migration en `supabase/migrations` que agrega la columna `image_url text null` a la tabla `articles`.

## 2. Servidor (`sync-feeds`)

- [x] 2.1 Declarar `customFields` adicionales en el `Parser` de `rss-parser` para exponer Media RSS (`media:content`, `media:thumbnail`) del ítem.
- [x] 2.2 Implementar función de extracción de imagen que prueba, en orden, Media RSS → `enclosure` (tipo `image/*`) → `itunes.image` → primer `<img src="...">` del HTML del contenido, devolviendo `null` si ninguna produce una URL válida.
- [x] 2.3 Usar esa función al construir cada fila de artículo en `syncSource`, poblando `image_url`.
- [x] 2.4 Confirmar que la ausencia de imagen no afecta el resultado `ok`/fallido de la fuente (sigue el mismo try/catch existente).
- [ ] 2.5 Agregar/actualizar tests del edge function (si existen) cubriendo cada rama del fallback y el caso sin imagen. — No aplica: no hay infraestructura de tests para edge functions en este repo (sin `.test.ts`, sin test runner configurado).

## 3. Cliente — capa de datos

- [x] 3.1 Agregar campo `imageUrl` (nullable) a `Article` (`core/domain/entities/article.dart`), incluido en `props` y no en `copyWith` (mismo tratamiento que `contentHtml`/`excerpt`: no es estado mutable por el usuario).
- [x] 3.2 Agregar `@HiveField(17) String? imageUrl` a `ArticleModel` (`core/data/models/article_model.dart`), y actualizar `fromEntity`/`toEntity`.
- [x] 3.3 Regenerar `article_model.g.dart` con `dart run build_runner build --delete-conflicting-outputs`.
- [x] 3.4 Mapear `image_url` en `_articleFromRow` de `features/sync/domain/usecases/sync_user_data.dart`.

## 4. Cliente — UI

- [x] 4.1 Actualizar `ArticleInboxTile` (`features/inbox/presentation/widgets/article_inbox_tile.dart`) para mostrar un thumbnail cuadrado como `trailing` del `ListTile` cuando `article.imageUrl != null`, usando `CachedNetworkImageWidget` (mismo patrón que `SourceIcon`).
- [x] 4.2 Confirmar que cuando `imageUrl` es `null` el `trailing` se omite (no se reserva espacio ni se muestra placeholder).

## 5. Verificación

- [x] 5.1 `flutter analyze` sin warnings nuevos.
- [x] 5.2 `flutter test` (unit + widget) incluyendo casos nuevos/actualizados para `Article`, `ArticleModel`, `sync_user_data.dart` y `ArticleInboxTile`.
- [ ] 5.3 Probar manualmente: pull-to-refresh con al menos una fuente que traiga imagen por cada rama del fallback (Media RSS, enclosure, iTunes, `<img>` embebido) y una fuente sin ninguna, verificando que el Inbox se ve correcto en ambos casos. — Requiere deploy de la migration + edge function a Supabase y probar en la app corriendo; no lo puedo hacer desde acá.
