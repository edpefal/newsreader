import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/config/app_config.dart';
import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/di/injection.dart';
import 'package:newsreader/core/observability/observability_client.dart';
import 'package:newsreader/core/observability/sentry_observability_client.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/core/data/models/article_model.dart';
import 'package:newsreader/core/data/models/article_summary_model.dart';
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

/// Identifica/desvincula al usuario ante los proveedores de suscripción y
/// observabilidad en respuesta a `authClient.authStateChanges`. Extraído de
/// `main()` para poder testearlo sin levantar toda la app.
void handleAuthStateChange(
  bool isSignedIn,
  String? userId,
  SubscriptionStatusProvider subscriptionStatusProvider,
  ObservabilityClient observabilityClient,
) {
  if (isSignedIn && userId != null) {
    subscriptionStatusProvider.identify(userId);
    observabilityClient.setUserId(userId);
  } else {
    // Desvincula al usuario de Superwall en logout/borrado de cuenta, para
    // que la próxima cuenta que inicie sesión en este dispositivo no
    // arrastre por un instante el estado de suscripción de la anterior.
    subscriptionStatusProvider.reset();
    observabilityClient.setUserId(null);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(NewsSourceModelAdapter());
  Hive.registerAdapter(ArticleModelAdapter());
  Hive.registerAdapter(DailySummaryModelAdapter());
  Hive.registerAdapter(ArticleSummaryModelAdapter());
  await Hive.openBox<NewsSourceModel>(AppConstants.hiveSourcesBox);
  await Hive.openBox<ArticleModel>(AppConstants.hiveArticlesBox);
  await Hive.openBox<dynamic>(AppConstants.hiveSettingsBox);
  await Hive.openBox<DailySummaryModel>(AppConstants.hiveSummariesBox);
  await Hive.openBox<ArticleSummaryModel>(
    AppConstants.hiveArticleSummariesBox,
  );

  // 2. Initialize Supabase (usado por AuthClient; el resto de la app sigue
  // llamando a las edge functions vía HttpClient, sin el SDK de Supabase).
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );
  debugPrint('Ambiente: ${AppConfig.isProd ? 'prod' : 'dev'}');

  // 2.5. Configurar Superwall. Cada plataforma tiene su propia public API
  // key (no son secretas -- son client-side, análogas a una publishable
  // key). Android todavía no tiene la suya: falta agregar esa plataforma en
  // el dashboard de Superwall (ver
  // openspec/changes/gate-daily-summary-behind-superwall-paywall/proposal.md).
  final superwallApiKey = Platform.isIOS
      ? 'pk_JmLJquLYADH1dqyDv8aH1'
      : 'SUPERWALL_API_KEY_PLACEHOLDER_ANDROID';
  // El lado nativo recién registra el event channel de
  // `subscriptionStatus` dentro del handler de `configure`, así que hay que
  // esperar a que termine antes de armar el DI: si
  // `SuperwallSubscriptionStatusProvider` se suscribe al stream antes de que
  // el nativo lo registre, tira MissingPluginException.
  final superwallConfigured = Completer<void>();
  Superwall.configure(
    superwallApiKey,
    completion: () => superwallConfigured.complete(),
  );
  await superwallConfigured.future;

  // 3. Setup dependency injection
  await setupDependencies();

  // 3.5. Identificar al usuario ante Superwall con el mismo user_id de
  // Supabase Auth, tanto en la sesión ya activa al abrir la app como en
  // cada login posterior (LoginCubit usa el mismo AuthClient, así que esta
  // suscripción cubre ambos casos sin duplicar la llamada en cada flujo).
  final authClient = getIt<AuthClient>();
  final subscriptionStatusProvider = getIt<SubscriptionStatusProvider>();
  final observabilityClient = getIt<ObservabilityClient>();
  if (authClient.isSignedIn && authClient.currentUserId != null) {
    await subscriptionStatusProvider.identify(authClient.currentUserId!);
    observabilityClient.setUserId(authClient.currentUserId);
  }
  authClient.authStateChanges.listen((isSignedIn) {
    handleAuthStateChange(
      isSignedIn,
      authClient.currentUserId,
      subscriptionStatusProvider,
      observabilityClient,
    );
  });

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

  await SentryObservabilityClient.init(
    dsn: AppConfig.sentryDsn,
    isProd: AppConfig.isProd,
    appRunner: () => runApp(App(
      themeCubit: getIt(),
      inboxCubit: getIt(),
      favoritesCubit: getIt(),
      archiveCubit: getIt(),
      sourcesCubit: getIt(),
      summariesCubit: getIt(),
    )),
  );
}
