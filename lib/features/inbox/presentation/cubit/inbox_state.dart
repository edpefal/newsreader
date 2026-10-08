part of 'inbox_cubit.dart';

sealed class InboxState extends Equatable {
  const InboxState();
}

final class InboxLoading extends InboxState {
  final bool isSyncing;

  const InboxLoading({this.isSyncing = false});

  @override
  List<Object?> get props => [isSyncing];
}

final class InboxLoaded extends InboxState {
  final List<Article> articles;
  final bool hasSources;
  final String? readArticleId;
  final bool isSyncingInBackground;
  final String searchQuery;

  /// Artículo actualmente resaltado en la columna central porque es la
  /// selección abierta en el panel de detalle (layout de dos paneles). A
  /// diferencia de `readArticleId` (señal transitoria para animar una
  /// salida puntual), este campo persiste mientras el artículo sigue
  /// siendo la selección abierta -- ver `InboxCubit.selectArticle` /
  /// `closeOpenArticle`.
  final String? openArticleId;

  /// Resumen diario de hoy que se muestra como tarjeta sobre la lista (ver
  /// capability `inbox-daily-summary-card`), o `null` si no hay ninguno.
  final DailySummary? pendingSummary;

  /// Resumen cuyo detalle está abierto en el panel derecho (layout de dos
  /// paneles). Mientras coincida con `pendingSummary.id`, la tarjeta se
  /// conserva (resaltada) aunque el resumen ya esté descartado. Mutuamente
  /// excluyente con `openArticleId`.
  final String? openSummaryId;

  const InboxLoaded(
    this.articles, {
    required this.hasSources,
    this.readArticleId,
    this.isSyncingInBackground = false,
    this.searchQuery = '',
    this.openArticleId,
    this.pendingSummary,
    this.openSummaryId,
  });

  List<Article> get visibleArticles => searchQuery.isEmpty
      ? articles
      : articles.where((a) => articleMatchesQuery(a, searchQuery)).toList();

  @override
  List<Object?> get props => [
    articles,
    hasSources,
    readArticleId,
    isSyncingInBackground,
    searchQuery,
    openArticleId,
    pendingSummary,
    openSummaryId,
  ];
}
