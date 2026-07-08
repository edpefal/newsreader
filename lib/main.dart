import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/di/injection.dart';
import 'package:newsreader/core/data/models/article_model.dart';
import 'package:newsreader/core/data/models/news_source_model.dart';
import 'package:newsreader/features/archive/presentation/cubit/archive_cubit.dart';
import 'package:newsreader/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/maintenance/domain/usecases/migrate_archived_articles.dart';
import 'package:newsreader/presentation/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(NewsSourceModelAdapter());
  Hive.registerAdapter(ArticleModelAdapter());
  await Hive.openBox<NewsSourceModel>(AppConstants.hiveSourcesBox);
  await Hive.openBox<ArticleModel>(AppConstants.hiveArticlesBox);
  await Hive.openBox<dynamic>(AppConstants.hiveSettingsBox);

  // 2. Setup dependency injection
  await setupDependencies();

  // 3. One-time migration: remove auto-archived articles from previous behavior
  await getIt<MigrateArchivedArticles>().execute();

  // 4. Load data after maintenance so cleanup runs first
  getIt<InboxCubit>().loadArticles();
  getIt<FavoritesCubit>().loadFavorites();
  getIt<ArchiveCubit>().loadArchive();

  runApp(App(
    themeCubit: getIt(),
    inboxCubit: getIt(),
    favoritesCubit: getIt(),
    archiveCubit: getIt(),
  ));
}
