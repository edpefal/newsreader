import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/features/sources/presentation/cubit/import_opml_cubit.dart';
import 'package:newsreader/features/sources/presentation/screens/import_opml_screen.dart';

class MockImportOpmlCubit extends MockCubit<ImportOpmlState>
    implements ImportOpmlCubit {}

Widget _buildSubject(ImportOpmlCubit cubit) {
  return MaterialApp(
    home: BlocProvider<ImportOpmlCubit>.value(
      value: cubit,
      child: const ImportOpmlScreen(xmlContent: '<opml/>'),
    ),
  );
}

void main() {
  late MockImportOpmlCubit cubit;

  setUp(() {
    cubit = MockImportOpmlCubit();
    when(() => cubit.loadPreview(any())).thenAnswer((_) async {});
  });

  group('ImportOpmlScreen', () {
    testWidgets('muestra spinner en estado Validating', (tester) async {
      when(() => cubit.state).thenReturn(const ImportOpmlValidating());

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Validando feeds…'), findsOneWidget);
    });

    testWidgets('muestra lista con checkbox para feed válido', (tester) async {
      when(() => cubit.state).thenReturn(
        const ImportOpmlPreview([
          OpmlFeedItem(
            url: 'https://a.com/feed',
            name: 'Feed A',
            status: OpmlFeedStatus.valid,
            selected: true,
          ),
        ]),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(CheckboxListTile), findsOneWidget);
      expect(find.text('Feed A'), findsOneWidget);
    });

    testWidgets('muestra tile deshabilitado con "Ya suscrito" para duplicado',
        (tester) async {
      when(() => cubit.state).thenReturn(
        const ImportOpmlPreview([
          OpmlFeedItem(
            url: 'https://b.com/feed',
            name: 'Feed B',
            status: OpmlFeedStatus.duplicate,
            selected: false,
          ),
        ]),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Ya suscrito'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNothing);
    });

    testWidgets('botón Importar habilitado cuando hay selección', (tester) async {
      when(() => cubit.state).thenReturn(
        const ImportOpmlPreview([
          OpmlFeedItem(
            url: 'https://a.com/feed',
            name: 'Feed A',
            status: OpmlFeedStatus.valid,
            selected: true,
          ),
        ]),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
      expect(find.text('Importar (1)'), findsOneWidget);
    });

    testWidgets('botón Importar deshabilitado sin selección', (tester) async {
      when(() => cubit.state).thenReturn(
        const ImportOpmlPreview([
          OpmlFeedItem(
            url: 'https://a.com/feed',
            name: 'Feed A',
            status: OpmlFeedStatus.valid,
            selected: false,
          ),
        ]),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('muestra mensaje de error en estado ImportOpmlError',
        (tester) async {
      when(() => cubit.state).thenReturn(
        const ImportOpmlError('El archivo no es un OPML válido'),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('El archivo no es un OPML válido'), findsOneWidget);
    });
  });
}
