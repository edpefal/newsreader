import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../core/feed/feed_parser.dart';
import '../../core/feed/webfeed_feed_parser.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/navigation/go_router_navigator.dart';
import '../../core/network/http_client.dart';
import '../../core/network/http_package_client.dart';
import '../../core/utils/id_generator.dart';
import '../../core/utils/uuid_id_generator.dart';
import '../../data/datasources/local/article_local_datasource.dart';
import '../../data/datasources/local/hive_article_datasource.dart';
import '../../data/datasources/local/hive_source_datasource.dart';
import '../../data/datasources/local/source_local_datasource.dart';
import '../../data/models/article_model.dart';
import '../../data/models/news_source_model.dart';
import '../../data/repositories/article_repository_impl.dart';
import '../../data/repositories/source_repository_impl.dart';
import '../../domain/repositories/article_repository.dart';
import '../../domain/repositories/source_repository.dart';
import '../../domain/usecases/article/get_archive.dart';
import '../../domain/usecases/article/get_favorites.dart';
import '../../domain/usecases/article/get_inbox_articles.dart';
import '../../domain/usecases/article/mark_article_as_read.dart';
import '../../domain/usecases/article/sync_sources.dart';
import '../../domain/usecases/article/toggle_favorite.dart';
import '../../domain/usecases/maintenance/run_maintenance.dart';
import '../../domain/usecases/source/add_source.dart';
import '../../domain/usecases/source/delete_source.dart';
import '../../domain/usecases/source/get_sources.dart';
import '../../domain/usecases/source/update_source_name.dart';
import '../../presentation/theme/theme_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Core — abstractions
  getIt.registerLazySingleton<HttpClient>(() => HttpPackageClient());
  getIt.registerLazySingleton<FeedParser>(() => WebfeedFeedParser());
  getIt.registerLazySingleton<IdGenerator>(() => const UuidIdGenerator());
  getIt.registerLazySingleton<AppNavigator>(() => const GoRouterNavigator());

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

  // Repositories
  getIt.registerLazySingleton<SourceRepository>(
    () => SourceRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<ArticleRepository>(
    () => ArticleRepositoryImpl(getIt()),
  );

  // Use cases — Sources
  getIt.registerLazySingleton(
    () => AddSource(getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => DeleteSource(getIt(), getIt()));
  getIt.registerLazySingleton(() => UpdateSourceName(getIt()));
  getIt.registerLazySingleton(() => GetSources(getIt()));

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
  getIt.registerLazySingleton(() => RunMaintenance(getIt()));

  // Presentation
  getIt.registerSingleton<ThemeCubit>(
    ThemeCubit(Hive.box<dynamic>(AppConstants.hiveSettingsBox)),
  );
}
