import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/ai/gemini_summary_generator.dart';
import 'package:newsreader/core/ai/summary_generator.dart';
import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/feed/feed_parser.dart';
import 'package:newsreader/core/feed/webfeed_feed_parser.dart';
import 'package:newsreader/core/navigation/app_navigator.dart';
import 'package:newsreader/core/navigation/go_router_navigator.dart';
import 'package:newsreader/core/network/http_client.dart';
import 'package:newsreader/core/network/http_package_client.dart';
import 'package:newsreader/core/utils/id_generator.dart';
import 'package:newsreader/core/utils/uuid_id_generator.dart';
import 'package:newsreader/core/data/datasources/local/article_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/hive_article_datasource.dart';
import 'package:newsreader/core/data/datasources/local/hive_source_datasource.dart';
import 'package:newsreader/core/data/datasources/local/hive_summary_datasource.dart';
import 'package:newsreader/core/data/datasources/local/source_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/summary_local_datasource.dart';
import 'package:newsreader/core/data/models/article_model.dart';
import 'package:newsreader/core/data/models/daily_summary_model.dart';
import 'package:newsreader/core/data/models/news_source_model.dart';
import 'package:newsreader/core/data/repositories/article_repository_impl.dart';
import 'package:newsreader/core/data/repositories/source_repository_impl.dart';
import 'package:newsreader/core/data/repositories/summary_repository_impl.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';
import 'package:newsreader/core/domain/repositories/summary_repository.dart';
import 'package:newsreader/features/archive/domain/usecases/get_archive.dart';
import 'package:newsreader/features/archive/presentation/cubit/archive_cubit.dart';
import 'package:newsreader/features/favorites/domain/usecases/get_favorites.dart';
import 'package:newsreader/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:newsreader/features/inbox/domain/usecases/get_inbox_articles.dart';
import 'package:newsreader/features/inbox/domain/usecases/mark_article_as_read.dart';
import 'package:newsreader/features/inbox/domain/usecases/sync_sources.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/reader/domain/usecases/toggle_favorite.dart';
import 'package:newsreader/features/maintenance/domain/usecases/migrate_archived_articles.dart';
import 'package:newsreader/core/opml/opml_parser.dart';
import 'package:newsreader/core/opml/xml_opml_parser.dart';
import 'package:newsreader/features/sources/domain/usecases/add_source.dart';
import 'package:newsreader/features/sources/domain/usecases/delete_source.dart';
import 'package:newsreader/features/sources/domain/usecases/get_source_articles.dart';
import 'package:newsreader/features/sources/domain/usecases/get_sources.dart';
import 'package:newsreader/features/sources/domain/usecases/import_opml.dart';
import 'package:newsreader/features/sources/domain/usecases/update_source_name.dart';
import 'package:newsreader/features/sources/presentation/cubit/sources_cubit.dart';
import 'package:newsreader/features/summaries/domain/usecases/generate_daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/get_daily_summaries.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';
import 'package:newsreader/presentation/theme/theme_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Core — abstractions
  getIt.registerLazySingleton<HttpClient>(() => HttpPackageClient());
  getIt.registerLazySingleton<FeedParser>(() => WebfeedFeedParser());
  getIt.registerLazySingleton<IdGenerator>(() => const UuidIdGenerator());
  getIt.registerLazySingleton<AppNavigator>(() => const GoRouterNavigator());
  getIt.registerLazySingleton<OPMLParser>(() => const XmlOpmlParser());
  getIt.registerLazySingleton<SummaryGenerator>(
    () => GeminiSummaryGenerator(getIt()),
  );

  // Data sources
  getIt.registerLazySingleton<SourceLocalDataSource>(
    () => HiveSourceDatasource(
      Hive.box<NewsSourceModel>(AppConstants.hiveSourcesBox),
    ),
  );
  getIt.registerLazySingleton<ArticleLocalDataSource>(
    () => HiveArticleDatasource(
      Hive.box<ArticleModel>(AppConstants.hiveArticlesBox),
    ),
  );
  getIt.registerLazySingleton<SummaryLocalDataSource>(
    () => HiveSummaryDatasource(
      Hive.box<DailySummaryModel>(AppConstants.hiveSummariesBox),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<SourceRepository>(
    () => SourceRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<ArticleRepository>(
    () => ArticleRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<SummaryRepository>(
    () => SummaryRepositoryImpl(getIt()),
  );

  // Use cases — Sources
  getIt.registerLazySingleton(
    () => AddSource(getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => DeleteSource(getIt(), getIt()));
  getIt.registerLazySingleton(() => UpdateSourceName(getIt()));
  getIt.registerLazySingleton(() => GetSources(getIt()));
  getIt.registerLazySingleton(() => GetSourceArticles(getIt()));
  getIt.registerLazySingleton(
    () => ImportOpml(getIt(), getIt(), getIt(), getIt(), getIt()),
  );

  // Use cases — Articles
  getIt.registerLazySingleton(
    () => SyncSources(getIt(), getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => GetInboxArticles(getIt()));
  getIt.registerLazySingleton(() => MarkArticleAsRead(getIt()));
  getIt.registerLazySingleton(() => ToggleFavorite(getIt()));
  getIt.registerLazySingleton(() => GetFavorites(getIt()));
  getIt.registerLazySingleton(() => GetArchive(getIt()));

  // Use cases — Maintenance
  getIt.registerLazySingleton(() => MigrateArchivedArticles(getIt()));

  // Use cases — Summaries
  getIt.registerLazySingleton(() => GetDailySummaries(getIt()));
  getIt.registerLazySingleton(
    () => GenerateDailySummary(getIt(), getIt(), getIt()),
  );

  // Presentation
  getIt.registerSingleton<ThemeCubit>(
    ThemeCubit(Hive.box<dynamic>(AppConstants.hiveSettingsBox)),
  );
  getIt.registerSingleton<InboxCubit>(InboxCubit(getIt(), getIt(), getIt(), getIt()));
  getIt.registerSingleton<FavoritesCubit>(FavoritesCubit(getIt()));
  getIt.registerSingleton<ArchiveCubit>(ArchiveCubit(getIt()));
  getIt.registerSingleton<SourcesCubit>(
    SourcesCubit(getIt(), getIt(), getIt()),
  );
  getIt.registerSingleton<SummariesCubit>(
    SummariesCubit(getIt(), getIt()),
  );
}
