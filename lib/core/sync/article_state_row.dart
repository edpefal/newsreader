import 'package:newsreader/core/data/models/article_model.dart';

/// Fila con únicamente el estado de usuario sobre un artículo -- nunca su
/// contenido (título, HTML, extracto, etc.), que solo el servidor escribe.
/// Compartido entre `SyncUserData` (sync por batch) y `MarkArticleAsRead`
/// (push inmediato al marcar leído), para que ambos conozcan las mismas
/// columnas de la tabla `articles` en un solo lugar.
Map<String, dynamic> articleStateRow(ArticleModel m) => {
      'id': m.id,
      'is_read': m.isRead,
      'is_favorite': m.isFavorite,
      'is_archived': m.isArchived,
      'read_at': _toUtcIso(m.readAt),
      'saved_as_favorite_at': _toUtcIso(m.savedAsFavoriteAt),
      'updated_at': _toUtcIsoRequired(m.updatedAt ?? DateTime.now()),
      'deleted_at': _toUtcIso(m.deletedAt),
    };

/// Convierte a UTC antes de serializar. `DateTime.now()` es hora local del
/// dispositivo; `toIso8601String()` de un `DateTime` local no incluye
/// offset/`Z`, así que Postgres lo interpreta como si ya fuera UTC -- en un
/// dispositivo con huso horario distinto a UTC+0 esto corre el timestamp
/// guardado varias horas hacia el pasado, rompiendo la comparación
/// `updated_at > cursor` del lado de otro dispositivo.
String? _toUtcIso(DateTime? value) => value?.toUtc().toIso8601String();
String _toUtcIsoRequired(DateTime value) => value.toUtc().toIso8601String();
