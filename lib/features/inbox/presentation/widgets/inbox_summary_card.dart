import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/theme/reevo_accent.dart';
import 'package:newsreader/l10n/app_localizations.dart';

/// Tarjeta destacada del resumen diario de hoy, al inicio del Inbox. Se
/// descarta deslizándola de derecha a izquierda (o con la acción semántica
/// "Descartar"); tocarla abre el detalle del resumen.
class InboxSummaryCard extends StatelessWidget {
  static const int _maxAvatars = 3;
  static const double _avatarSize = 28;
  static const double _avatarOverlap = 10;

  final DailySummary summary;

  /// `true` mientras su detalle está abierto en el panel derecho (layout de
  /// dos paneles): borde de 2px y CTA "Abierto".
  final bool isSelected;
  final VoidCallback onTap;

  /// Se invoca al terminar el swipe o al activar la acción semántica.
  final VoidCallback onDismissed;

  const InboxSummaryCard({
    super.key,
    required this.summary,
    required this.onTap,
    required this.onDismissed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fill =
        theme.extension<ReevoAccent>()?.unreadFavoriteAccent ??
        theme.colorScheme.primary;
    // Mayor contraste sobre el óxido de cada tema: papel en claro, superficie
    // oscura en oscuro (ambos son `surface` del esquema).
    final foreground = theme.colorScheme.surface;

    final blocks = summary.sourceBlocks;
    final hasSources = blocks != null && blocks.isNotEmpty;
    final countText = hasSources
        ? '${l10n.inboxSummaryCardCountOnly(summary.articleCount)} · '
              '${l10n.inboxSummaryCardSources(blocks.length)}'
        : l10n.inboxSummaryCardCountOnly(summary.articleCount);
    final ctaText = isSelected
        ? l10n.inboxSummaryCardOpen
        : l10n.inboxSummaryCardCta;

    final card = Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.onSurface, width: 2)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.inboxSummaryCardTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      countText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                    if (hasSources) ...[
                      const SizedBox(height: 12),
                      _SourceAvatars(
                        names: [for (final b in blocks) b.sourceName],
                        maxAvatars: _maxAvatars,
                        size: _avatarSize,
                        overlap: _avatarOverlap,
                        fill: fill,
                        foreground: foreground,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ctaText,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 18, color: foreground),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      label: '${l10n.inboxSummaryCardTitle}, $countText, $ctaText',
      onTap: onTap,
      customSemanticsActions: {
        CustomSemanticsAction(label: l10n.inboxSummaryCardDismiss): onDismissed,
      },
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Dismissible(
          key: ValueKey('inbox-summary-card-${summary.id}'),
          direction: DismissDirection.endToStart,
          background: const _SwipeDismissBackground(),
          onDismissed: (_) => onDismissed(),
          child: card,
        ),
      ),
    );
  }
}

class _SourceAvatars extends StatelessWidget {
  final List<String> names;
  final int maxAvatars;
  final double size;
  final double overlap;
  final Color fill;
  final Color foreground;

  const _SourceAvatars({
    required this.names,
    required this.maxAvatars,
    required this.size,
    required this.overlap,
    required this.fill,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final shown = names.take(maxAvatars).toList();
    final extra = names.length - shown.length;
    final step = size - overlap;
    final stackWidth = size + step * (shown.length - 1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: stackWidth,
          height: size,
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(
                  left: i * step,
                  child: _Avatar(
                    name: shown[i],
                    size: size,
                    ringColor: fill,
                    background: foreground.withValues(alpha: 0.25),
                    foreground: foreground,
                  ),
                ),
            ],
          ),
        ),
        if (extra > 0) ...[
          const SizedBox(width: 8),
          Text(
            '+$extra',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  final Color ringColor;
  final Color background;
  final Color foreground;

  const _Avatar({
    required this.name,
    required this.size,
    required this.ringColor,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: Border.all(color: ringColor, width: 2),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

/// Fondo del swipe de descarte: distinto del teal de "leído" de los
/// artículos, con ícono de cerrar.
class _SwipeDismissBackground extends StatelessWidget {
  const _SwipeDismissBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Icon(Icons.close, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
