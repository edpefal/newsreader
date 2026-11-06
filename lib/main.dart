import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/config/app_config.dart';
import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/di/injection.dart';
import 'package:newsreader/core/feature_flags/posthog_feature_flag_client.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/core/observability/default_telemetry_client.dart';
import 'package:newsreader/core/subscription/revenuecat_subscription_status_provider.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/core/data/models/ai_usage_daily_model.dart';
import 'package:newsreader/core/data/models/article_model.dart';
import 'package:newsreader/core/data/models/article_summary_model.dart';
import 'package:newsreader/core/data/models/daily_summary_model.dart';
import 'package:newsreader/core/data/models/news_source_model.dart';
import 'package:newsreader/core/data/models/user_preferences_model.dart';
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
  TelemetryClient observabilityClient,
) {
  if (isSignedIn && userId != null) {
    subscriptionStatusProvider.identify(userId);
    observabilityClient.setUserId(userId);
  } else {
    // Desvincula al usuario de RevenueCat en logout/borrado de cuenta, para
    // que la próxima cuenta que inicie sesión en este dispositivo no
    // arrastre por un instante el estado de suscripción de la anterior.
    subscriptionStatusProvider.reset();
    observabilityClient.setUserId(null);
  }
}

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Mantiene la splash nativa visible más allá del primer frame -- se quita
  // explícitamente en el postFrameCallback de más abajo, una vez que el
  // primer frame ya se pintó con datos locales, en vez de depender del
  // primer frame que Flutter dibuja mientras todavía hay I/O de red
  // pendiente (DI). Ver design.md del change
  // `speed-up-app-startup`.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 1. Initialize Hive, en paralelo con Supabase (2): ninguno depende del
  // resultado del otro.
  await Future.wait([_initHive(), _initSupabase()]);

  // 3. Setup dependency injection
  await setupDependencies();

  // 3.5. Configurar RevenueCat. `configure` no usa la red y el estado inicial
  // de suscripción sale de la caché del SDK sin esperarla, así que no retrasa
  // el arranque. Sin llave (Android) no configura nada. Ver
  // openspec/changes/migrate-to-revenuecat/design.md (D6, D10).
  await getIt<RevenueCatSubscriptionStatusProvider>().init();

  // 4. Cargar datos locales (Hive) para el primer render -- no depende del
  // sync con la nube, que corre después del primer frame (ver
  // `_runDeferredStartupWork`).
  getIt<InboxCubit>().loadArticles();
  getIt<FavoritesCubit>().loadFavorites();
  getIt<ArchiveCubit>().loadArchive();
  getIt<SourcesCubit>().loadSources();
  getIt<SummariesCubit>().loadSummaries();

  await DefaultTelemetryClient.init(
    dsn: AppConfig.sentryDsn,
    isProd: AppConfig.isProd,
    appRunner: () {
      runApp(App(
        themeCubit: getIt(),
        inboxCubit: getIt(),
        favoritesCubit: getIt(),
        archiveCubit: getIt(),
        sourcesCubit: getIt(),
        summariesCubit: getIt(),
      ));
      // Recién acá, con el primer frame ya encolado, se libera la splash
      // nativa -- `addPostFrameCallback` garantiza que ese frame ya se
      // renderizó antes de removerla, evitando el parpadeo de volver a la
      // splash si se quitara antes de tiempo.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
      // No se espera (`unawaited`): el resto del arranque (analytics, sync
      // con la nube) corre en segundo plano sin bloquear la UI ya visible.
      unawaited(_runDeferredStartupWork());
    },
  );
}

