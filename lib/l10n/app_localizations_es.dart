// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Reevo';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonToday => 'Hoy';

  @override
  String get commonYesterday => 'Ayer';

  @override
  String get inboxSyncingSources => 'Sincronizando fuentes...';

  @override
  String get inboxOfflineSyncMessage =>
      'Sin conexión. Los artículos descargados siguen disponibles.';

  @override
  String inboxSourcesFailedToSync(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fuentes no pudieron sincronizarse.',
      one: '1 fuente no pudo sincronizarse.',
    );
    return '$_temp0';
  }

  @override
  String get inboxOnboardingTitle => 'Bienvenido a Reevo';

  @override
  String get inboxOnboardingSubtitle =>
      'Tu espacio para leer tus fuentes fuera del email.';

  @override
  String get inboxOnboardingAddFirstSourceButton => 'Agrega tu primera fuente';

  @override
  String get inboxUpToDateTitle => 'Estás al día';

  @override
  String get inboxUpToDateSubtitle => 'Desliza para actualizar.';

  @override
  String get readerRemoveFavoriteTooltip => 'Quitar de favoritos';

  @override
  String get readerAddFavoriteTooltip => 'Agregar a favoritos';

  @override
  String get readerOpenInBrowserTooltip => 'Ver en el navegador';

  @override
  String get readerTruncatedContentHint =>
      'Este feed no incluye el artículo completo. Toca aquí para leerlo en el sitio original.';

  @override
  String get favoritesEmptyTitle => 'Sin favoritos aún';

  @override
  String get favoritesEmptySubtitle =>
      'Abre un artículo y toca la estrella para guardarlo aquí.';

  @override
  String get archiveEmptyTitle => 'Sin artículos leídos';

  @override
  String get archiveEmptySubtitle =>
      'Los artículos leídos y no leídos se archivarán automáticamente.';

  @override
  String get commonAdd => 'Agregar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonCopy => 'Copiar';

  @override
  String get sourcesAddSourceTooltip => 'Agregar fuente';

  @override
  String get sourcesEmptyTitle => 'Aún no tienes fuentes';

  @override
  String get sourcesEmptySubtitle =>
      'Agrega tu primera fuente para empezar a leer.';

  @override
  String get sourcesAddFirstSourceButton => 'Agrega mi primera fuente';

  @override
  String get sourcesEditNameMenuItem => 'Editar nombre';

  @override
  String sourcesAddedSnackbar(String name) {
    return '\"$name\" agregado.';
  }

  @override
  String get sourcesAddScreenTitle => 'Agregar fuente';

  @override
  String get sourcesAddInstructions =>
      'Pega el link del sitio (o la URL del feed RSS si la tienes).';

  @override
  String get sourcesFeedUrlLabel => 'URL del feed';

  @override
  String get sourcesSearchingHeuristics =>
      'Buscando en varios lugares posibles...';

  @override
  String get sourcesOtherWaysToAdd => 'Otras formas de agregar';

  @override
  String get sourcesImportOpmlTitle => 'Importar desde OPML';

  @override
  String get sourcesImportOpmlDescription =>
      'Trae tus suscripciones desde otro lector de feeds.';

  @override
  String get sourcesEmailGeneratedDialogTitle => 'Dirección generada';

  @override
  String get sourcesEmailGeneratedDialogBody =>
      'Suscribe el newsletter usando esta dirección. El primer correo puede tardar unos minutos en aparecer.';

  @override
  String get sourcesEmailCopiedSnackbar => 'Dirección copiada.';

  @override
  String get sourcesAlreadySubscribedButton => 'Ya me suscribí';

  @override
  String get sourcesGenerateEmailTitle => 'Generar dirección de email';

  @override
  String get sourcesGenerateEmailDescription =>
      'Para newsletters sin RSS: los correos se convierten en artículos.';

  @override
  String get sourcesGenerateEmailExpandedHint =>
      'Te damos una dirección única. Suscribe el newsletter con ella y cada correo que llegue aparecerá aquí.';

  @override
  String get sourceDetailEmptyTitle => 'Sin publicaciones';

  @override
  String get sourceDetailEmptySubtitle =>
      'Aún no hay artículos de esta fuente.';

  @override
  String sourcesOpmlImportedOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fuentes importadas.',
      one: '1 fuente importada.',
    );
    return '$_temp0';
  }

  @override
  String sourcesOpmlImportedWithFailures(int imported, int failed) {
    String _temp0 = intl.Intl.pluralLogic(
      imported,
      locale: localeName,
      other: '$imported importadas',
      one: '1 importada',
    );
    String _temp1 = intl.Intl.pluralLogic(
      failed,
      locale: localeName,
      other: '$failed fallidas',
      one: '1 fallida',
    );
    return '$_temp0, $_temp1.';
  }

  @override
  String get sourcesImportOpmlScreenTitle => 'Importar OPML';

  @override
  String get sourcesValidatingFeeds => 'Validando feeds…';

  @override
  String get sourcesImportingSources => 'Importando fuentes…';

  @override
  String sourcesValidatingMoreFeeds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Validando $count feeds más…',
      one: 'Validando 1 feed más…',
    );
    return '$_temp0';
  }

  @override
  String get sourcesImportButton => 'Importar';

  @override
  String sourcesImportButtonWithCount(int count) {
    return 'Importar ($count)';
  }

  @override
  String get sourcesAlreadySubscribed => 'Ya suscrito';

  @override
  String get sourcesFeedValidationFailed => 'No se pudo validar el feed.';

  @override
  String get sourcesDeleteDialogTitle => 'Eliminar fuente';

  @override
  String sourcesDeleteDialogBody(String name) {
    return '¿Eliminar \"$name\"? También se eliminarán sus artículos no guardados como favoritos.';
  }

  @override
  String get sourcesEditNameDialogTitle => 'Editar nombre';

  @override
  String get sourcesEditNameFieldLabel => 'Nombre';

  @override
  String get summariesGenerating => 'Generando resumen...';

  @override
  String get summariesRegenerateTodayButton => 'Regenerar resumen de hoy';

  @override
  String get summariesCreateTodayButton => 'Crear resumen de hoy';

  @override
  String get summariesEmptyTitle => 'Sin resúmenes todavía';

  @override
  String get summariesEmptySubtitle =>
      'Crea el resumen de hoy para ver de qué trataron tus noticias.';

  @override
  String summaryDetailTitle(String date) {
    return 'Resumen del $date';
  }

  @override
  String summaryDetailArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos resumidos',
      one: '1 artículo resumido',
    );
    return '$_temp0';
  }

  @override
  String summaryListArticleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos',
      one: '1 artículo',
    );
    return '$_temp0';
  }

  @override
  String get loginSubtitle => 'Inicia sesión para continuar';

  @override
  String get loginContinueWithGoogle => 'Continuar con Google';

  @override
  String get loginContinueWithApple => 'Continuar con Apple';

  @override
  String get accountDeleteDialogTitle => 'Eliminar cuenta';

  @override
  String get accountDeleteDialogBody =>
      'Esta acción es irreversible: se eliminarán tu cuenta y todos tus datos (fuentes, artículos, favoritos y resúmenes). No se puede deshacer.';

  @override
  String get navInbox => 'Inbox';

  @override
  String get navFavorites => 'Favoritos';

  @override
  String get navArchive => 'Leídos';

  @override
  String get navSources => 'Fuentes';

  @override
  String get navSummaries => 'Resúmenes';

  @override
  String get navSearchHintSources => 'Buscar por nombre o autor...';

  @override
  String get navSearchHintArticles => 'Buscar por título, fuente o autor...';

  @override
  String get navExportData => 'Exportar mis datos';

  @override
  String get navSignOut => 'Cerrar sesión';

  @override
  String commonDaysAgoShort(int count) {
    return '${count}d';
  }

  @override
  String get commonNoSearchResults => 'Sin resultados';

  @override
  String get webViewOriginalArticle => 'Artículo original';
}
