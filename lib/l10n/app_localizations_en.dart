// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Reevo';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonSave => 'Save';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get inboxSyncingSources => 'Syncing sources...';

  @override
  String get inboxOfflineSyncMessage =>
      'You\'re offline. Downloaded articles are still available.';

  @override
  String inboxSourcesFailedToSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources couldn\'t sync.',
      one: '1 source couldn\'t sync.',
    );
    return '$_temp0';
  }

  @override
  String get inboxOnboardingTitle => 'Welcome to Reevo';

  @override
  String get inboxOnboardingSubtitle =>
      'Your space to read your sources outside of email.';

  @override
  String get inboxOnboardingAddFirstSourceButton => 'Add your first source';

  @override
  String get inboxUpToDateTitle => 'You\'re all caught up';

  @override
  String get inboxUpToDateSubtitle => 'Pull to refresh.';

  @override
  String get readerRemoveFavoriteTooltip => 'Remove from favorites';

  @override
  String get readerAddFavoriteTooltip => 'Add to favorites';

  @override
  String get readerOpenInBrowserTooltip => 'View in browser';

  @override
  String get readerTruncatedContentHint =>
      'This feed doesn\'t include the full article. Tap here to read it on the original site.';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptySubtitle =>
      'Open an article and tap the star to save it here.';

  @override
  String get archiveEmptyTitle => 'No read articles';

  @override
  String get archiveEmptySubtitle =>
      'Read and unread articles will be archived automatically.';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCopy => 'Copy';

  @override
  String get sourcesAddSourceTooltip => 'Add source';

  @override
  String get sourcesEmptyTitle => 'You don\'t have any sources yet';

  @override
  String get sourcesEmptySubtitle => 'Add your first source to start reading.';

  @override
  String get sourcesAddFirstSourceButton => 'Add my first source';

  @override
  String get sourcesEditNameMenuItem => 'Edit name';

  @override
  String sourcesAddedSnackbar(String name) {
    return '\"$name\" added.';
  }

  @override
  String get sourcesAddScreenTitle => 'Add source';

  @override
  String get sourcesAddInstructions =>
      'Paste the site link (or the RSS feed URL if you have it).';

  @override
  String get sourcesFeedUrlLabel => 'Feed URL';

  @override
  String get sourcesSearchingHeuristics =>
      'Searching several possible places...';

  @override
  String get sourcesOtherWaysToAdd => 'Other ways to add';

  @override
  String get sourcesImportOpmlTitle => 'Import from OPML';

  @override
  String get sourcesImportOpmlDescription =>
      'Bring your subscriptions from another feed reader.';

  @override
  String get sourcesEmailGeneratedDialogTitle => 'Address generated';

  @override
  String get sourcesEmailGeneratedDialogBody =>
      'Subscribe to the newsletter using this address. The first email may take a few minutes to arrive.';

  @override
  String get sourcesEmailCopiedSnackbar => 'Address copied.';

  @override
  String get sourcesAlreadySubscribedButton => 'I already subscribed';

  @override
  String get sourcesGenerateEmailTitle => 'Generate email address';

  @override
  String get sourcesGenerateEmailDescription =>
      'For newsletters without RSS: emails become articles.';

  @override
  String get sourcesGenerateEmailExpandedHint =>
      'We\'ll give you a unique address. Subscribe the newsletter with it and every email that arrives will appear here.';

  @override
  String get sourceDetailEmptyTitle => 'No posts';

  @override
  String get sourceDetailEmptySubtitle =>
      'There are no articles from this source yet.';

  @override
  String sourcesOpmlImportedOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources imported.',
      one: '1 source imported.',
    );
    return '$_temp0';
  }

  @override
  String sourcesOpmlImportedWithFailures(int imported, int failed) {
    String _temp0 = intl.Intl.pluralLogic(
      imported,
      locale: localeName,
      other: '$imported imported',
      one: '1 imported',
    );
    String _temp1 = intl.Intl.pluralLogic(
      failed,
      locale: localeName,
      other: '$failed failed',
      one: '1 failed',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String get sourcesImportOpmlScreenTitle => 'Import OPML';

  @override
  String get sourcesValidatingFeeds => 'Validating feeds…';

  @override
  String get sourcesImportingSources => 'Importing sources…';

  @override
  String sourcesValidatingMoreFeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Validating $count more feeds…',
      one: 'Validating 1 more feed…',
    );
    return '$_temp0';
  }

  @override
  String get sourcesImportButton => 'Import';

  @override
  String sourcesImportButtonWithCount(int count) {
    return 'Import ($count)';
  }

  @override
  String get sourcesAlreadySubscribed => 'Already subscribed';

  @override
  String get sourcesFeedValidationFailed => 'Couldn\'t validate the feed.';

  @override
  String get sourcesDeleteDialogTitle => 'Delete source';

  @override
  String sourcesDeleteDialogBody(String name) {
    return 'Delete \"$name\"? Its articles that aren\'t saved as favorites will also be deleted.';
  }

  @override
  String get sourcesEditNameDialogTitle => 'Edit name';

  @override
  String get sourcesEditNameFieldLabel => 'Name';

  @override
  String get summariesGenerating => 'Generating summary...';

  @override
  String get summariesRegenerateTodayButton => 'Regenerate today\'s summary';

  @override
  String get summariesCreateTodayButton => 'Create today\'s summary';

  @override
  String get summariesEmptyTitle => 'No summaries yet';

  @override
  String get summariesEmptySubtitle =>
      'Create today\'s summary to see what your news was about.';

  @override
  String summaryDetailTitle(String date) {
    return 'Summary for $date';
  }

  @override
  String summaryDetailArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles summarized',
      one: '1 article summarized',
    );
    return '$_temp0';
  }

  @override
  String summaryListArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$_temp0';
  }

  @override
  String get loginSubtitle => 'Sign in to continue';

  @override
  String get loginContinueWithGoogle => 'Continue with Google';

  @override
  String get loginContinueWithApple => 'Continue with Apple';

  @override
  String get accountDeleteDialogTitle => 'Delete account';

  @override
  String get accountDeleteDialogBody =>
      'This action is irreversible: your account and all your data (sources, articles, favorites, and summaries) will be deleted. This cannot be undone.';

  @override
  String get navInbox => 'Inbox';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navArchive => 'Read';

  @override
  String get navSources => 'Sources';

  @override
  String get navSummaries => 'Summaries';

  @override
  String get navSearchHintSources => 'Search by name or author...';

  @override
  String get navSearchHintArticles => 'Search by title, source or author...';

  @override
  String get navExportData => 'Export my data';

  @override
  String get navSignOut => 'Sign out';

  @override
  String commonDaysAgoShort(int count) {
    return '${count}d';
  }

  @override
  String get commonNoSearchResults => 'No results';

  @override
  String get webViewOriginalArticle => 'Original article';

  @override
  String get errorNetwork => 'No internet connection';

  @override
  String get errorTimeout => 'The request took too long';

  @override
  String get errorInvalidFeedUrl =>
      'We couldn\'t find a valid feed at this URL';

  @override
  String get errorInvalidOpmlFile => 'This file isn\'t a valid OPML file';

  @override
  String get errorDuplicateSource =>
      'You\'re already subscribed to this source';

  @override
  String get errorNotFound => 'Not found';

  @override
  String get errorFeedDiscoveryFailed =>
      'We couldn\'t detect the feed automatically. Paste the exact RSS feed URL (for example, ending in /feed or .xml).';

  @override
  String get errorNoActiveSession => 'You need an active session for this';

  @override
  String get errorAccountDeletionFailed =>
      'We couldn\'t delete your account. Please try again.';

  @override
  String get errorGoogleTokenMissing =>
      'Google didn\'t return a valid token. Please try again.';

  @override
  String get errorAppleTokenMissing =>
      'Apple didn\'t return a valid token. Please try again.';

  @override
  String get errorAuthProviderError =>
      'Something went wrong signing you in. Please try again.';

  @override
  String get errorEmptyUrl => 'Enter a valid URL';

  @override
  String get errorOpmlNoFeedsFound => 'No feeds were found in this file';

  @override
  String get errorNoArticlesToday =>
      'There are no new articles today to summarize';

  @override
  String get errorGenerationFailed => 'Something went wrong. Please try again.';

  @override
  String get errorUnknown => 'Something unexpected happened';
}
