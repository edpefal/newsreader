import 'package:newsreader/core/config/app_config.dart';

class AppConstants {
  AppConstants._();

  static const int articleTruncatedThreshold = 500;
  static const int cleanupDays = 30;
  static const Duration feedFetchTimeout = Duration(seconds: 10);
  static const Duration summaryGenerationTimeout = Duration(seconds: 45);
  // Espejo del límite aplicado del lado del servidor en
  // `check_and_record_ai_usage` (ver migración `add_ai_usage_daily` y
  // `summarize-articles/index.ts`) -- solo para mostrar el medidor, la
  // autoridad real es el backend.
  static const int aiUsageDailyWordLimit = 30000;
  static const String settingsThemeModeKey = 'theme_mode';
  // Gatea la migración de una sola vez desde el formato binario previo
  // (solo 'light'/'dark') al de tres opciones (se agrega 'system'). Es una
  // key aparte del valor en sí para no confundir una preferencia legada
  // con una elección explícita de 'light'/'dark' hecha ya usando la UI
  // nueva -- ver ThemeCubit.
  static const String settingsThemeModeMigratedKey = 'theme_mode_migrated_v2';
  static const String settingsLastSyncedAtKey = 'last_synced_at';
  // v3 (no v2): la v2 limpiaba los artículos locales pero no reseteaba el
  // cursor de sincronización, dejando invisibles para siempre los
  // artículos remotos con updatedAt anterior al último sync. v3 fuerza que
  // la migración corra de nuevo en dispositivos que ya pasaron por v2.
  static const String settingsArticlesResetV3Key = 'articles_reset_v3';

  // Nombres de box separados por ambiente: sin esto, un dispositivo usado
  // para probar dev y prod comparte el mismo caché local de Hive, y sigue
  // mostrando fuentes/artículos de un ambiente aunque la app esté corriendo
  // contra el otro (el pull incremental de SyncUserData nunca borra
  // localmente lo que el otro backend no tiene). Prod mantiene los nombres
  // originales para no requerir migración en instalaciones existentes.
  static String get hiveSourcesBox =>
      AppConfig.isProd ? 'sources' : 'sources_dev';
  static String get hiveArticlesBox =>
      AppConfig.isProd ? 'articles' : 'articles_dev';
  static String get hiveSettingsBox =>
      AppConfig.isProd ? 'settings' : 'settings_dev';
  static String get hiveSummariesBox =>
      AppConfig.isProd ? 'summaries' : 'summaries_dev';
  static String get hiveArticleSummariesBox =>
      AppConfig.isProd ? 'article_summaries' : 'article_summaries_dev';
}
