import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/data/datasources/local/article_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/source_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/summary_local_datasource.dart';
import 'package:newsreader/features/sync/domain/usecases/clear_local_user_data.dart';

class MockSourceLocalDataSource extends Mock implements SourceLocalDataSource {}

class MockArticleLocalDataSource extends Mock implements ArticleLocalDataSource {}

class MockSummaryLocalDataSource extends Mock implements SummaryLocalDataSource {}

class MockSettingsBox extends Mock implements Box<dynamic> {}

void main() {
  late MockSourceLocalDataSource mockSourceLocal;
  late MockArticleLocalDataSource mockArticleLocal;
  late MockSummaryLocalDataSource mockSummaryLocal;
  late MockSettingsBox mockSettingsBox;
  late ClearLocalUserData sut;

  setUp(() {
    mockSourceLocal = MockSourceLocalDataSource();
    mockArticleLocal = MockArticleLocalDataSource();
    mockSummaryLocal = MockSummaryLocalDataSource();
    mockSettingsBox = MockSettingsBox();
    sut = ClearLocalUserData(
      mockSourceLocal,
      mockArticleLocal,
      mockSummaryLocal,
      mockSettingsBox,
    );

    when(() => mockSourceLocal.clearAll()).thenAnswer((_) async {});
    when(() => mockArticleLocal.clearAll()).thenAnswer((_) async {});
    when(() => mockSummaryLocal.clearAll()).thenAnswer((_) async {});
    when(() => mockSettingsBox.delete(any())).thenAnswer((_) async {});
  });

  test('borra las 3 boxes locales y el cursor de sincronización', () async {
    await sut.execute();

    verify(() => mockSourceLocal.clearAll()).called(1);
    verify(() => mockArticleLocal.clearAll()).called(1);
    verify(() => mockSummaryLocal.clearAll()).called(1);
    verify(
      () => mockSettingsBox.delete(AppConstants.settingsLastSyncedAtKey),
    ).called(1);
  });
}
