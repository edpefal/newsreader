import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/features/sources/domain/usecases/import_opml.dart';
import 'package:newsreader/features/sources/presentation/cubit/import_opml_cubit.dart';

class MockImportOpml extends Mock implements ImportOpml {}

final _tSource = NewsSource(
  id: 'id-1',
  name: 'Feed A',
  feedUrl: 'https://a.com/feed',
  addedAt: DateTime(2024),
);

void main() {
  late MockImportOpml mockImportOpml;

  setUp(() {
    mockImportOpml = MockImportOpml();
  });

  ImportOpmlCubit buildCubit() => ImportOpmlCubit(mockImportOpml);

  group('loadPreview', () {
    blocTest<ImportOpmlCubit, ImportOpmlState>(
      'emite Validating → Preview intermedio → Preview final con pendingCount 0',
      build: buildCubit,
      setUp: () {
        when(() => mockImportOpml.parseUrls(any()))
            .thenReturn(['https://a.com/feed']);
        when(() => mockImportOpml.validateFeeds(
              any(),
              onResult: any(named: 'onResult'),
            )).thenAnswer((invocation) async {
          final onResult = invocation.namedArguments[const Symbol('onResult')]
              as void Function(OpmlFeedValidation);
          onResult(OpmlFeedValidation(
            url: 'https://a.com/feed',
            name: 'Feed A',
            status: OpmlFeedValidationStatus.valid,
          ));
        });
      },
      act: (cubit) => cubit.loadPreview('<opml/>'),
      expect: () => [
        const ImportOpmlValidating(),
        isA<ImportOpmlPreview>()
            .having((s) => s.feeds.length, 'feeds count', 1)
            .having((s) => s.pendingCount, 'pendingCount', 0),
      ],
    );

    blocTest<ImportOpmlCubit, ImportOpmlState>(
      'emite estados intermedios con pendingCount decreciente',
      build: buildCubit,
      setUp: () {
        when(() => mockImportOpml.parseUrls(any()))
            .thenReturn(['https://a.com/feed', 'https://b.com/feed']);
        when(() => mockImportOpml.validateFeeds(
              any(),
              onResult: any(named: 'onResult'),
            )).thenAnswer((invocation) async {
          final onResult = invocation.namedArguments[const Symbol('onResult')]
              as void Function(OpmlFeedValidation);
          onResult(OpmlFeedValidation(
            url: 'https://a.com/feed',
            name: 'Feed A',
            status: OpmlFeedValidationStatus.valid,
          ));
          onResult(OpmlFeedValidation(
            url: 'https://b.com/feed',
            name: 'Feed B',
            status: OpmlFeedValidationStatus.duplicate,
          ));
        });
      },
      act: (cubit) => cubit.loadPreview('<opml/>'),
      expect: () => [
        const ImportOpmlValidating(),
        isA<ImportOpmlPreview>()
            .having((s) => s.feeds.length, 'feeds count', 1)
            .having((s) => s.pendingCount, 'pendingCount', 1),
        isA<ImportOpmlPreview>()
            .having((s) => s.feeds.length, 'feeds count', 2)
            .having((s) => s.pendingCount, 'pendingCount', 0),
      ],
    );

    blocTest<ImportOpmlCubit, ImportOpmlState>(
      'emite Error cuando el OPML no tiene feeds',
      build: buildCubit,
      setUp: () {
        when(() => mockImportOpml.parseUrls(any())).thenReturn([]);
      },
      act: (cubit) => cubit.loadPreview('<opml/>'),
      expect: () => [
        const ImportOpmlValidating(),
        isA<ImportOpmlError>(),
      ],
    );

    blocTest<ImportOpmlCubit, ImportOpmlState>(
      'emite Error cuando el parser lanza ParseException',
      build: buildCubit,
      setUp: () {
        when(() => mockImportOpml.parseUrls(any()))
            .thenThrow(const ParseException('XML inválido'));
      },
      act: (cubit) => cubit.loadPreview('no xml'),
      expect: () => [
        const ImportOpmlValidating(),
        const ImportOpmlError('XML inválido'),
      ],
    );

    blocTest<ImportOpmlCubit, ImportOpmlState>(
      'feeds válidos quedan seleccionados por defecto',
      build: buildCubit,
      setUp: () {
        when(() => mockImportOpml.parseUrls(any()))
            .thenReturn(['https://a.com/feed', 'https://b.com/feed']);
        when(() => mockImportOpml.validateFeeds(
              any(),
              onResult: any(named: 'onResult'),
            )).thenAnswer((invocation) async {
          final onResult = invocation.namedArguments[const Symbol('onResult')]
              as void Function(OpmlFeedValidation);
          onResult(OpmlFeedValidation(
            url: 'https://a.com/feed',
            name: 'Feed A',
            status: OpmlFeedValidationStatus.valid,
          ));
          onResult(OpmlFeedValidation(
            url: 'https://b.com/feed',
            name: 'Feed B',
            status: OpmlFeedValidationStatus.duplicate,
          ));
        });
      },
      act: (cubit) => cubit.loadPreview('<opml/>'),
      verify: (cubit) {
        final state = cubit.state as ImportOpmlPreview;
        final feedA = state.feeds.firstWhere((f) => f.url == 'https://a.com/feed');
        final feedB = state.feeds.firstWhere((f) => f.url == 'https://b.com/feed');
        expect(feedA.selected, isTrue);
        expect(feedB.selected, isFalse);
      },
    );
  });

  group('toggleSelection', () {
    blocTest<ImportOpmlCubit, ImportOpmlState>(
      'invierte la selección de un feed válido',
      build: buildCubit,
      seed: () => ImportOpmlPreview(const [
        OpmlFeedItem(
          url: 'https://a.com/feed',
          name: 'Feed A',
          status: OpmlFeedStatus.valid,
          selected: true,
        ),
      ]),
      act: (cubit) => cubit.toggleSelection('https://a.com/feed'),
      expect: () => [
        isA<ImportOpmlPreview>().having(
          (s) => s.feeds.first.selected,
          'selected',
          isFalse,
        ),
      ],
    );

    blocTest<ImportOpmlCubit, ImportOpmlState>(
      'no emite nuevo estado para feeds duplicados',
      build: buildCubit,
      seed: () => ImportOpmlPreview(const [
        OpmlFeedItem(
          url: 'https://a.com/feed',
          name: 'Feed A',
          status: OpmlFeedStatus.duplicate,
          selected: false,
        ),
      ]),
      act: (cubit) => cubit.toggleSelection('https://a.com/feed'),
      // Equatable suprime la emisión porque el estado no cambia
      expect: () => [],
    );
  });

  group('confirmImport', () {
    blocTest<ImportOpmlCubit, ImportOpmlState>(
      'emite Importing → Done con conteos correctos',
      build: buildCubit,
      setUp: () {
        when(() => mockImportOpml.execute(any()))
            .thenAnswer((_) async => ImportOpmlResult(
                  imported: [_tSource],
                  skippedDuplicates: [],
                  failed: [],
                ));
      },
      seed: () => ImportOpmlPreview(const [
        OpmlFeedItem(
          url: 'https://a.com/feed',
          name: 'Feed A',
          status: OpmlFeedStatus.valid,
          selected: true,
        ),
      ]),
      act: (cubit) => cubit.confirmImport(),
      expect: () => [
        const ImportOpmlImporting(),
        const ImportOpmlDone(importedCount: 1, failedCount: 0),
      ],
    );

    blocTest<ImportOpmlCubit, ImportOpmlState>(
      'no hace nada si no hay feeds seleccionados',
      build: buildCubit,
      seed: () => ImportOpmlPreview(const [
        OpmlFeedItem(
          url: 'https://a.com/feed',
          name: 'Feed A',
          status: OpmlFeedStatus.valid,
          selected: false,
        ),
      ]),
      act: (cubit) => cubit.confirmImport(),
      expect: () => [],
    );
  });
}
