import 'package:flutter/material.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/widgets/source_icon.dart';
import 'package:newsreader/features/summaries/presentation/widgets/summary_article_row.dart';
import 'package:newsreader/l10n/app_localizations.dart';

/// Tarjeta de una fuente dentro del detalle del resumen: encabezado con
/// ícono, nombre y contador de artículos; debajo, el párrafo y una fila por
/// artículo.
class SummarySourceCard extends StatelessWidget {
  // Tonos cálidos del mockup aprobado. No salen de ColorScheme porque en
  // AppTheme `surfaceContainerHighest`/`outline` son hairlines translúcidos y
  // sobre el fondo se leen como gris. Los oscuros son el equivalente cálido
  // sobre `_darkSurface`.
  static const _lightCard = Color(0xFFFFFFFF);
  static const _lightHeader = Color(0xFFF1EDE3);
  static const _lightBorder = Color(0xFFE3DDD0);
  static const _darkHeader = Color(0xFF211F1B);
  static const _darkBorder = Color(0xFF2E2B26);

  final String title;
  final String text;

  /// `null` cuando la fuente ya no existe localmente: [SourceIcon] cae a la
  /// inicial de [title].
  final String? iconUrl;
  final List<Article> articles;

  /// Número que muestra el contador. Lo calcula quien conoce si los
  /// artículos ya se resolvieron; 0 oculta el contador.
  final int articleCount;

  const SummarySourceCard({
    super.key,
    required this.title,
    required this.text,
    required this.iconUrl,
    required this.articles,
    required this.articleCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : _lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? _darkBorder : _lightBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: isDark ? _darkHeader : _lightHeader,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    SourceIcon(iconUrl: iconUrl, name: title, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (articleCount > 0)
                      Text(
                        l10n.summaryListArticleCount(articleCount),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  if (articles.isNotEmpty) const SizedBox(height: 8),
                  for (final article in articles)
                    SummaryArticleRow(article: article),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
