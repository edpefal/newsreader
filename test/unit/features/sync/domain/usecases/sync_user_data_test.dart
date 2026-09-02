import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/data/datasources/local/ai_usage_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/article_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/source_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/summary_local_datasource.dart';
import 'package:newsreader/core/data/models/ai_usage_daily_model.dart';
import 'package:newsreader/core/data/models/article_model.dart';
import 'package:newsreader/core/data/models/daily_summary_model.dart';
import 'package:newsreader/core/data/models/news_source_model.dart';
import 'package:newsreader/core/sync/cloud_sync_client.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';

class MockSourceLocalDataSource extends Mock implements SourceLocalDataSource {}

class MockArticleLocalDataSource extends Mock implements ArticleLocalDataSource {}

class MockSummaryLocalDataSource extends Mock implements SummaryLocalDataSource {}

class MockAiUsageLocalDataSource extends Mock
    implements AiUsageLocalDataSource {}

class MockCloudSyncClient extends Mock implements CloudSyncClient {}

class MockAuthClient extends Mock implements AuthClient {}

class MockSettingsBox extends Mock implements Box<dynamic> {}

NewsSourceModel _source({
  required String id,
  DateTime? updatedAt,
  DateTime? deletedAt,
}) =>
    NewsSourceModel(
      id: id,
      name: 'Source $id',
      feedUrl: 'https://example.com/$id/feed',
      addedAt: DateTime(2026),
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );

ArticleModel _article({required String id, DateTime? updatedAt}) => ArticleModel(
      id: id,
      sourceId: 's1',
      sourceName: 'Source',
      title: 'Title $id',
      articleUrl: 'https://example.com/$id',
      publishedAt: DateTime(2026),
      updatedAt: updatedAt,
    );

