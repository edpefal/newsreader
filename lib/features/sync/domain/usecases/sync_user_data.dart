import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/data/datasources/local/article_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/source_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/summary_local_datasource.dart';
import 'package:newsreader/core/data/models/article_model.dart';
import 'package:newsreader/core/data/models/daily_summary_model.dart';
import 'package:newsreader/core/data/models/news_source_model.dart';
import 'package:newsreader/core/sync/article_state_row.dart';
import 'package:newsreader/core/sync/cloud_sync_client.dart';

/// Sincroniza fuentes, artículos y resúmenes diarios con la nube: sube los
/// cambios locales pendientes y baja los cambios remotos, en una sola
/// pasada por tabla. Sin tiempo real — se dispara al abrir la app.
///
/// A diferencia del resto de los use cases del proyecto, depende
/// directamente de los datasources locales (no de los repositorios de
/// dominio): necesita ver también los registros soft-deleted para
/// propagarlos, algo que los repositorios ocultan a propósito del resto de
/// la app. Ver design.md del change `sync-user-data-to-cloud`.
class SyncUserData {
  static const _sourcesTable = 'sources';
  static const _articlesTable = 'articles';
  static const _summariesTable = 'daily_summaries';

  final SourceLocalDataSource _sourceLocalDataSource;
  final ArticleLocalDataSource _articleLocalDataSource;
  final SummaryLocalDataSource _summaryLocalDataSource;
  final CloudSyncClient _cloudSyncClient;
  final AuthClient _authClient;
  final Box<dynamic> _settingsBox;

  const SyncUserData(
    this._sourceLocalDataSource,
    this._articleLocalDataSource,
    this._summaryLocalDataSource,
    this._cloudSyncClient,
    this._authClient,
    this._settingsBox,
  );

  Future<void> execute() async {
    final userId = _authClient.currentUserId;
    if (userId == null) return;

    final lastSyncedAt = _readCursor();
    var newCursor = lastSyncedAt;

    newCursor = _maxCursor(newCursor, await _syncSources(userId, lastSyncedAt));
    newCursor = _maxCursor(newCursor, await _syncArticles(userId, lastSyncedAt));
    newCursor = _maxCursor(newCursor, await _syncSummaries(userId, lastSyncedAt));

    // El cursor se deriva de los `updated_at` que realmente devolvió el
    // servidor, nunca del reloj del dispositivo (`DateTime.now()`): si el
    // reloj de un dispositivo está adelantado (común en emuladores), un
    // cursor basado en su "ahora" queda por delante de lo que otro
    // dispositivo recién subió con su propio reloj, y ese cambio se
    // descarta para siempre por parecer "más viejo" que el cursor. Si no
    // hubo ninguna fila remota nueva, se deja el cursor sin cambios (es
    // seguro: la próxima sincronización repite la misma consulta).
    if (newCursor != null && newCursor != lastSyncedAt) {
      await _writeCursor(newCursor);
    }
  }

