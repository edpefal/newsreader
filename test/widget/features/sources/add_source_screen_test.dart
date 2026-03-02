import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/features/sources/presentation/cubit/add_source_cubit.dart';
import 'package:newsreader/features/sources/presentation/screens/add_source_screen.dart';

class MockAddSourceCubit extends MockCubit<AddSourceState>
    implements AddSourceCubit {}

Widget _buildSubject(AddSourceCubit cubit) {
  return MaterialApp(
    home: BlocProvider<AddSourceCubit>.value(
      value: cubit,
      child: const AddSourceView(),
    ),
  );
}

void main() {
  late MockAddSourceCubit cubit;

  setUp(() {
    cubit = MockAddSourceCubit();
    when(() => cubit.state).thenReturn(const AddSourceInitial());
  });

  group('AddSourceScreen', () {
    testWidgets('muestra campo de texto y botón Agregar', (tester) async {
      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Agregar'), findsOneWidget);
    });

    testWidgets('muestra spinner en el botón cuando estado es Validating',
        (tester) async {
      when(() => cubit.state).thenReturn(const AddSourceValidating());

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Agregar'), findsNothing);
    });

    testWidgets('botón está deshabilitado cuando estado es Validating',
        (tester) async {
      when(() => cubit.state).thenReturn(const AddSourceValidating());

      await tester.pumpWidget(_buildSubject(cubit));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('muestra snackbar de error cuando estado es AddSourceError',
        (tester) async {
      whenListen(
        cubit,
        Stream.fromIterable([
          const AddSourceValidating(),
          const AddSourceError('No se encontró un feed válido en esta URL'),
        ]),
        initialState: const AddSourceInitial(),
      );

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.pump();

      expect(
        find.text('No se encontró un feed válido en esta URL'),
        findsOneWidget,
      );
    });

    testWidgets('llama addSource con el texto ingresado al pulsar Agregar',
        (tester) async {
      when(() => cubit.addSource(any())).thenAnswer((_) async {});

      await tester.pumpWidget(_buildSubject(cubit));

      await tester.enterText(
        find.byType(TextField),
        'https://example.com/feed',
      );
      await tester.tap(find.text('Agregar'));

      verify(() => cubit.addSource('https://example.com/feed')).called(1);
    });
  });
}
