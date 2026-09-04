import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/ai/article_summary_generator.dart';
import 'package:newsreader/core/ai/gemini_article_summary_generator.dart';
import 'package:newsreader/core/ai/gemini_summary_generator.dart';
import 'package:newsreader/core/ai/mention_enricher.dart';
import 'package:newsreader/core/ai/remote_mention_enricher.dart';
import 'package:newsreader/core/ai/summary_generator.dart';
import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/auth/supabase_auth_client.dart';
import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/email_feed/email_feed_generator.dart';
import 'package:newsreader/core/email_feed/supabase_email_feed_generator.dart';
import 'package:newsreader/core/feed/feed_parser.dart';
import 'package:newsreader/core/feed/feed_sync_trigger.dart';
import 'package:newsreader/core/feed/feed_url_resolver.dart';
import 'package:newsreader/core/feed/supabase_feed_sync_trigger.dart';
import 'package:newsreader/core/feed/webfeed_feed_parser.dart';
import 'package:newsreader/core/navigation/app_navigator.dart';
import 'package:newsreader/core/navigation/external_link_launcher.dart';
import 'package:newsreader/core/navigation/go_router_navigator.dart';
import 'package:newsreader/core/navigation/url_launcher_external_link_launcher.dart';
import 'package:newsreader/core/network/http_client.dart';
import 'package:newsreader/core/network/http_package_client.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/core/observability/default_telemetry_client.dart';
import 'package:newsreader/core/utils/id_generator.dart';
import 'package:newsreader/core/utils/uuid_id_generator.dart';
import 'package:newsreader/core/data/datasources/local/ai_usage_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/article_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/article_summary_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/daily_summary_free_usage_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/hive_ai_usage_datasource.dart';
import 'package:newsreader/core/data/datasources/local/hive_daily_summary_free_usage_datasource.dart';
import 'package:newsreader/core/data/datasources/local/hive_article_datasource.dart';
import 'package:newsreader/core/data/datasources/local/hive_article_summary_datasource.dart';
import 'package:newsreader/core/data/datasources/local/hive_source_datasource.dart';
import 'package:newsreader/core/data/datasources/local/hive_summary_datasource.dart';
import 'package:newsreader/core/data/datasources/local/source_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/summary_local_datasource.dart';
import 'package:newsreader/core/data/models/ai_usage_daily_model.dart';
import 'package:newsreader/core/data/models/article_model.dart';
import 'package:newsreader/core/data/models/article_summary_model.dart';
import 'package:newsreader/core/data/models/daily_summary_free_usage_model.dart';
import 'package:newsreader/core/data/models/daily_summary_model.dart';
import 'package:newsreader/core/data/models/news_source_model.dart';
import 'package:newsreader/core/data/repositories/ai_usage_repository_impl.dart';
import 'package:newsreader/core/data/repositories/article_repository_impl.dart';
import 'package:newsreader/core/data/repositories/article_summary_repository_impl.dart';
import 'package:newsreader/core/data/repositories/daily_summary_free_usage_repository_impl.dart';
import 'package:newsreader/core/data/repositories/source_repository_impl.dart';
import 'package:newsreader/core/data/repositories/summary_repository_impl.dart';
import 'package:newsreader/core/domain/repositories/ai_usage_repository.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';
import 'package:newsreader/core/domain/repositories/article_summary_repository.dart';
import 'package:newsreader/core/domain/repositories/daily_summary_free_usage_repository.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';
import 'package:newsreader/core/domain/repositories/summary_repository.dart';
import 'package:newsreader/core/sharing/file_sharer.dart';
import 'package:newsreader/core/sharing/share_plus_file_sharer.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/core/subscription/superwall_subscription_status_provider.dart';
import 'package:newsreader/features/account/domain/usecases/delete_account.dart';
import 'package:newsreader/features/account/domain/usecases/export_favorites_json.dart';
import 'package:newsreader/features/account/domain/usecases/export_sources_opml.dart';
import 'package:newsreader/features/account/domain/usecases/export_user_data.dart';
import 'package:newsreader/features/archive/domain/usecases/get_archive.dart';
import 'package:newsreader/features/article_summary/domain/usecases/generate_article_summary.dart';
import 'package:newsreader/features/article_summary/presentation/cubit/article_summary_cubit.dart';
import 'package:newsreader/features/archive/presentation/cubit/archive_cubit.dart';
import 'package:newsreader/features/favorites/domain/usecases/get_favorites.dart';
import 'package:newsreader/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:newsreader/features/inbox/domain/usecases/get_inbox_articles.dart';
import 'package:newsreader/features/inbox/domain/usecases/mark_article_as_read.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/reader/domain/usecases/toggle_favorite.dart';
import 'package:newsreader/features/maintenance/domain/usecases/migrate_archived_articles.dart';
import 'package:newsreader/features/maintenance/domain/usecases/reset_local_articles.dart';
import 'package:newsreader/core/opml/opml_parser.dart';
import 'package:newsreader/core/opml/xml_opml_parser.dart';
import 'package:newsreader/core/sync/cloud_sync_client.dart';
import 'package:newsreader/core/sync/supabase_cloud_sync_client.dart';
import 'package:newsreader/features/auth/presentation/cubit/login_cubit.dart';
import 'package:newsreader/features/sources/domain/usecases/add_source.dart';
import 'package:newsreader/features/sources/domain/usecases/delete_source.dart';
import 'package:newsreader/features/sources/domain/usecases/get_source_articles.dart';
import 'package:newsreader/features/sources/domain/usecases/generate_email_feed.dart';
import 'package:newsreader/features/sources/domain/usecases/get_sources.dart';
import 'package:newsreader/features/sources/domain/usecases/import_opml.dart';
import 'package:newsreader/features/sources/domain/usecases/update_source_name.dart';
import 'package:newsreader/features/sources/presentation/cubit/sources_cubit.dart';
import 'package:newsreader/features/summaries/domain/usecases/generate_daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_articles.dart';
import 'package:newsreader/features/summaries/domain/usecases/get_daily_summaries.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';
import 'package:newsreader/features/sync/domain/usecases/clear_local_user_data.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';
import 'package:newsreader/presentation/theme/theme_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Core — abstractions
  getIt.registerLazySingleton<AuthClient>(
    () => SupabaseAuthClient(observabilityClient: getIt()),
  );
  getIt.registerLazySingleton<CloudSyncClient>(() => SupabaseCloudSyncClient());
  getIt.registerLazySingleton<HttpClient>(() => HttpPackageClient());
  getIt.registerLazySingleton<FeedParser>(() => WebfeedFeedParser());
  getIt.registerLazySingleton<FeedUrlResolver>(() => FeedUrlResolver());
  getIt.registerLazySingleton<FeedSyncTrigger>(
    () => SupabaseFeedSyncTrigger(getIt(), getIt()),
  );
  getIt.registerLazySingleton<IdGenerator>(() => const UuidIdGenerator());
  getIt.registerLazySingleton<AppNavigator>(() => const GoRouterNavigator());
  getIt.registerLazySingleton<ExternalLinkLauncher>(
    () => const UrlLauncherExternalLinkLauncher(),
  );
  getIt.registerLazySingleton<OPMLParser>(() => const XmlOpmlParser());
  getIt.registerLazySingleton<SummaryGenerator>(
    () => GeminiSummaryGenerator(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton<ArticleSummaryGenerator>(
    () => GeminiArticleSummaryGenerator(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton<MentionEnricher>(
    () => RemoteMentionEnricher(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton<EmailFeedGenerator>(
    () => SupabaseEmailFeedGenerator(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton<FileSharer>(() => SharePlusFileSharer());
  getIt.registerLazySingleton<SubscriptionStatusProvider>(
    () => SuperwallSubscriptionStatusProvider(),
  );
  getIt.registerLazySingleton<TelemetryClient>(
    () => DefaultTelemetryClient(),
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
  getIt.registerLazySingleton<ArticleSummaryLocalDataSource>(
    () => HiveArticleSummaryDatasource(
      Hive.box<ArticleSummaryModel>(AppConstants.hiveArticleSummariesBox),
    ),
  );
  getIt.registerLazySingleton<AiUsageLocalDataSource>(
    () => HiveAiUsageDatasource(
      Hive.box<AiUsageDailyModel>(AppConstants.hiveAiUsageBox),
    ),
  );
  getIt.registerLazySingleton<DailySummaryFreeUsageLocalDataSource>(
    () => HiveDailySummaryFreeUsageDatasource(
      Hive.box<DailySummaryFreeUsageModel>(
        AppConstants.hiveDailySummaryFreeUsageBox,
      ),
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
  getIt.registerLazySingleton<ArticleSummaryRepository>(
    () => ArticleSummaryRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<AiUsageRepository>(
    () => AiUsageRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton<DailySummaryFreeUsageRepository>(
    () => DailySummaryFreeUsageRepositoryImpl(getIt()),
  );

  // Use cases — Sources
  getIt.registerLazySingleton(
    () => AddSource(getIt(), getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => GenerateEmailFeed(getIt()));
  getIt.registerLazySingleton(() => DeleteSource(getIt(), getIt()));
  getIt.registerLazySingleton(() => UpdateSourceName(getIt()));
  getIt.registerLazySingleton(() => GetSources(getIt()));
  getIt.registerLazySingleton(() => GetSourceArticles(getIt()));
  getIt.registerLazySingleton(
    () => ImportOpml(getIt(), getIt(), getIt(), getIt(), getIt(), getIt()),
  );

  // Use cases — Articles
  getIt.registerLazySingleton(() => GetInboxArticles(getIt()));
  getIt.registerLazySingleton(
    () => MarkArticleAsRead(getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(
    () => ToggleFavorite(getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => GetFavorites(getIt()));
  getIt.registerLazySingleton(() => GetArchive(getIt()));

  // Use cases — Maintenance
  getIt.registerLazySingleton(() => MigrateArchivedArticles(getIt()));
  getIt.registerLazySingleton(
    () => ResetLocalArticles(
      getIt(),
      Hive.box<dynamic>(AppConstants.hiveSettingsBox),
    ),
  );

  // Use cases — Summaries
  getIt.registerLazySingleton(() => GetDailySummaries(getIt()));
  getIt.registerLazySingleton(
    () => GenerateDailySummary(getIt(), getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => ResolveSummaryArticles(getIt()));

  // Use cases — Article summary
  getIt.registerLazySingleton(
    () => GenerateArticleSummary(getIt(), getIt(), getIt(), getIt()),
  );

  // Use cases — Sync
  getIt.registerLazySingleton(
    () => SyncUserData(
      getIt(),
      getIt(),
      getIt(),
      getIt(),
      getIt(),
      getIt(),
      getIt(),
      Hive.box<dynamic>(AppConstants.hiveSettingsBox),
    ),
  );
  getIt.registerLazySingleton(
    () => ClearLocalUserData(
      getIt(),
      getIt(),
      getIt(),
      Hive.box<dynamic>(AppConstants.hiveSettingsBox),
    ),
  );

  // Use cases — Account
  getIt.registerLazySingleton(() => DeleteAccount(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton(() => ExportSourcesOpml(getIt()));
  getIt.registerLazySingleton(() => ExportFavoritesJson(getIt()));
  getIt.registerLazySingleton(() => ExportUserData(getIt(), getIt(), getIt()));

  // Presentation
  getIt.registerFactory<LoginCubit>(() => LoginCubit(getIt(), getIt()));
  getIt.registerSingleton<ThemeCubit>(
    ThemeCubit(Hive.box<dynamic>(AppConstants.hiveSettingsBox)),
  );
  getIt.registerSingleton<InboxCubit>(
    InboxCubit(getIt(), getIt(), getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerSingleton<FavoritesCubit>(FavoritesCubit(getIt()));
  getIt.registerSingleton<ArchiveCubit>(ArchiveCubit(getIt()));
  getIt.registerSingleton<SourcesCubit>(
    SourcesCubit(getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerSingleton<SummariesCubit>(
    SummariesCubit(getIt(), getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerFactory<ArticleSummaryCubit>(
    () => ArticleSummaryCubit(getIt(), getIt(), getIt()),
  );
}