Future<void> _initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapter(NewsSourceModelAdapter());
  Hive.registerAdapter(ArticleModelAdapter());
  Hive.registerAdapter(DailySummaryModelAdapter());
  Hive.registerAdapter(ArticleSummaryModelAdapter());
  Hive.registerAdapter(AiUsageDailyModelAdapter());
  Hive.registerAdapter(UserPreferencesModelAdapter());
  await Hive.openBox<NewsSourceModel>(AppConstants.hiveSourcesBox);
  await Hive.openBox<ArticleModel>(AppConstants.hiveArticlesBox);
  await Hive.openBox<dynamic>(AppConstants.hiveSettingsBox);
  await Hive.openBox<DailySummaryModel>(AppConstants.hiveSummariesBox);
  await Hive.openBox<ArticleSummaryModel>(
    AppConstants.hiveArticleSummariesBox,
  );
  await Hive.openBox<AiUsageDailyModel>(AppConstants.hiveAiUsageBox);
  await Hive.openBox<UserPreferencesModel>(
    AppConstants.hiveUserPreferencesBox,
  );
}

Future<void> _initSupabase() async {
  // Usado por AuthClient; el resto de la app sigue llamando a las edge
  // functions vía HttpClient, sin el SDK de Supabase.
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );
  debugPrint('Ambiente: ${AppConfig.isProd ? 'prod' : 'dev'}');
}

/// Trabajo de arranque que no es necesario para pintar el primer frame:
/// analytics, identificación de usuario, migraciones one-time y sync con la
/// nube. Corre después de `runApp()`, sin bloquear la UI ya visible -- ver
/// design.md del change `speed-up-app-startup`.
Future<void> _runDeferredStartupWork() async {
  try {
    // Inicializar PostHog antes de cualquier `setUserId`: a diferencia de
    // Sentry, que ya está corriendo (envuelve este mismo `appRunner`),
    // PostHog necesita haber terminado su `setup` antes de que se lo pueda
    // identificar.
    await DefaultTelemetryClient.initPostHog(
      AppConfig.postHogApiKey,
      isProd: AppConfig.isProd,
      onFeatureFlags: getIt<PostHogFeatureFlagClient>().notifyChanged,
    );

    // Identificar al usuario ante RevenueCat con el mismo user_id de
    // Supabase Auth, tanto en la sesión ya activa al abrir la app como en
    // cada login posterior (LoginCubit usa el mismo AuthClient, así que esta
    // suscripción cubre ambos casos sin duplicar la llamada en cada flujo).
    final authClient = getIt<AuthClient>();
    final subscriptionStatusProvider = getIt<SubscriptionStatusProvider>();
    final observabilityClient = getIt<TelemetryClient>();
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

    // One-time migration: remove auto-archived articles from previous behavior
    await getIt<MigrateArchivedArticles>().execute();

    // One-time migration (centralize-feed-fetching): limpia los artículos
    // locales con ids viejos (generados en el cliente) antes de que el sync
    // de abajo pueda traer los nuevos (ids generados en el servidor).
    // No-op después de la primera vez que corre en cada dispositivo.
    await getIt<ResetLocalArticles>().execute();

    // Sync user data with the cloud (no-op si no hay sesión activa). El
    // Inbox ya se pintó con lo que había en Hive local (ver `main`); acá se
    // pone al día en segundo plano.
    await getIt<SyncUserData>().execute();

    // Recargar las pantallas con lo que trajo el sync. El Inbox reusa su
    // mecanismo existente de "sincronizando en background" (mismo que usa
    // al volver del background o tras login) para no pisar de golpe lo que
    // el usuario ya está viendo.
    unawaited(getIt<InboxCubit>().syncInBackground());
    getIt<FavoritesCubit>().loadFavorites();
    getIt<ArchiveCubit>().loadArchive();
    getIt<SourcesCubit>().loadSources();
    getIt<SummariesCubit>().loadSummaries();
  } catch (e, st) {
    // Silencioso a propósito: es trabajo de arranque en segundo plano, no
    // una acción pedida explícitamente por el usuario -- un fallo acá no
    // debe crashear la app ni bloquear la UI ya visible.
    getIt<TelemetryClient>().captureException(e, st);
  }
}
