class AppConstants {
  AppConstants._();

  static const int articleTruncatedThreshold = 500;
  static const int cleanupDays = 30;
  static const Duration feedFetchTimeout = Duration(seconds: 10);
  static const Duration summaryGenerationTimeout = Duration(seconds: 45);
  static const String settingsThemeModeKey = 'theme_mode';
  static const String settingsLastSyncedAtKey = 'last_synced_at';
  // v3 (no v2): la v2 limpiaba los artículos locales pero no reseteaba el
  // cursor de sincronización, dejando invisibles para siempre los
  // artículos remotos con updatedAt anterior al último sync. v3 fuerza que
  // la migración corra de nuevo en dispositivos que ya pasaron por v2.
  static const String settingsArticlesResetV3Key = 'articles_reset_v3';
  static const String hiveSourcesBox = 'sources';
  static const String hiveArticlesBox = 'articles';
  static const String hiveSettingsBox = 'settings';
  static const String hiveSummariesBox = 'summaries';
}