void main() {
  late MockSourceLocalDataSource mockSourceLocal;
  late MockArticleLocalDataSource mockArticleLocal;
  late MockSummaryLocalDataSource mockSummaryLocal;
  late MockAiUsageLocalDataSource mockAiUsageLocal;
  late MockCloudSyncClient mockCloudSyncClient;
  late MockAuthClient mockAuthClient;
  late MockSettingsBox mockSettingsBox;
  late SyncUserData sut;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<Map<String, dynamic>>[]);
    registerFallbackValue('sources');
    registerFallbackValue(_source(id: 'fallback'));
    registerFallbackValue(_article(id: 'fallback'));
    registerFallbackValue(
      DailySummaryModel(
        id: 'fallback',
        date: DateTime(2026),
        content: '',
        articleCount: 0,
        createdAt: DateTime(2026),
      ),
    );
    registerFallbackValue(
      AiUsageDailyModel(day: DateTime(2026), summariesUsed: 0),
    );
  });

  setUp(() {
    mockSourceLocal = MockSourceLocalDataSource();
    mockArticleLocal = MockArticleLocalDataSource();
    mockSummaryLocal = MockSummaryLocalDataSource();
    mockAiUsageLocal = MockAiUsageLocalDataSource();
    mockCloudSyncClient = MockCloudSyncClient();
    mockAuthClient = MockAuthClient();
    mockSettingsBox = MockSettingsBox();
    sut = SyncUserData(
      mockSourceLocal,
      mockArticleLocal,
      mockSummaryLocal,
      mockAiUsageLocal,
      mockCloudSyncClient,
      mockAuthClient,
      mockSettingsBox,
    );

    when(() => mockAuthClient.currentUserId).thenReturn('user-1');
    when(() => mockSettingsBox.put(any(), any())).thenAnswer((_) async {});
    when(() => mockSourceLocal.purge(any())).thenAnswer((_) async {});
    when(() => mockArticleLocal.purge(any())).thenAnswer((_) async {});
    when(() => mockSourceLocal.applyRemote(any())).thenAnswer((_) async {});
    when(() => mockArticleLocal.applyRemote(any())).thenAnswer((_) async {});
    when(() => mockSummaryLocal.applyRemote(any())).thenAnswer((_) async {});
    when(() => mockAiUsageLocal.applyRemote(any())).thenAnswer((_) async {});
    when(() => mockCloudSyncClient.updatePartial(any(), any()))
        .thenAnswer((_) async {});
    // Stub por defecto para la tabla nueva de solo lectura: la mayoría de
    // los tests no le interesa `ai_usage_daily`, solo evitar un
    // MissingStubError -- los tests que sí necesitan otro comportamiento
    // pueden seguir registrando su propio `when` más específico.
    when(() => mockCloudSyncClient.fetchChangedSince('ai_usage_daily', any()))
        .thenAnswer((_) async => []);
  });

  group('sin sesión activa', () {
    test('no hace nada si no hay usuario logueado', () async {
      when(() => mockAuthClient.currentUserId).thenReturn(null);

      await sut.execute();

      verifyNever(() => mockSourceLocal.getChangedSince(any()));
      verifyNever(() => mockCloudSyncClient.upsert(any(), any()));
    });
  });

  group('primera sincronización (cursor null)', () {
    test('sube todos los registros locales, sin filtrar por fecha', () async {
      when(() => mockSettingsBox.get(AppConstants.settingsLastSyncedAtKey))
          .thenReturn(null);
      when(() => mockSourceLocal.getChangedSince(null))
          .thenAnswer((_) async => [_source(id: 's1'), _source(id: 's2')]);
      when(() => mockArticleLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockSummaryLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.upsert(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockCloudSyncClient.fetchChangedSince(any(), null))
          .thenAnswer((_) async => []);

      await sut.execute();

      final captured = verify(
        () => mockCloudSyncClient.upsert('sources', captureAny()),
      ).captured.single as List<Map<String, dynamic>>;
      expect(captured.map((r) => r['id']), ['s1', 's2']);
    });
  });

  group('sincronización incremental', () {
    test('solo consulta lo cambiado desde el cursor guardado', () async {
      final cursor = DateTime(2026, 1, 1);
      when(() => mockSettingsBox.get(AppConstants.settingsLastSyncedAtKey))
          .thenReturn(cursor.toIso8601String());
      when(() => mockSourceLocal.getChangedSince(cursor))
          .thenAnswer((_) async => []);
      when(() => mockArticleLocal.getChangedSince(cursor))
          .thenAnswer((_) async => []);
      when(() => mockSummaryLocal.getChangedSince(cursor))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince(any(), cursor))
          .thenAnswer((_) async => []);

      await sut.execute();

      verify(() => mockSourceLocal.getChangedSince(cursor)).called(1);
      verify(() => mockArticleLocal.getChangedSince(cursor)).called(1);
      verify(() => mockSummaryLocal.getChangedSince(cursor)).called(1);
      verifyNever(() => mockCloudSyncClient.upsert(any(), any()));
    });

    test('actualiza el cursor al finalizar, con el updated_at más reciente devuelto por el servidor', () async {
      when(() => mockSettingsBox.get(AppConstants.settingsLastSyncedAtKey))
          .thenReturn(null);
      when(() => mockSourceLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockArticleLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockSummaryLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('sources', null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('daily_summaries', null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('articles', null))
          .thenAnswer((_) async => [
                {
                  'id': 'a1',
                  'source_id': 's1',
                  'source_name': 'Source',
                  'title': 'Título',
                  'published_at': DateTime(2026).toIso8601String(),
                  'article_url': 'https://example.com/a1',
                  'is_read': false,
                  'is_favorite': false,
                  'is_archived': false,
                  'updated_at': DateTime(2026, 1, 5).toIso8601String(),
                },
              ]);

      await sut.execute();

      verify(
        () => mockSettingsBox.put(
          AppConstants.settingsLastSyncedAtKey,
          DateTime(2026, 1, 5).toIso8601String(),
        ),
      ).called(1);
    });

    test('no toca el cursor si no hay ninguna fila remota nueva (no depende del reloj local)', () async {
      when(() => mockSettingsBox.get(AppConstants.settingsLastSyncedAtKey))
          .thenReturn(null);
      when(() => mockSourceLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockArticleLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockSummaryLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince(any(), null))
          .thenAnswer((_) async => []);

      await sut.execute();

      verifyNever(
        () => mockSettingsBox.put(AppConstants.settingsLastSyncedAtKey, any()),
      );
    });
  });

  group('soft-delete remoto', () {
    test('un tombstone remoto se aplica como borrado físico local', () async {
      when(() => mockSettingsBox.get(AppConstants.settingsLastSyncedAtKey))
          .thenReturn(null);
      when(() => mockSourceLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockArticleLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockSummaryLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('sources', null))
          .thenAnswer((_) async => [
                {
                  'id': 's1',
                  'name': 'Source',
                  'feed_url': 'https://example.com/feed',
                  'added_at': DateTime(2026).toIso8601String(),
                  'has_error': false,
                  'updated_at': DateTime(2026, 1, 2).toIso8601String(),
                  'deleted_at': DateTime(2026, 1, 2).toIso8601String(),
                },
              ]);
      when(() => mockCloudSyncClient.fetchChangedSince('articles', null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('daily_summaries', null))
          .thenAnswer((_) async => []);

      await sut.execute();

      verify(() => mockSourceLocal.purge('s1')).called(1);
      verifyNever(() => mockSourceLocal.applyRemote(any()));
    });

    test('un tombstone local recién subido se purga localmente', () async {
      when(() => mockSettingsBox.get(AppConstants.settingsLastSyncedAtKey))
          .thenReturn(null);
      when(() => mockSourceLocal.getChangedSince(null)).thenAnswer(
        (_) async => [_source(id: 's1', deletedAt: DateTime(2026, 1, 2))],
      );
      when(() => mockArticleLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockSummaryLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.upsert(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockCloudSyncClient.fetchChangedSince(any(), null))
          .thenAnswer((_) async => []);

      await sut.execute();

      verify(() => mockSourceLocal.purge('s1')).called(1);
    });
  });

  group('push de artículos', () {
    test('solo sube el estado de usuario, nunca el contenido', () async {
      when(() => mockSettingsBox.get(AppConstants.settingsLastSyncedAtKey))
          .thenReturn(null);
      when(() => mockSourceLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockArticleLocal.getChangedSince(null)).thenAnswer(
        (_) async => [
          _article(id: 'a1', updatedAt: DateTime(2026, 1, 1))
            ..isRead = true
            ..readAt = DateTime(2026, 1, 1, 10),
        ],
      );
      when(() => mockSummaryLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince(any(), null))
          .thenAnswer((_) async => []);

      await sut.execute();

      final captured = verify(
        () => mockCloudSyncClient.updatePartial('articles', captureAny()),
      ).captured.single as List<Map<String, dynamic>>;
      expect(captured.single['id'], 'a1');
      expect(captured.single['is_read'], true);
      expect(captured.single.containsKey('title'), isFalse);
      expect(captured.single.containsKey('content_html'), isFalse);
      expect(captured.single.containsKey('source_id'), isFalse);
      verifyNever(() => mockCloudSyncClient.upsert('articles', any()));
    });

    test('serializa los timestamps en UTC, sin importar el huso horario local', () async {
      // DateTime(...) sin `.toUtc()` construye una hora LOCAL: si se
      // serializa tal cual (sin convertir a UTC), Postgres la interpreta
      // como si ya fuera UTC y el timestamp queda corrido -- ver bug
      // encontrado probando con la app real (tasks.md, sección 9).
      when(() => mockSettingsBox.get(AppConstants.settingsLastSyncedAtKey))
          .thenReturn(null);
      when(() => mockSourceLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockArticleLocal.getChangedSince(null)).thenAnswer(
        (_) async => [
          _article(id: 'a1', updatedAt: DateTime(2026, 1, 1, 10))
            ..isRead = true
            ..readAt = DateTime(2026, 1, 1, 10),
        ],
      );
      when(() => mockSummaryLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince(any(), null))
          .thenAnswer((_) async => []);

      await sut.execute();

      final captured = verify(
        () => mockCloudSyncClient.updatePartial('articles', captureAny()),
      ).captured.single as List<Map<String, dynamic>>;
      expect(captured.single['updated_at'], endsWith('Z'));
      expect(captured.single['read_at'], endsWith('Z'));
    });
  });

  group('last-write-wins', () {
    test('un artículo remoto más reciente sobreescribe el local vía pull', () async {
      when(() => mockSettingsBox.get(AppConstants.settingsLastSyncedAtKey))
          .thenReturn(null);
      when(() => mockSourceLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockArticleLocal.getChangedSince(null)).thenAnswer(
        (_) async => [_article(id: 'a1', updatedAt: DateTime(2026, 1, 1))],
      );
      when(() => mockSummaryLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.upsert(any(), any()))
          .thenAnswer((_) async {});
      when(() => mockCloudSyncClient.fetchChangedSince('sources', null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('daily_summaries', null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('articles', null))
          .thenAnswer((_) async => [
                {
                  'id': 'a1',
                  'source_id': 's1',
                  'source_name': 'Source',
                  'title': 'Título editado en otro dispositivo',
                  'published_at': DateTime(2026).toIso8601String(),
                  'article_url': 'https://example.com/a1',
                  'is_read': true,
                  'is_favorite': false,
                  'is_archived': false,
                  // más reciente que el local (2026-01-01)
                  'updated_at': DateTime(2026, 1, 3).toIso8601String(),
                },
              ]);

      await sut.execute();

      final applied = verify(() => mockArticleLocal.applyRemote(captureAny()))
          .captured
          .single as ArticleModel;
      expect(applied.title, 'Título editado en otro dispositivo');
      expect(applied.isRead, true);
    });
  });

  group('ai_usage_daily (solo lectura)', () {
    test('aplica localmente lo que devuelve el servidor, sin subir nada',
        () async {
      when(() => mockSettingsBox.get(AppConstants.settingsLastSyncedAtKey))
          .thenReturn(null);
      when(() => mockSourceLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockArticleLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockSummaryLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('sources', null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('articles', null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('daily_summaries', null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('ai_usage_daily', null))
          .thenAnswer((_) async => [
                {
                  'day': DateTime(2026, 1, 5).toIso8601String(),
                  'summaries_used': 7,
                  'updated_at': DateTime(2026, 1, 5, 10).toIso8601String(),
                },
              ]);

      await sut.execute();

      final applied = verify(() => mockAiUsageLocal.applyRemote(captureAny()))
          .captured
          .single as AiUsageDailyModel;
      expect(applied.summariesUsed, 7);
      verifyNever(() => mockCloudSyncClient.upsert('ai_usage_daily', any()));
      verifyNever(
        () => mockCloudSyncClient.updatePartial('ai_usage_daily', any()),
      );
    });
  });

  group('imagen del artículo', () {
    test('mapea image_url de la fila remota al modelo local', () async {
      when(() => mockSettingsBox.get(AppConstants.settingsLastSyncedAtKey))
          .thenReturn(null);
      when(() => mockSourceLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockArticleLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockSummaryLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('sources', null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('daily_summaries', null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('articles', null))
          .thenAnswer((_) async => [
                {
                  'id': 'a1',
                  'source_id': 's1',
                  'source_name': 'Source',
                  'title': 'Título',
                  'published_at': DateTime(2026).toIso8601String(),
                  'article_url': 'https://example.com/a1',
                  'image_url': 'https://example.com/a1/image.jpg',
                  'is_read': false,
                  'is_favorite': false,
                  'is_archived': false,
                  'updated_at': DateTime(2026, 1, 5).toIso8601String(),
                },
              ]);

      await sut.execute();

      final applied = verify(() => mockArticleLocal.applyRemote(captureAny()))
          .captured
          .single as ArticleModel;
      expect(applied.imageUrl, 'https://example.com/a1/image.jpg');
    });

    test('image_url ausente en la fila remota se mapea como null', () async {
      when(() => mockSettingsBox.get(AppConstants.settingsLastSyncedAtKey))
          .thenReturn(null);
      when(() => mockSourceLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockArticleLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockSummaryLocal.getChangedSince(null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('sources', null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('daily_summaries', null))
          .thenAnswer((_) async => []);
      when(() => mockCloudSyncClient.fetchChangedSince('articles', null))
          .thenAnswer((_) async => [
                {
                  'id': 'a1',
                  'source_id': 's1',
                  'source_name': 'Source',
                  'title': 'Título',
                  'published_at': DateTime(2026).toIso8601String(),
                  'article_url': 'https://example.com/a1',
                  'is_read': false,
                  'is_favorite': false,
                  'is_archived': false,
                  'updated_at': DateTime(2026, 1, 5).toIso8601String(),
                },
              ]);

      await sut.execute();

      final applied = verify(() => mockArticleLocal.applyRemote(captureAny()))
          .captured
          .single as ArticleModel;
      expect(applied.imageUrl, isNull);
    });
  });
}
