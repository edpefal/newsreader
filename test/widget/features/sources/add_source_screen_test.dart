import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/features/sources/presentation/cubit/add_source_cubit.dart';
import 'package:newsreader/features/sources/presentation/screens/add_source_screen.dart';

import '../../../support/pump_localized_app.dart';

class MockAddSourceCubit extends MockCubit<AddSourceState>
    implements AddSourceCubit {}

Widget _buildSubject(AddSourceCubit cubit) {
  return MaterialApp(
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    home: BlocProvider<AddSourceCubit>.value(
      value: cubit,
      child: const AddSourceView(),
    ),
  );
}

/// Envuelve `AddSourceView` en un `Navigator` real con una pantalla debajo,
/// para poder observar el valor con el que hace `pop` al recibir
/// `AddSourceSuccess`.
Widget _buildSubjectWithPopObserver(
  AddSourceCubit cubit,
  void Function(NewsSource?) onPopped,
) {
  return MaterialApp(
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<NewsSource>(
                MaterialPageRoute(
                  builder: (_) => BlocProvider<AddSourceCubit>.value(
                    value: cubit,
                    child: const AddSourceView(),
                  ),
                ),
              );
              onPopped(result);
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
}

/// Envuelve `AddSourceView` en un `Navigator` real con una pantalla debajo,
/// para poder navegar hacia atrás con el botón de back del `AppBar`.
Widget _buildSubjectPushed(AddSourceCubit cubit) {
  return MaterialApp(
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push<NewsSource>(
              MaterialPageRoute(
                builder: (_) => BlocProvider<AddSourceCubit>.value(
                  value: cubit,
                  child: const AddSourceView(),
                ),
              ),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
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

    testWidgets(
        'muestra "Buscando en varios lugares posibles..." cuando estado es ValidatingHeuristics',
        (tester) async {
      when(() => cubit.state)
          .thenReturn(const AddSourceValidatingHeuristics());

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Buscando en varios lugares posibles...'), findsOneWidget);
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

    testWidgets(
        'muestra snackbar sin ninguna acción cuando falla la detección',
        (tester) async {
      whenListen(
        cubit,
        Stream.fromIterable([
          const AddSourceValidating(),
          const AddSourceFeedDiscoveryFailed(
            'No pudimos detectar el feed automáticamente.',
            'https://sin-feed.com',
          ),
        ]),
        initialState: const AddSourceInitial(),
      );

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.pumpAndSettle();

      expect(
        find.text('No pudimos detectar el feed automáticamente.'),
        findsOneWidget,
      );
      expect(find.text('Generar email'), findsNothing);
    });

    testWidgets(
        'cierra el snackbar de error al tocar el ícono de cerrar',
        (tester) async {
      whenListen(
        cubit,
        Stream.fromIterable([
          const AddSourceValidating(),
          const AddSourceFeedDiscoveryFailed(
            'No pudimos detectar el feed automáticamente.',
            'https://sin-feed.com',
          ),
        ]),
        initialState: const AddSourceInitial(),
      );

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.pumpAndSettle();

      expect(
        find.text('No pudimos detectar el feed automáticamente.'),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(
        find.text('No pudimos detectar el feed automáticamente.'),
        findsNothing,
      );
    });

    testWidgets(
        'oculta el snackbar de error previo al reintentar agregar una fuente',
        (tester) async {
      when(() => cubit.addSource(any())).thenAnswer((_) async {});

      whenListen(
        cubit,
        Stream.fromIterable([
          const AddSourceValidating(),
          const AddSourceFeedDiscoveryFailed(
            'No pudimos detectar el feed automáticamente.',
            'https://sin-feed.com',
          ),
        ]),
        initialState: const AddSourceInitial(),
      );

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.pumpAndSettle();

      expect(
        find.text('No pudimos detectar el feed automáticamente.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'https://otra-url.com');
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();

      expect(
        find.text('No pudimos detectar el feed automáticamente.'),
        findsNothing,
      );
    });

    testWidgets(
        'oculta el snackbar de error al salir de la pantalla',
        (tester) async {
      whenListen(
        cubit,
        Stream.fromIterable([
          const AddSourceValidating(),
          const AddSourceFeedDiscoveryFailed(
            'No pudimos detectar el feed automáticamente.',
            'https://sin-feed.com',
          ),
        ]),
        initialState: const AddSourceInitial(),
      );

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_buildSubjectPushed(cubit));
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(
        find.text('No pudimos detectar el feed automáticamente.'),
        findsOneWidget,
      );

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(
        find.text('No pudimos detectar el feed automáticamente.'),
        findsNothing,
      );
    });

    testWidgets(
        'la card de generar email está visible y colapsada al abrir la pantalla',
        (tester) async {
      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Generar dirección de email'), findsOneWidget);
      expect(
        find.text(
          'Para newsletters sin RSS: los correos se convierten en artículos.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Te damos una dirección única. Suscribe el newsletter con ella '
          'y cada correo que llegue aparecerá aquí.',
        ),
        findsNothing,
      );
    });

    testWidgets('tocar la card de email la expande mostrando el detalle',
        (tester) async {
      await tester.pumpWidget(_buildSubject(cubit));

      await tester.tap(find.text('Generar dirección de email'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Te damos una dirección única. Suscribe el newsletter con ella '
          'y cada correo que llegue aparecerá aquí.',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(FilledButton, 'Generar dirección de email'),
        findsOneWidget,
      );
    });

    testWidgets(
        'tocar el botón interno de la card expandida llama a generateEmailFeed',
        (tester) async {
      when(() => cubit.generateEmailFeed(label: any(named: 'label')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.text('Generar dirección de email'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FilledButton, 'Generar dirección de email'),
      );

      verify(() => cubit.generateEmailFeed()).called(1);
    });

    testWidgets('la card de email se colapsa tras generar exitosamente',
        (tester) async {
      const feed = (
        email: 'abc-123@dominio.com',
        feedUrl: 'https://x.supabase.co/functions/v1/feed/abc-123',
      );
      final controller = StreamController<AddSourceState>();
      addTearDown(controller.close);
      whenListen(cubit, controller.stream, initialState: const AddSourceInitial());

      await tester.pumpWidget(_buildSubject(cubit));

      await tester.tap(find.text('Generar dirección de email'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Te damos una dirección única. Suscribe el newsletter con ella '
          'y cada correo que llegue aparecerá aquí.',
        ),
        findsOneWidget,
      );

      controller.add(const AddSourceGeneratingEmailFeed());
      await tester.pump();
      controller.add(const AddSourceEmailFeedGenerated(feed));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Te damos una dirección única. Suscribe el newsletter con ella '
          'y cada correo que llegue aparecerá aquí.',
        ),
        findsNothing,
      );
    });

    testWidgets(
        'la card de email se colapsa al agregar una fuente exitosamente',
        (tester) async {
      final tSource = NewsSource(
        id: 's2',
        name: 'Otra fuente',
        feedUrl: 'https://otra.com/feed',
        addedAt: DateTime(2024),
      );
      final controller = StreamController<AddSourceState>();
      addTearDown(controller.close);
      whenListen(cubit, controller.stream, initialState: const AddSourceInitial());

      NewsSource? poppedResult;
      await tester.pumpWidget(
        _buildSubjectWithPopObserver(cubit, (result) => poppedResult = result),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generar dirección de email'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Te damos una dirección única. Suscribe el newsletter con ella '
          'y cada correo que llegue aparecerá aquí.',
        ),
        findsOneWidget,
      );

      controller.add(AddSourceSuccess(tSource));
      await tester.pumpAndSettle();

      expect(poppedResult, tSource);
    });

    testWidgets('muestra diálogo con la dirección generada', (tester) async {
      const feed = (
        email: 'abc-123@dominio.com',
        feedUrl: 'https://x.supabase.co/functions/v1/feed/abc-123',
      );

      whenListen(
        cubit,
        Stream.fromIterable([
          const AddSourceGeneratingEmailFeed(),
          const AddSourceEmailFeedGenerated(feed),
        ]),
        initialState: const AddSourceInitial(),
      );

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.pump();

      expect(find.text('abc-123@dominio.com'), findsOneWidget);
      expect(find.text('Ya me suscribí'), findsOneWidget);
    });

    testWidgets('al agregar exitosamente, hace pop con la fuente agregada',
        (tester) async {
      final tSource = NewsSource(
        id: 's1',
        name: 'Newsletter Nueva',
        feedUrl: 'https://nueva.com/feed',
        addedAt: DateTime(2024),
      );

      whenListen(
        cubit,
        Stream.fromIterable([AddSourceSuccess(tSource)]),
        initialState: const AddSourceInitial(),
      );

      NewsSource? poppedResult;
      await tester.pumpWidget(
        _buildSubjectWithPopObserver(cubit, (result) => poppedResult = result),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(poppedResult, tSource);
    });
  });
}
