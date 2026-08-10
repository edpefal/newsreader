import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/features/sources/presentation/cubit/sources_cubit.dart';
import 'package:newsreader/features/sources/presentation/screens/sources_screen.dart';

class MockSourcesCubit extends MockCubit<SourcesState>
    implements SourcesCubit {}

Widget _buildSubject(SourcesCubit cubit, {NewsSource? sourceToReturnOnAdd}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => BlocProvider<SourcesCubit>.value(
          value: cubit,
          child: const SourcesView(),
        ),
      ),
      GoRoute(
        path: '/sources/add',
        builder: (context, __) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).pop(sourceToReturnOnAdd),
            child: const Text('Simular agregado'),
          ),
        ),
      ),
      GoRoute(
        path: '/sources/:id',
        builder: (_, state) => Scaffold(
          body: Text(
            'Detalle${state.uri.queryParameters['justAdded'] == 'true' ? ' (justAdded)' : ''}',
          ),
        ),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  late MockSourcesCubit cubit;

  final tSources = [
    NewsSource(
      id: '1',
      name: 'Newsletter A',
      feedUrl: 'https://a.com/feed',
      addedAt: DateTime(2024),
    ),
    NewsSource(
      id: '2',
      name: 'Newsletter B',
      feedUrl: 'https://b.com/feed',
      addedAt: DateTime(2024),
    ),
  ];

  setUp(() {
    cubit = MockSourcesCubit();
  });

  group('SourcesScreen', () {
    testWidgets('muestra spinner cuando estado es SourcesLoading',
        (tester) async {
      when(() => cubit.state).thenReturn(const SourcesLoading());

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra estado vacío cuando no hay fuentes', (tester) async {
      when(() => cubit.state).thenReturn(const SourcesLoaded([]));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Aún no tienes fuentes'), findsOneWidget);
      expect(find.text('Agregar mi primera fuente'), findsOneWidget);
    });

    testWidgets(
        'muestra solo las fuentes que coinciden con la búsqueda activa',
        (tester) async {
      when(() => cubit.state).thenReturn(
        SourcesLoaded(tSources, searchQuery: 'Newsletter A'),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Newsletter A'), findsOneWidget);
      expect(find.text('Newsletter B'), findsNothing);
    });

    testWidgets(
        'muestra NoSearchResultsState cuando la búsqueda no encuentra nada',
        (tester) async {
      when(() => cubit.state).thenReturn(
        SourcesLoaded(tSources, searchQuery: 'inexistente'),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Sin resultados'), findsOneWidget);
      expect(find.text('Aún no tienes fuentes'), findsNothing);
    });

    testWidgets('muestra lista de fuentes cuando hay fuentes', (tester) async {
      when(() => cubit.state).thenReturn(SourcesLoaded(tSources));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Newsletter A'), findsOneWidget);
      expect(find.text('Newsletter B'), findsOneWidget);
    });

    testWidgets('muestra FAB en pantalla de fuentes', (tester) async {
      when(() => cubit.state).thenReturn(const SourcesLoaded([]));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('muestra menú de opciones por cada fuente', (tester) async {
      when(() => cubit.state).thenReturn(SourcesLoaded(tSources));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(
        find.byWidgetPredicate((w) => w is PopupMenuButton),
        findsNWidgets(tSources.length),
      );
    });

    testWidgets('tap en fuente navega al detalle de la fuente', (tester) async {
      when(() => cubit.state).thenReturn(SourcesLoaded(tSources));

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.text('Newsletter A'));
      await tester.pumpAndSettle();

      expect(find.text('Detalle'), findsOneWidget);
    });

    testWidgets(
        'al agregar una fuente, recarga la lista y navega a su detalle con justAdded',
        (tester) async {
      when(() => cubit.state).thenReturn(const SourcesLoaded([]));
      when(() => cubit.loadSources()).thenAnswer((_) async {});
      final addedSource = NewsSource(
        id: 'new-1',
        name: 'Newsletter Nueva',
        feedUrl: 'https://nueva.com/feed',
        addedAt: DateTime(2024),
      );

      await tester.pumpWidget(
        _buildSubject(cubit, sourceToReturnOnAdd: addedSource),
      );
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simular agregado'));
      await tester.pumpAndSettle();

      verify(() => cubit.loadSources()).called(1);
      expect(find.text('Detalle (justAdded)'), findsOneWidget);
    });

    testWidgets(
        'si no vuelve ninguna fuente del flujo de agregar, no recarga ni navega',
        (tester) async {
      when(() => cubit.state).thenReturn(const SourcesLoaded([]));

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simular agregado'));
      await tester.pumpAndSettle();

      verifyNever(() => cubit.loadSources());
      expect(find.text('Agregar mi primera fuente'), findsOneWidget);
    });

    testWidgets('el menú muestra opciones Editar y Eliminar', (tester) async {
      when(() => cubit.state).thenReturn(SourcesLoaded(tSources));

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(
        find.byWidgetPredicate((w) => w is PopupMenuButton).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Editar nombre'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });
  });
}
