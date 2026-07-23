class AppConstants {
  AppConstants._();

  static const int articleTruncatedThreshold = 500;
  static const int cleanupDays = 30;
  static const Duration feedFetchTimeout = Duration(seconds: 10);
  static const Duration summaryGenerationTimeout = Duration(seconds: 45);
  static const String settingsThemeModeKey = 'theme_mode';
  static const String hiveSourcesBox = 'sources';
  static const String hiveArticlesBox = 'articles';
  static const String hiveSettingsBox = 'settings';
  static const String hiveSummariesBox = 'summaries';
}
