part of 'article_summary_cubit.dart';

sealed class ArticleSummaryState extends Equatable {
  /// Resúmenes restantes hoy según el último `AiUsageStatus` conocido, o
  /// `null` mientras todavía no se consultó. Se muestra siempre en el
  /// bottom sheet -- ver Requirement: Indicador de uso restante.
  final int? remainingToday;

  const ArticleSummaryState({this.remainingToday});
}

final class ArticleSummaryLoading extends ArticleSummaryState {
  const ArticleSummaryLoading({super.remainingToday});

  @override
  List<Object?> get props => [remainingToday];
}

final class ArticleSummaryLoaded extends ArticleSummaryState {
  final ArticleSummary summary;

  const ArticleSummaryLoaded(this.summary, {super.remainingToday});

  @override
  List<Object?> get props => [summary, remainingToday];
}

final class ArticleSummaryError extends ArticleSummaryState {
  final AppErrorCode code;

  const ArticleSummaryError(this.code, {super.remainingToday});

  @override
  List<Object?> get props => [code, remainingToday];
}

/// Se alcanzó el límite diario de resúmenes -- estado propio, no una
/// variante de [ArticleSummaryError]: conceptualmente no es una falla (es
/// un tope esperado y alcanzable por diseño), así que el bottom sheet lo
/// renderiza con superficie/tono neutro en vez del bloque rojo de error.
/// Ver design.md, decisión 6.
///
/// [dailyLimit] es el límite vigente al momento del rechazo (25 con
/// suscripción activa, 2 sin ella, ver capability `ai-usage-budget`), para
/// que el copy muestre el número correcto en vez de uno fijo.
final class ArticleSummaryLimitReached extends ArticleSummaryState {
  final int dailyLimit;

  const ArticleSummaryLimitReached({required this.dailyLimit})
      : super(remainingToday: 0);

  @override
  List<Object?> get props => [dailyLimit];
}
