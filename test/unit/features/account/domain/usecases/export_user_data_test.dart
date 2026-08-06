import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/sharing/file_sharer.dart';
import 'package:newsreader/features/account/domain/usecases/export_favorites_json.dart';
import 'package:newsreader/features/account/domain/usecases/export_sources_opml.dart';
import 'package:newsreader/features/account/domain/usecases/export_user_data.dart';

class MockExportSourcesOpml extends Mock implements ExportSourcesOpml {}

class MockExportFavoritesJson extends Mock implements ExportFavoritesJson {}

class MockFileSharer extends Mock implements FileSharer {}

void main() {
  late MockExportSourcesOpml mockExportSourcesOpml;
  late MockExportFavoritesJson mockExportFavoritesJson;
  late MockFileSharer mockFileSharer;

  ExportUserData buildUseCase() => ExportUserData(
        mockExportSourcesOpml,
        mockExportFavoritesJson,
        mockFileSharer,
      );

  setUp(() {
    mockExportSourcesOpml = MockExportSourcesOpml();
    mockExportFavoritesJson = MockExportFavoritesJson();
    mockFileSharer = MockFileSharer();
    registerFallbackValue(const <SharableFile>[]);
  });

  group('ExportUserData', () {
    test('comparte el OPML de fuentes y el JSON de favoritos generados',
        () async {
      when(() => mockExportSourcesOpml.execute())
          .thenAnswer((_) async => '<opml></opml>');
      when(() => mockExportFavoritesJson.execute())
          .thenAnswer((_) async => '[]');
      when(() => mockFileSharer.shareFiles(any())).thenAnswer((_) async {});

      await buildUseCase().execute();

      final captured =
          verify(() => mockFileSharer.shareFiles(captureAny())).captured;
      final files = captured.single as List<SharableFile>;

      expect(files, hasLength(2));
      expect(files[0].name, 'fuentes-reevo.opml');
      expect(files[0].content, '<opml></opml>');
      expect(files[0].mimeType, 'text/x-opml');
      expect(files[1].name, 'favoritos-reevo.json');
      expect(files[1].content, '[]');
      expect(files[1].mimeType, 'application/json');
    });
  });
}
