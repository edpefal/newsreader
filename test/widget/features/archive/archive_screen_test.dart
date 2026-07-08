import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/archive/presentation/cubit/archive_cubit.dart';
import 'package:newsreader/features/archive/presentation/screens/archive_screen.dart';

class MockArchiveCubit extends MockCubit<ArchiveState>
    implements ArchiveCubit {}

Widget _buildSubject(ArchiveCubit cubit) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => BlocProvider<ArchiveCubit>.value(
          value: cubit,
          child: const ArchiveView(),
        ),
      ),
      GoRoute(
        path: '/article/:id',
        builder: (_, __) => const Scaffold(body: Text('Reader')),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  late MockArchiveCubit cubit;

  final tArticles = [
    Article(
      id: 'a1',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo archivado uno',
      publishedAt: DateTime(2024, 1, 15),
      articleUrl: 'https://example.com/1',
      isRead: true,
    ),
    Article(
      id: 'a2',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo archivado dos',
      publishedAt: DateTime(2024, 1, 14),
      articleUrl: 'https://example.com/2',
      isRead: true,
    ),
  ];

  setUp(() {
    cubit = MockArchiveCubit();
  });

  group('ArchiveScreen', () {
    testWidgets('muestra spinner cuando estado es ArchiveLoading',
        (tester) async {
      when(() => cubit.state).thenReturn(const ArchiveLoading());

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra estado vacío cuando no hay archivados', (tester) async {
      when(() => cubit.state).thenReturn(const ArchiveLoaded([]));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Sin artículos leídos'), findsOneWidget);
      expect(find.byIcon(Icons.archive_outlined), findsOneWidget);
    });

    testWidgets('muestra lista de artículos cuando hay archivados',
        (tester) async {
      when(() => cubit.state).thenReturn(ArchiveLoaded(tArticles));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Artículo archivado uno'), findsOneWidget);
      expect(find.text('Artículo archivado dos'), findsOneWidget);
    });

    testWidgets('muestra el título del AppBar "Leídos"', (tester) async {
      when(() => cubit.state).thenReturn(const ArchiveLoaded([]));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Leídos'), findsOneWidget);
    });

    testWidgets('tap en artículo navega al reader', (tester) async {
      when(() => cubit.state).thenReturn(ArchiveLoaded(tArticles));
      when(() => cubit.loadArchive()).thenAnswer((_) async {});

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.text('Artículo archivado uno'));
      await tester.pumpAndSettle();

      expect(find.text('Reader'), findsOneWidget);
    });

    testWidgets('muestra separadores de fecha agrupando artículos por día',
        (tester) async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final articles = [
        Article(
          id: 'hoy',
          sourceId: 's1',
          sourceName: 'Newsletter A',
          title: 'Archivado de hoy',
          publishedAt: DateTime(now.year, now.month, now.day, 10),
          articleUrl: 'https://example.com/hoy',
          isRead: true,
        ),
        Article(
          id: 'ayer',
          sourceId: 's1',
          sourceName: 'Newsletter A',
          title: 'Archivado de ayer',
          publishedAt:
              DateTime(yesterday.year, yesterday.month, yesterday.day, 10),
          articleUrl: 'https://example.com/ayer',
          isRead: true,
        ),
      ];

      when(() => cubit.state).thenReturn(ArchiveLoaded(articles));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Hoy'), findsOneWidget);
      expect(find.text('Ayer'), findsOneWidget);
    });

    testWidgets('al volver del reader llama a loadArchive', (tester) async {
      when(() => cubit.state).thenReturn(ArchiveLoaded(tArticles));
      when(() => cubit.loadArchive()).thenAnswer((_) async {});

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.text('Artículo archivado uno'));
      await tester.pumpAndSettle();

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      verify(() => cubit.loadArchive()).called(1);
    });
  });
}
