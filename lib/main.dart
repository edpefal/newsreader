import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/di/injection.dart';
import 'package:newsreader/core/data/models/article_model.dart';
import 'package:newsreader/core/data/models/daily_summary_model.dart';
import 'package:newsreader/core/data/models/news_source_model.dart';
import 'package:newsreader/features/archive/presentation/cubit/archive_cubit.dart';
import 'package:newsreader/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/maintenance/domain/usecases/migrate_archived_articles.dart';
import 'package:newsreader/features/maintenance/domain/usecases/reset_local_articles.dart';
import 'package:newsreader/features/sources/presentation/cubit/sources_cubit.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';
import 'package:newsreader/presentation/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(NewsSourceModelAdapter());
  Hive.registerAdapter(ArticleModelAdapter());
  Hive.registerAdapter(DailySummaryModelAdapter());
  await Hive.openBox<NewsSourceModel>(AppConstants.hiveSourcesBox);
  await Hive.openBox<ArticleModel>(AppConstants.hiveArticlesBox);
  await Hive.openBox<dynamic>(AppConstants.hiveSettingsBox);
  await Hive.openBox<DailySummaryModel>(AppConstants.hiveSummariesBox);

  // 2. Initialize Supabase (usado por AuthClient; el resto de la app sigue
  // llamando a las edge functions vía HttpClient, sin el SDK de Supabase).
  await Supabase.initialize(
    url: 'https://avyaxzhdilhufyimrzzb.supabase.co',
    publishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF2eWF4emhkaWxodWZ5aW1yenpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3OTE1MTMsImV4cCI6MjA5OTM2NzUxM30.LfgL2Arsth-br6qoAUzbAYhMFtiVCXnrnpoWU59Xzh0',
  );

  // 3. Setup dependency injection
  await setupDependencies();

  // 4. One-time migration: remove auto-archived articles from previous behavior
  await getIt<MigrateArchivedArticles>().execute();

  // 4.5. One-time migration (centralize-feed-fetching): limpia los
  // artículos locales con ids viejos (generados en el cliente) antes de que
  // el sync de abajo pueda traer los nuevos (ids generados en el servidor).
  // No-op después de la primera vez que corre en cada dispositivo.
  await getIt<ResetLocalArticles>().execute();

  // 5. Sync user data with the cloud (no-op si no hay sesión activa), antes
  // de que los cubits carguen sus datos para que lo recién sincronizado se
  // vea en el primer render.
  await getIt<SyncUserData>().execute();

  // 6. Load data after maintenance so cleanup runs first
  getIt<InboxCubit>().loadArticles();
  getIt<FavoritesCubit>().loadFavorites();
  getIt<ArchiveCubit>().loadArchive();
  getIt<SourcesCubit>().loadSources();
  getIt<SummariesCubit>().loadSummaries();

  runApp(App(
    themeCubit: getIt(),
    inboxCubit: getIt(),
    favoritesCubit: getIt(),
    archiveCubit: getIt(),
    sourcesCubit: getIt(),
    summariesCubit: getIt(),
  ));
}
