import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// The application name, shown in the OS task switcher and window title.
  ///
  /// In en, this message translates to:
  /// **'Reevo'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @inboxSyncingSources.
  ///
  /// In en, this message translates to:
  /// **'Syncing sources...'**
  String get inboxSyncingSources;

  /// No description provided for @inboxOfflineSyncMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Downloaded articles are still available.'**
  String get inboxOfflineSyncMessage;

  /// No description provided for @inboxSourcesFailedToSync.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 source couldn\'t sync.} other{{count} sources couldn\'t sync.}}'**
  String inboxSourcesFailedToSync(int count);

  /// No description provided for @inboxOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Reevo'**
  String get inboxOnboardingTitle;

  /// No description provided for @inboxOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your space to read your sources outside of email.'**
  String get inboxOnboardingSubtitle;

  /// No description provided for @inboxOnboardingAddFirstSourceButton.
  ///
  /// In en, this message translates to:
  /// **'Add your first source'**
  String get inboxOnboardingAddFirstSourceButton;

  /// No description provided for @inboxUpToDateTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get inboxUpToDateTitle;

  /// No description provided for @inboxUpToDateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh.'**
  String get inboxUpToDateSubtitle;

  /// No description provided for @commonSelectArticleTitle.
  ///
  /// In en, this message translates to:
  /// **'Select an article'**
  String get commonSelectArticleTitle;

  /// No description provided for @commonSelectArticleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an article from the list to read it here.'**
  String get commonSelectArticleSubtitle;

  /// No description provided for @readerRemoveFavoriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get readerRemoveFavoriteTooltip;

  /// No description provided for @readerAddFavoriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get readerAddFavoriteTooltip;

  /// No description provided for @readerOpenInBrowserTooltip.
  ///
  /// In en, this message translates to:
  /// **'View in browser'**
  String get readerOpenInBrowserTooltip;

  /// No description provided for @readerTruncatedContentHint.
  ///
  /// In en, this message translates to:
  /// **'This feed doesn\'t include the full article. Tap here to read it on the original site.'**
  String get readerTruncatedContentHint;

  /// No description provided for @articleSummaryButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Summarize article'**
  String get articleSummaryButtonTooltip;

  /// No description provided for @articleSummarySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get articleSummarySheetTitle;

  /// No description provided for @articleSummaryMentionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Mentioned in this article'**
  String get articleSummaryMentionsTitle;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open an article and tap the star to save it here.'**
  String get favoritesEmptySubtitle;

  /// No description provided for @archiveEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No read articles'**
  String get archiveEmptyTitle;

  /// No description provided for @archiveEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read and unread articles will be archived automatically.'**
  String get archiveEmptySubtitle;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @sourcesAddSourceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get sourcesAddSourceTooltip;

  /// No description provided for @sourcesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any sources yet'**
  String get sourcesEmptyTitle;

  /// No description provided for @sourcesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first source to start reading.'**
  String get sourcesEmptySubtitle;

  /// No description provided for @sourcesAddFirstSourceButton.
  ///
  /// In en, this message translates to:
  /// **'Add my first source'**
  String get sourcesAddFirstSourceButton;

  /// No description provided for @sourcesEditNameMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get sourcesEditNameMenuItem;

  /// No description provided for @sourcesAddedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" added.'**
  String sourcesAddedSnackbar(String name);

  /// No description provided for @sourcesAddScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get sourcesAddScreenTitle;

  /// No description provided for @sourcesAddInstructions.
  ///
  /// In en, this message translates to:
  /// **'Paste the site link (or the RSS feed URL if you have it).'**
  String get sourcesAddInstructions;

  /// No description provided for @sourcesFeedUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Feed URL'**
  String get sourcesFeedUrlLabel;

  /// No description provided for @sourcesSearchingHeuristics.
  ///
  /// In en, this message translates to:
  /// **'Searching several possible places...'**
  String get sourcesSearchingHeuristics;

  /// No description provided for @sourcesOtherWaysToAdd.
  ///
  /// In en, this message translates to:
  /// **'Other ways to add'**
  String get sourcesOtherWaysToAdd;

  /// No description provided for @sourcesImportOpmlTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from OPML'**
  String get sourcesImportOpmlTitle;

  /// No description provided for @sourcesImportOpmlDescription.
  ///
  /// In en, this message translates to:
  /// **'Bring your subscriptions from another feed reader.'**
  String get sourcesImportOpmlDescription;

  /// No description provided for @sourcesEmailGeneratedDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Address generated'**
  String get sourcesEmailGeneratedDialogTitle;

  /// No description provided for @sourcesEmailGeneratedDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to the newsletter using this address. The first email may take a few minutes to arrive.'**
  String get sourcesEmailGeneratedDialogBody;

  /// No description provided for @sourcesEmailCopiedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Address copied.'**
  String get sourcesEmailCopiedSnackbar;

  /// No description provided for @sourcesAlreadySubscribedButton.
  ///
  /// In en, this message translates to:
  /// **'I already subscribed'**
  String get sourcesAlreadySubscribedButton;

  /// No description provided for @sourcesGenerateEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate email address'**
  String get sourcesGenerateEmailTitle;

  /// No description provided for @sourcesGenerateEmailDescription.
  ///
  /// In en, this message translates to:
  /// **'For newsletters without RSS: emails become articles.'**
  String get sourcesGenerateEmailDescription;

  /// No description provided for @sourcesGenerateEmailExpandedHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll give you a unique address. Subscribe the newsletter with it and every email that arrives will appear here.'**
  String get sourcesGenerateEmailExpandedHint;

  /// No description provided for @sourceDetailEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No posts'**
  String get sourceDetailEmptyTitle;

  /// No description provided for @sourceDetailEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'There are no articles from this source yet.'**
  String get sourceDetailEmptySubtitle;

  /// No description provided for @sourcesSelectSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a source'**
  String get sourcesSelectSourceTitle;

  /// No description provided for @sourcesSelectSourceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a source from the list to see its articles.'**
  String get sourcesSelectSourceSubtitle;

  /// No description provided for @sourcesOpmlImportedOnly.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 source imported.} other{{count} sources imported.}}'**
  String sourcesOpmlImportedOnly(int count);

  /// No description provided for @sourcesOpmlImportedWithFailures.
  ///
  /// In en, this message translates to:
  /// **'{imported, plural, =1{1 imported} other{{imported} imported}}, {failed, plural, =1{1 failed} other{{failed} failed}}.'**
  String sourcesOpmlImportedWithFailures(int imported, int failed);

  /// No description provided for @sourcesImportOpmlScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Import OPML'**
  String get sourcesImportOpmlScreenTitle;

  /// No description provided for @sourcesValidatingFeeds.
  ///
  /// In en, this message translates to:
  /// **'Validating feeds…'**
  String get sourcesValidatingFeeds;

  /// No description provided for @sourcesImportingSources.
  ///
  /// In en, this message translates to:
  /// **'Importing sources…'**
  String get sourcesImportingSources;

  /// No description provided for @sourcesValidatingMoreFeeds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Validating 1 more feed…} other{Validating {count} more feeds…}}'**
  String sourcesValidatingMoreFeeds(int count);

  /// No description provided for @sourcesImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get sourcesImportButton;

  /// No description provided for @sourcesImportButtonWithCount.
  ///
  /// In en, this message translates to:
  /// **'Import ({count})'**
  String sourcesImportButtonWithCount(int count);

  /// No description provided for @sourcesAlreadySubscribed.
  ///
  /// In en, this message translates to:
  /// **'Already subscribed'**
  String get sourcesAlreadySubscribed;

  /// No description provided for @sourcesFeedValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t validate the feed.'**
  String get sourcesFeedValidationFailed;

  /// No description provided for @sourcesDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete source'**
  String get sourcesDeleteDialogTitle;

  /// No description provided for @sourcesDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? Its articles that aren\'t saved as favorites will also be deleted.'**
  String sourcesDeleteDialogBody(String name);

  /// No description provided for @sourcesEditNameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get sourcesEditNameDialogTitle;

  /// No description provided for @sourcesEditNameFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sourcesEditNameFieldLabel;

  /// No description provided for @summariesGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating summary...'**
  String get summariesGenerating;

  /// No description provided for @summariesRegenerateTodayButton.
  ///
  /// In en, this message translates to:
  /// **'Regenerate today\'s summary'**
  String get summariesRegenerateTodayButton;

  /// No description provided for @summariesCreateTodayButton.
  ///
  /// In en, this message translates to:
  /// **'Create today\'s summary'**
  String get summariesCreateTodayButton;

  /// No description provided for @summariesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No summaries yet'**
  String get summariesEmptyTitle;

  /// No description provided for @summariesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create today\'s summary to see what your news was about.'**
  String get summariesEmptySubtitle;

  /// No description provided for @summaryDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary for {date}'**
  String summaryDetailTitle(String date);

  /// No description provided for @summaryDetailArticleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 article summarized} other{{count} articles summarized}}'**
  String summaryDetailArticleCount(int count);

  /// No description provided for @summaryListArticleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 article} other{{count} articles}}'**
  String summaryListArticleCount(int count);

  /// No description provided for @summariesSelectSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a summary'**
  String get summariesSelectSummaryTitle;

  /// No description provided for @summariesSelectSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a daily summary from the list to read it here.'**
  String get summariesSelectSummarySubtitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get loginSubtitle;

  /// No description provided for @loginContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginContinueWithGoogle;

  /// No description provided for @loginContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get loginContinueWithApple;

  /// No description provided for @accountDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDeleteDialogTitle;

  /// No description provided for @accountDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible: your account and all your data (sources, articles, favorites, and summaries) will be deleted. This cannot be undone.'**
  String get accountDeleteDialogBody;

  /// No description provided for @navInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get navInbox;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navArchive.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get navArchive;

  /// No description provided for @navSources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get navSources;

  /// No description provided for @navSummaries.
  ///
  /// In en, this message translates to:
  /// **'Summaries'**
  String get navSummaries;

  /// No description provided for @navSearchHintSources.
  ///
  /// In en, this message translates to:
  /// **'Search by name or author...'**
  String get navSearchHintSources;

  /// No description provided for @navSearchHintArticles.
  ///
  /// In en, this message translates to:
  /// **'Search by title, source or author...'**
  String get navSearchHintArticles;

  /// No description provided for @navExportData.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get navExportData;

  /// No description provided for @navSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get navSignOut;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreenTitle;

  /// No description provided for @settingsThemeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsThemeSectionTitle;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsAccountSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountSectionTitle;

  /// No description provided for @commonDaysAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String commonDaysAgoShort(int count);

  /// No description provided for @commonNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get commonNoSearchResults;

  /// No description provided for @webViewOriginalArticle.
  ///
  /// In en, this message translates to:
  /// **'Original article'**
  String get webViewOriginalArticle;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request took too long'**
  String get errorTimeout;

  /// No description provided for @errorInvalidFeedUrl.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find a valid feed at this URL'**
  String get errorInvalidFeedUrl;

  /// No description provided for @errorInvalidOpmlFile.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t a valid OPML file'**
  String get errorInvalidOpmlFile;

  /// No description provided for @errorDuplicateSource.
  ///
  /// In en, this message translates to:
  /// **'You\'re already subscribed to this source'**
  String get errorDuplicateSource;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get errorNotFound;

  /// No description provided for @errorFeedDiscoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t detect the feed automatically. Paste the exact RSS feed URL (for example, ending in /feed or .xml).'**
  String get errorFeedDiscoveryFailed;

  /// No description provided for @errorNoActiveSession.
  ///
  /// In en, this message translates to:
  /// **'You need an active session for this'**
  String get errorNoActiveSession;

  /// No description provided for @errorAccountDeletionFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t delete your account. Please try again.'**
  String get errorAccountDeletionFailed;

  /// No description provided for @errorGoogleTokenMissing.
  ///
  /// In en, this message translates to:
  /// **'Google didn\'t return a valid token. Please try again.'**
  String get errorGoogleTokenMissing;

  /// No description provided for @errorAppleTokenMissing.
  ///
  /// In en, this message translates to:
  /// **'Apple didn\'t return a valid token. Please try again.'**
  String get errorAppleTokenMissing;

  /// No description provided for @errorAuthProviderError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong signing you in. Please try again.'**
  String get errorAuthProviderError;

  /// No description provided for @errorEmptyUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid URL'**
  String get errorEmptyUrl;

  /// No description provided for @errorOpmlNoFeedsFound.
  ///
  /// In en, this message translates to:
  /// **'No feeds were found in this file'**
  String get errorOpmlNoFeedsFound;

  /// No description provided for @errorNoArticlesToday.
  ///
  /// In en, this message translates to:
  /// **'There are no new articles today to summarize'**
  String get errorNoArticlesToday;

  /// No description provided for @errorGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGenerationFailed;

  /// No description provided for @errorAiUsageLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached today\'s AI usage limit. Try again tomorrow.'**
  String get errorAiUsageLimitReached;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something unexpected happened'**
  String get errorUnknown;

  /// No description provided for @summariesUsageMeter.
  ///
  /// In en, this message translates to:
  /// **'{used} / {limit} words used today'**
  String summariesUsageMeter(int used, int limit);

  /// No description provided for @summariesRegenerateConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Regenerate anyway?'**
  String get summariesRegenerateConfirmTitle;

  /// No description provided for @summariesRegenerateConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'No new articles have arrived since the last summary. Do you want to regenerate it anyway?'**
  String get summariesRegenerateConfirmBody;

  /// No description provided for @summariesRegenerateConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Regenerate anyway'**
  String get summariesRegenerateConfirmButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
