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

Widget _buildSubject(SourcesCubit cubit) {
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
        builder: (_, __) => const Scaffold(body: Text('Agregar')),
      ),
      GoRoute(
        path: '/sources/:id',
        builder: (_, __) => const Scaffold(body: Text('Detalle')),
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

      expect(find.text('Aún no tienes newsletters'), findsOneWidget);
      expect(find.text('Agregar mi primer newsletter'), findsOneWidget);
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
