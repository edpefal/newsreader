import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/l10n/app_localizations.dart';

/// Resuelve un [AppErrorCode] al texto correspondiente en el idioma activo
/// de la app. Único lugar donde vive este mapeo — los widgets que muestran
/// un error llaman `code.localize(AppLocalizations.of(context))` en vez de
/// repetir un `switch` en cada pantalla.
extension AppErrorCodeL10n on AppErrorCode {
  String localize(AppLocalizations l10n) {
    switch (this) {
      case AppErrorCode.network:
        return l10n.errorNetwork;
      case AppErrorCode.timeout:
        return l10n.errorTimeout;
      case AppErrorCode.invalidFeedUrl:
        return l10n.errorInvalidFeedUrl;
      case AppErrorCode.invalidOpmlFile:
        return l10n.errorInvalidOpmlFile;
      case AppErrorCode.duplicateSource:
        return l10n.errorDuplicateSource;
      case AppErrorCode.notFound:
        return l10n.errorNotFound;
      case AppErrorCode.feedDiscoveryFailed:
        return l10n.errorFeedDiscoveryFailed;
      case AppErrorCode.noActiveSession:
        return l10n.errorNoActiveSession;
      case AppErrorCode.accountDeletionFailed:
        return l10n.errorAccountDeletionFailed;
      case AppErrorCode.googleTokenMissing:
        return l10n.errorGoogleTokenMissing;
      case AppErrorCode.appleTokenMissing:
        return l10n.errorAppleTokenMissing;
      case AppErrorCode.authProviderError:
        return l10n.errorAuthProviderError;
      case AppErrorCode.emptyUrl:
        return l10n.errorEmptyUrl;
      case AppErrorCode.opmlNoFeedsFound:
        return l10n.errorOpmlNoFeedsFound;
      case AppErrorCode.opmlFeedValidationFailed:
        // Reusa la clave ya agregada en el Change 1 (mismo texto, ya
        // usado como fallback en `_ErrorFeedTile` para este caso).
        return l10n.sourcesFeedValidationFailed;
      case AppErrorCode.noArticlesToday:
        return l10n.errorNoArticlesToday;
      case AppErrorCode.generationFailed:
        return l10n.errorGenerationFailed;
      case AppErrorCode.aiUsageLimitReached:
        return l10n.errorAiUsageLimitReached;
      case AppErrorCode.contentBlocked:
        return l10n.errorContentBlocked;
      case AppErrorCode.subscriptionRequired:
        return l10n.errorSubscriptionRequired;
      case AppErrorCode.dailySummaryAlreadyGenerated:
        return l10n.errorDailySummaryAlreadyGenerated;
      case AppErrorCode.articleTooLongToSummarize:
        return l10n.errorArticleTooLongToSummarize;
      case AppErrorCode.unknown:
        return l10n.errorUnknown;
    }
  }
}
