// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Reevo';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonToday => 'Aujourd\'hui';

  @override
  String get commonYesterday => 'Hier';

  @override
  String get inboxSyncingSources => 'Synchronisation des sources...';

  @override
  String get inboxOfflineSyncMessage =>
      'Tu es hors ligne. Les articles téléchargés restent disponibles.';

  @override
  String inboxSourcesFailedToSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources n\'ont pas pu être synchronisées.',
      one: '1 source n\'a pas pu être synchronisée.',
    );
    return '$_temp0';
  }

  @override
  String get inboxOnboardingTitle => 'Bienvenue sur Reevo';

  @override
  String get inboxOnboardingSubtitle =>
      'Ton espace pour lire tes sources en dehors de l\'e-mail.';

  @override
  String get inboxOnboardingAddFirstSourceButton => 'Ajoute ta première source';

  @override
  String get inboxUpToDateTitle => 'Tu es à jour';

  @override
  String get inboxUpToDateSubtitle => 'Tire pour actualiser.';

  @override
  String get readerRemoveFavoriteTooltip => 'Retirer des favoris';

  @override
  String get readerAddFavoriteTooltip => 'Ajouter aux favoris';

  @override
  String get readerOpenInBrowserTooltip => 'Voir dans le navigateur';

  @override
  String get readerTruncatedContentHint =>
      'Ce flux n\'inclut pas l\'article complet. Touche ici pour le lire sur le site d\'origine.';

  @override
  String get favoritesEmptyTitle => 'Aucun favori pour l\'instant';

  @override
  String get favoritesEmptySubtitle =>
      'Ouvre un article et touche l\'étoile pour l\'enregistrer ici.';

  @override
  String get archiveEmptyTitle => 'Aucun article lu';

  @override
  String get archiveEmptySubtitle =>
      'Les articles lus et non lus seront archivés automatiquement.';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonCopy => 'Copier';

  @override
  String get sourcesAddSourceTooltip => 'Ajouter une source';

  @override
  String get sourcesEmptyTitle => 'Tu n\'as pas encore de source';

  @override
  String get sourcesEmptySubtitle =>
      'Ajoute ta première source pour commencer à lire.';

  @override
  String get sourcesAddFirstSourceButton => 'Ajoute ma première source';

  @override
  String get sourcesEditNameMenuItem => 'Modifier le nom';

  @override
  String sourcesAddedSnackbar(String name) {
    return '\"$name\" ajouté.';
  }

  @override
  String get sourcesAddScreenTitle => 'Ajouter une source';

  @override
  String get sourcesAddInstructions =>
      'Colle le lien du site (ou l\'URL du flux RSS si tu l\'as).';

  @override
  String get sourcesFeedUrlLabel => 'URL du flux';

  @override
  String get sourcesSearchingHeuristics =>
      'Recherche à plusieurs endroits possibles...';

  @override
  String get sourcesOtherWaysToAdd => 'Autres façons d\'ajouter';

  @override
  String get sourcesImportOpmlTitle => 'Importer depuis OPML';

  @override
  String get sourcesImportOpmlDescription =>
      'Récupère tes abonnements depuis un autre lecteur de flux.';

  @override
  String get sourcesEmailGeneratedDialogTitle => 'Adresse générée';

  @override
  String get sourcesEmailGeneratedDialogBody =>
      'Abonne-toi à la newsletter avec cette adresse. Le premier e-mail peut prendre quelques minutes pour arriver.';

  @override
  String get sourcesEmailCopiedSnackbar => 'Adresse copiée.';

  @override
  String get sourcesAlreadySubscribedButton => 'Je suis déjà abonné';

  @override
  String get sourcesGenerateEmailTitle => 'Générer une adresse e-mail';

  @override
  String get sourcesGenerateEmailDescription =>
      'Pour les newsletters sans RSS : les e-mails deviennent des articles.';

  @override
  String get sourcesGenerateEmailExpandedHint =>
      'On te donne une adresse unique. Abonne la newsletter avec elle et chaque e-mail qui arrive apparaîtra ici.';

  @override
  String get sourceDetailEmptyTitle => 'Aucune publication';

  @override
  String get sourceDetailEmptySubtitle =>
      'Il n\'y a pas encore d\'articles de cette source.';

  @override
  String sourcesOpmlImportedOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources importées.',
      one: '1 source importée.',
    );
    return '$_temp0';
  }

  @override
  String sourcesOpmlImportedWithFailures(int imported, int failed) {
    String _temp0 = intl.Intl.pluralLogic(
      imported,
      locale: localeName,
      other: '$imported importées',
      one: '1 importée',
    );
    String _temp1 = intl.Intl.pluralLogic(
      failed,
      locale: localeName,
      other: '$failed échouées',
      one: '1 échouée',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String get sourcesImportOpmlScreenTitle => 'Importer OPML';

  @override
  String get sourcesValidatingFeeds => 'Validation des flux…';

  @override
  String get sourcesImportingSources => 'Importation des sources…';

  @override
  String sourcesValidatingMoreFeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Validation de $count flux supplémentaires…',
      one: 'Validation d\'1 flux supplémentaire…',
    );
    return '$_temp0';
  }

  @override
  String get sourcesImportButton => 'Importer';

  @override
  String sourcesImportButtonWithCount(int count) {
    return 'Importer ($count)';
  }

  @override
  String get sourcesAlreadySubscribed => 'Déjà abonné';

  @override
  String get sourcesFeedValidationFailed => 'Impossible de valider le flux.';

  @override
  String get sourcesDeleteDialogTitle => 'Supprimer la source';

  @override
  String sourcesDeleteDialogBody(String name) {
    return 'Supprimer \"$name\" ? Ses articles qui ne sont pas enregistrés comme favoris seront aussi supprimés.';
  }

  @override
  String get sourcesEditNameDialogTitle => 'Modifier le nom';

  @override
  String get sourcesEditNameFieldLabel => 'Nom';

  @override
  String get summariesGenerating => 'Génération du résumé...';

  @override
  String get summariesRegenerateTodayButton => 'Régénérer le résumé du jour';

  @override
  String get summariesCreateTodayButton => 'Créer le résumé du jour';

  @override
  String get summariesEmptyTitle => 'Aucun résumé pour l\'instant';

  @override
  String get summariesEmptySubtitle =>
      'Crée le résumé du jour pour voir de quoi parlaient tes actualités.';

  @override
  String summaryDetailTitle(String date) {
    return 'Résumé du $date';
  }

  @override
  String summaryDetailArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles résumés',
      one: '1 article résumé',
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
  String get loginSubtitle => 'Connecte-toi pour continuer';

  @override
  String get loginContinueWithGoogle => 'Continuer avec Google';

  @override
  String get loginContinueWithApple => 'Continuer avec Apple';

  @override
  String get accountDeleteDialogTitle => 'Supprimer le compte';

  @override
  String get accountDeleteDialogBody =>
      'Cette action est irréversible : ton compte et toutes tes données (sources, articles, favoris et résumés) seront supprimés. Cette action ne peut pas être annulée.';

  @override
  String get navInbox => 'Inbox';

  @override
  String get navFavorites => 'Favoris';

  @override
  String get navArchive => 'Lus';

  @override
  String get navSources => 'Sources';

  @override
  String get navSummaries => 'Résumés';

  @override
  String get navSearchHintSources => 'Rechercher par nom ou auteur...';

  @override
  String get navSearchHintArticles =>
      'Rechercher par titre, source ou auteur...';

  @override
  String get navExportData => 'Exporter mes données';

  @override
  String get navSignOut => 'Se déconnecter';

  @override
  String commonDaysAgoShort(int count) {
    return '$count j';
  }

  @override
  String get commonNoSearchResults => 'Aucun résultat';

  @override
  String get webViewOriginalArticle => 'Article original';
}
