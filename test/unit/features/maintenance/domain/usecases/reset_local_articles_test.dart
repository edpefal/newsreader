import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/data/datasources/local/article_local_datasource.dart';
import 'package:newsreader/features/maintenance/domain/usecases/reset_local_articles.dart';

class MockArticleLocalDataSource extends Mock implements ArticleLocalDataSource {}

class MockSettingsBox extends Mock implements Box<dynamic> {}

void main() {
  late MockArticleLocalDataSource mockArticleLocal;
  late MockSettingsBox mockSettingsBox;
  late ResetLocalArticles sut;

  setUp(() {
    mockArticleLocal = MockArticleLocalDataSource();
    mockSettingsBox = MockSettingsBox();
    sut = ResetLocalArticles(mockArticleLocal, mockSettingsBox);

    when(() => mockArticleLocal.clearAll()).thenAnswer((_) async {});
    when(() => mockSettingsBox.delete(any())).thenAnswer((_) async {});
    when(() => mockSettingsBox.put(any(), any())).thenAnswer((_) async {});
  });

  test('primera vez: limpia artículos, resetea el cursor de sync y marca la migración', () async {
    when(() => mockSettingsBox.get(AppConstants.settingsArticlesResetV3Key))
        .thenReturn(null);

    await sut.execute();

    verify(() => mockArticleLocal.clearAll()).called(1);
    verify(
      () => mockSettingsBox.delete(AppConstants.settingsLastSyncedAtKey),
    ).called(1);
    verify(
      () => mockSettingsBox.put(AppConstants.settingsArticlesResetV3Key, true),
    ).called(1);
  });

  test('no hace nada si ya corrió antes en este dispositivo', () async {
    when(() => mockSettingsBox.get(AppConstants.settingsArticlesResetV3Key))
        .thenReturn(true);

    await sut.execute();

    verifyNever(() => mockArticleLocal.clearAll());
    verifyNever(() => mockSettingsBox.delete(any()));
  });
}
