import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/features/sources/domain/usecases/add_source.dart';
import 'package:newsreader/features/sources/presentation/cubit/add_source_cubit.dart';

class MockAddSource extends Mock implements AddSource {}

void main() {
  late MockAddSource mockAddSource;

  final tSource = NewsSource(
    id: '1',
    name: 'Test Newsletter',
    feedUrl: 'https://example.com/feed',
    addedAt: DateTime(2024),
  );

  setUp(() {
    mockAddSource = MockAddSource();
  });

  group('AddSourceCubit', () {
    test('estado inicial es AddSourceInitial', () {
      expect(
        AddSourceCubit(mockAddSource).state,
        const AddSourceInitial(),
      );
    });

    blocTest<AddSourceCubit, AddSourceState>(
      'emite [Validating, Success] cuando la URL es válida',
      build: () {
        when(() => mockAddSource.execute(any()))
            .thenAnswer((_) async => tSource);
        return AddSourceCubit(mockAddSource);
      },
      act: (cubit) => cubit.addSource('https://example.com/feed'),
      expect: () => [
        const AddSourceValidating(),
        AddSourceSuccess(tSource),
      ],
    );

    blocTest<AddSourceCubit, AddSourceState>(
      'emite [Error] inmediato si la URL está vacía',
      build: () => AddSourceCubit(mockAddSource),
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
        return AddSourceCubit(mockAddSource);
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
        return AddSourceCubit(mockAddSource);
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
        return AddSourceCubit(mockAddSource);
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
        return AddSourceCubit(mockAddSource);
      },
      act: (cubit) => cubit.addSource('https://example.com/feed'),
      expect: () => [
        const AddSourceValidating(),
        const AddSourceError('La solicitud tardó demasiado'),
      ],
    );

    blocTest<AddSourceCubit, AddSourceState>(
      'reset() vuelve a AddSourceInitial',
      build: () => AddSourceCubit(mockAddSource),
      seed: () => const AddSourceError('error previo'),
      act: (cubit) => cubit.reset(),
      expect: () => [const AddSourceInitial()],
    );
  });
}
