import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/email_feed/email_feed_generator.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/features/sources/domain/usecases/add_source.dart';
import 'package:newsreader/features/sources/domain/usecases/generate_email_feed.dart';
import 'package:newsreader/features/sources/presentation/cubit/add_source_cubit.dart';

class MockAddSource extends Mock implements AddSource {}
class MockGenerateEmailFeed extends Mock implements GenerateEmailFeed {}

void main() {
  late MockAddSource mockAddSource;
  late MockGenerateEmailFeed mockGenerateEmailFeed;

  final tSource = NewsSource(
    id: '1',
    name: 'Test Newsletter',
    feedUrl: 'https://example.com/feed',
    addedAt: DateTime(2024),
  );

  const tGeneratedFeed = (
    email: 'abc-123@dominio.com',
    feedUrl: 'https://x.supabase.co/functions/v1/feed/abc-123',
  );

  setUp(() {
    mockAddSource = MockAddSource();
    mockGenerateEmailFeed = MockGenerateEmailFeed();
  });

  AddSourceCubit buildCubit() =>
      AddSourceCubit(mockAddSource, mockGenerateEmailFeed);

  group('AddSourceCubit', () {
    test('estado inicial es AddSourceInitial', () {
      expect(buildCubit().state, const AddSourceInitial());
    });

    blocTest<AddSourceCubit, AddSourceState>(
      'emite [Validating, Success] cuando la URL es válida',
      build: () {
        when(() => mockAddSource.execute(any()))
            .thenAnswer((_) async => tSource);
        return buildCubit();
      },
      act: (cubit) => cubit.addSource('https://example.com/feed'),
      expect: () => [
        const AddSourceValidating(),
        AddSourceSuccess(tSource),
      ],
    );

    blocTest<AddSourceCubit, AddSourceState>(
      'emite [Error] inmediato si la URL está vacía',
      build: buildCubit,
      act: (cubit) => cubit.addSource('   '),
      expect: () => [
        const AddSourceError('Ingresa una URL válida.'),
      ],
      verify: (_) => verifyNever(() => mockAddSource.execute(any())),
    );

    blocTest<AddSourceCubit, AddSourceState>(
      'emite [Validating, Error] cuando el feed no es válido (ParseException)',
      build: () {
        when(() => mockAddSource.execute(any()))
            .thenThrow(const ParseException());
        return buildCubit();
      },
      act: (cubit) => cubit.addSource('https://example.com/not-a-feed'),
      expect: () => [
        const AddSourceValidating(),
        const AddSourceError('No se encontró un feed válido en esta URL'),
      ],
    );

    blocTest<AddSourceCubit, AddSourceState>(
      'emite [Validating, Error] cuando no hay conexión (NetworkException)',
      build: () {
        when(() => mockAddSource.execute(any()))
            .thenThrow(const NetworkException());
        return buildCubit();
      },
      act: (cubit) => cubit.addSource('https://example.com/feed'),
      expect: () => [
        const AddSourceValidating(),
        const AddSourceError('Sin conexión a internet'),
      ],
    );

    blocTest<AddSourceCubit, AddSourceState>(
      'emite [Validating, Error] cuando la fuente ya existe (DuplicateSourceException)',
      build: () {
        when(() => mockAddSource.execute(any()))
            .thenThrow(const DuplicateSourceException());
        return buildCubit();
      },
      act: (cubit) => cubit.addSource('https://example.com/feed'),
      expect: () => [
        const AddSourceValidating(),
        const AddSourceError('Ya estás suscrito a esta fuente'),
      ],
    );

    blocTest<AddSourceCubit, AddSourceState>(
      'emite [Validating, Error] cuando hay timeout (TimeoutException)',
      build: () {
        when(() => mockAddSource.execute(any()))
            .thenThrow(const TimeoutException());
        return buildCubit();
      },
      act: (cubit) => cubit.addSource('https://example.com/feed'),
      expect: () => [
        const AddSourceValidating(),
        const AddSourceError('La solicitud tardó demasiado'),
      ],
    );

    blocTest<AddSourceCubit, AddSourceState>(
      'emite [Validating, FeedDiscoveryFailed] cuando no se pudo detectar el feed',
      build: () {
        when(() => mockAddSource.execute(any()))
            .thenThrow(const FeedDiscoveryException());
        return buildCubit();
      },
      act: (cubit) => cubit.addSource('https://sitio-desconocido.com'),
      expect: () => [
        const AddSourceValidating(),
        const AddSourceFeedDiscoveryFailed(
          'No pudimos detectar el feed automáticamente. Pega la URL exacta '
              'del feed RSS (por ejemplo, que termine en /feed o .xml).',
          'https://sitio-desconocido.com',
        ),
      ],
    );

    blocTest<AddSourceCubit, AddSourceState>(
      'emite [GeneratingEmailFeed, EmailFeedGenerated] cuando se genera con éxito',
      build: () {
        when(() => mockGenerateEmailFeed.execute(label: any(named: 'label')))
            .thenAnswer((_) async => tGeneratedFeed);
        return buildCubit();
      },
      act: (cubit) => cubit.generateEmailFeed(),
      expect: () => [
        const AddSourceGeneratingEmailFeed(),
        const AddSourceEmailFeedGenerated(tGeneratedFeed),
      ],
    );

    blocTest<AddSourceCubit, AddSourceState>(
      'emite [GeneratingEmailFeed, Error] cuando falla la generación',
      build: () {
        when(() => mockGenerateEmailFeed.execute(label: any(named: 'label')))
            .thenThrow(const EmailFeedGenerationException('Límite alcanzado'));
        return buildCubit();
      },
      act: (cubit) => cubit.generateEmailFeed(),
      expect: () => [
        const AddSourceGeneratingEmailFeed(),
        const AddSourceError('Límite alcanzado'),
      ],
    );

    blocTest<AddSourceCubit, AddSourceState>(
      'reset() vuelve a AddSourceInitial',
      build: buildCubit,
      seed: () => const AddSourceError('error previo'),
      act: (cubit) => cubit.reset(),
      expect: () => [const AddSourceInitial()],
    );
  });
}
