import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:newsreader/features/favorites/presentation/screens/favorites_screen.dart';

class MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

Widget _buildSubject(FavoritesCubit cubit) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => BlocProvider<FavoritesCubit>.value(
          value: cubit,
          child: const FavoritesView(),
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
  late MockFavoritesCubit cubit;

  final tArticles = [
    Article(
      id: 'a1',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo favorito uno',
      publishedAt: DateTime(2024, 1, 15),
      articleUrl: 'https://example.com/1',
      isFavorite: true,
    ),
    Article(
      id: 'a2',
      sourceId: 's1',
      sourceName: 'Newsletter A',
      title: 'Artículo favorito dos',
      publishedAt: DateTime(2024, 1, 14),
      articleUrl: 'https://example.com/2',
      isFavorite: true,
    ),
  ];

  setUp(() {
    cubit = MockFavoritesCubit();
  });

  group('FavoritesScreen', () {
    testWidgets('muestra spinner cuando estado es FavoritesLoading',
        (tester) async {
      when(() => cubit.state).thenReturn(const FavoritesLoading());

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('muestra estado vacío cuando no hay favoritos', (tester) async {
      when(() => cubit.state).thenReturn(const FavoritesLoaded([]));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Sin favoritos aún'), findsOneWidget);
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
    });

    testWidgets('muestra lista de artículos cuando hay favoritos',
        (tester) async {
      when(() => cubit.state).thenReturn(FavoritesLoaded(tArticles));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Artículo favorito uno'), findsOneWidget);
      expect(find.text('Artículo favorito dos'), findsOneWidget);
    });

    testWidgets('muestra el título del AppBar "Favoritos"', (tester) async {
      when(() => cubit.state).thenReturn(const FavoritesLoaded([]));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Favoritos'), findsOneWidget);
    });

    testWidgets('tap en artículo navega al reader', (tester) async {
      when(() => cubit.state).thenReturn(FavoritesLoaded(tArticles));
      when(() => cubit.loadFavorites()).thenAnswer((_) async {});

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.text('Artículo favorito uno'));
      await tester.pumpAndSettle();

      expect(find.text('Reader'), findsOneWidget);
    });

    testWidgets('al volver del reader llama a loadFavorites', (tester) async {
      when(() => cubit.state).thenReturn(FavoritesLoaded(tArticles));
      when(() => cubit.loadFavorites()).thenAnswer((_) async {});

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.text('Artículo favorito uno'));
      await tester.pumpAndSettle();

      // navigate back
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      verify(() => cubit.loadFavorites()).called(1);
    });
  });
}