  static DateTime? _maxCursor(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  DateTime? _readCursor() {
    final raw = _settingsBox.get(AppConstants.settingsLastSyncedAtKey) as String?;
    return raw == null ? null : DateTime.parse(raw);
  }

  Future<void> _writeCursor(DateTime value) => _settingsBox.put(
        AppConstants.settingsLastSyncedAtKey,
        value.toIso8601String(),
      );

  /// Convierte a UTC antes de serializar. `DateTime.now()` es hora local
  /// del dispositivo; `toIso8601String()` de un `DateTime` local no incluye
  /// offset/`Z`, así que Postgres lo interpreta como si ya fuera UTC --
  /// en un dispositivo con huso horario distinto a UTC+0 esto corre el
  /// timestamp guardado varias horas hacia el pasado, rompiendo la
  /// comparación `updated_at > cursor` del lado de otro dispositivo.
  static String? _toUtcIso(DateTime? value) => value?.toUtc().toIso8601String();
  static String _toUtcIsoRequired(DateTime value) => value.toUtc().toIso8601String();

  /// Máximo `updated_at` (ya parseado) entre las filas remotas devueltas,
  /// o `null` si la lista está vacía.
  static DateTime? _maxUpdatedAt(List<Map<String, dynamic>> rows) {
    DateTime? max;
    for (final row in rows) {
      final updatedAt = DateTime.parse(row['updated_at'] as String);
      if (max == null || updatedAt.isAfter(max)) max = updatedAt;
    }
    return max;
  }

  // --- Sources ---

  Future<DateTime?> _syncSources(String userId, DateTime? lastSyncedAt) async {
    final local = await _sourceLocalDataSource.getChangedSince(lastSyncedAt);
    if (local.isNotEmpty) {
      await _cloudSyncClient.upsert(
        _sourcesTable,
        local.map((m) => _sourceToRow(m, userId)).toList(),
      );
      for (final model in local.where((m) => m.deletedAt != null)) {
        await _sourceLocalDataSource.purge(model.id);
      }
    }

    final remote =
        await _cloudSyncClient.fetchChangedSince(_sourcesTable, lastSyncedAt);
    for (final row in remote) {
      if (row['deleted_at'] != null) {
        await _sourceLocalDataSource.purge(row['id'] as String);
      } else {
        await _sourceLocalDataSource.applyRemote(_sourceFromRow(row));
      }
    }
    return _maxUpdatedAt(remote);
  }

  Map<String, dynamic> _sourceToRow(NewsSourceModel m, String userId) => {
        'id': m.id,
        'user_id': userId,
        'name': m.name,
        'feed_url': m.feedUrl,
        'author': m.author,
        'icon_url': m.iconUrl,
        'added_at': _toUtcIsoRequired(m.addedAt),
        'last_synced_at': _toUtcIso(m.lastSyncedAt),
        'has_error': m.hasError,
        'updated_at': _toUtcIsoRequired(m.updatedAt ?? DateTime.now()),
        'deleted_at': _toUtcIso(m.deletedAt),
      };

  NewsSourceModel _sourceFromRow(Map<String, dynamic> row) => NewsSourceModel(
        id: row['id'] as String,
        name: row['name'] as String,
        feedUrl: row['feed_url'] as String,
        author: row['author'] as String?,
        iconUrl: row['icon_url'] as String?,
        addedAt: DateTime.parse(row['added_at'] as String),
        lastSyncedAt: (row['last_synced_at'] as String?) != null
            ? DateTime.parse(row['last_synced_at'] as String)
            : null,
        hasError: row['has_error'] as bool? ?? false,
        updatedAt: DateTime.parse(row['updated_at'] as String),
        deletedAt: (row['deleted_at'] as String?) != null
            ? DateTime.parse(row['deleted_at'] as String)
            : null,
      );

  // --- Articles ---

  Future<DateTime?> _syncArticles(String userId, DateTime? lastSyncedAt) async {
    final local = await _articleLocalDataSource.getChangedSince(lastSyncedAt);
    if (local.isNotEmpty) {
      // Solo se sube el estado de usuario (leído/favorito/borrado), nunca el
      // contenido: los artículos nacen en el servidor vía el fetch
      // centralizado de feeds (`sync-feeds`), no se crean desde el cliente.
      // Por eso es un update parcial, no un upsert -- si el `id` todavía no
      // existe en el servidor (artículo no sincronizado hacia este
      // dispositivo todavía), no hay nada que actualizar.
      await _cloudSyncClient.updatePartial(
        _articlesTable,
        local.map(articleStateRow).toList(),
      );
      for (final model in local.where((m) => m.deletedAt != null)) {
        await _articleLocalDataSource.purge(model.id);
      }
    }

    final remote =
        await _cloudSyncClient.fetchChangedSince(_articlesTable, lastSyncedAt);
    for (final row in remote) {
      if (row['deleted_at'] != null) {
        await _articleLocalDataSource.purge(row['id'] as String);
      } else {
        await _articleLocalDataSource.applyRemote(_articleFromRow(row));
      }
    }
    return _maxUpdatedAt(remote);
  }

  ArticleModel _articleFromRow(Map<String, dynamic> row) => ArticleModel(
        id: row['id'] as String,
        sourceId: row['source_id'] as String,
        sourceName: row['source_name'] as String,
        sourceIconUrl: row['source_icon_url'] as String?,
        title: row['title'] as String,
        author: row['author'] as String?,
        publishedAt: DateTime.parse(row['published_at'] as String),
        contentHtml: row['content_html'] as String?,
        excerpt: row['excerpt'] as String?,
        imageUrl: row['image_url'] as String?,
        articleUrl: row['article_url'] as String,
        isRead: row['is_read'] as bool? ?? false,
        isFavorite: row['is_favorite'] as bool? ?? false,
        isArchived: row['is_archived'] as bool? ?? false,
        readAt: (row['read_at'] as String?) != null
            ? DateTime.parse(row['read_at'] as String)
            : null,
        savedAsFavoriteAt: (row['saved_as_favorite_at'] as String?) != null
            ? DateTime.parse(row['saved_as_favorite_at'] as String)
            : null,
        updatedAt: DateTime.parse(row['updated_at'] as String),
        deletedAt: (row['deleted_at'] as String?) != null
            ? DateTime.parse(row['deleted_at'] as String)
            : null,
      );

  // --- Daily summaries ---

  Future<DateTime?> _syncSummaries(String userId, DateTime? lastSyncedAt) async {
    final local = await _summaryLocalDataSource.getChangedSince(lastSyncedAt);
    if (local.isNotEmpty) {
      await _cloudSyncClient.upsert(
        _summariesTable,
        local.map((m) => _summaryToRow(m, userId)).toList(),
      );
    }

    final remote = await _cloudSyncClient.fetchChangedSince(
      _summariesTable,
      lastSyncedAt,
    );
    for (final row in remote) {
      await _summaryLocalDataSource.applyRemote(_summaryFromRow(row));
    }
    return _maxUpdatedAt(remote);
  }

  Map<String, dynamic> _summaryToRow(DailySummaryModel m, String userId) => {
        'id': m.id,
        'user_id': userId,
        'date': _toUtcIsoRequired(m.date),
        'content': m.content,
        'article_count': m.articleCount,
        'created_at': _toUtcIsoRequired(m.createdAt),
        'updated_at': _toUtcIsoRequired(m.updatedAt ?? DateTime.now()),
      };

  DailySummaryModel _summaryFromRow(Map<String, dynamic> row) =>
      DailySummaryModel(
        id: row['id'] as String,
        date: DateTime.parse(row['date'] as String),
        content: row['content'] as String,
        articleCount: row['article_count'] as int,
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );
}
