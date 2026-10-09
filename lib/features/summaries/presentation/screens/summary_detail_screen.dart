import 'package:flutter/material.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/domain/entities/summary_source_block.dart';
import 'package:newsreader/core/utils/localized_date_formatter.dart';
import 'package:newsreader/features/summaries/domain/summary_block_title.dart';
import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_articles.dart';
import 'package:newsreader/features/summaries/domain/usecases/resolve_summary_sources.dart';
import 'package:newsreader/features/summaries/presentation/widgets/summary_block_parser.dart';
import 'package:newsreader/features/summaries/presentation/widgets/summary_header.dart';
import 'package:newsreader/features/summaries/presentation/widgets/summary_plain_block.dart';
import 'package:newsreader/features/summaries/presentation/widgets/summary_source_card.dart';
import 'package:newsreader/l10n/app_localizations.dart';

/// Ancho máximo del contenido; mismo criterio que el lector (~680pt), para no
/// estirar las tarjetas de borde a borde en iPad.
const double _kMaxContentWidth = 680;

class SummaryDetailScreen extends StatefulWidget {
  final DailySummary summary;
  final ResolveSummaryArticles resolveSummaryArticles;
  final ResolveSummarySources resolveSummarySources;

  /// Se invoca una vez, al mostrarse el detalle (también al restaurar o
  /// abrir la ruta directamente). Lo usan las rutas para quitar el resumen
  /// de hoy del Inbox sin que este feature conozca al de Inbox.
  final VoidCallback? onOpened;

  const SummaryDetailScreen({
    super.key,
    required this.summary,
    required this.resolveSummaryArticles,
    required this.resolveSummarySources,
    this.onOpened,
  });

  @override
  State<SummaryDetailScreen> createState() => _SummaryDetailScreenState();
}

class _SummaryDetailScreenState extends State<SummaryDetailScreen> {
  Map<String, Article> _resolvedArticles = const {};
  Map<String, NewsSource> _resolvedSources = const {};
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _resolveReferences();
    // Fuera del build: el callback persiste y puede emitir estados en otros
    // Cubits que se reconstruyen en este mismo frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onOpened?.call();
    });
  }

  /// Resuelve artículos y fuentes en paralelo y aplica ambos en un solo
  /// `setState`, para que la tarjeta no pinte primero la inicial y luego
  /// salte al ícono real.
  Future<void> _resolveReferences() async {
    final blocks = widget.summary.sourceBlocks;
    if (blocks == null || blocks.isEmpty) return;

    final articleIds = blocks.expand((b) => b.articleIds).toList();
    final sourceIds = blocks.map((b) => b.sourceId).toList();
    final results = await Future.wait([
      widget.resolveSummaryArticles.execute(articleIds),
      widget.resolveSummarySources.execute(sourceIds),
    ]);
    if (!mounted) return;
    setState(() {
      _resolvedArticles = results[0] as Map<String, Article>;
      _resolvedSources = results[1] as Map<String, NewsSource>;
      _resolved = true;
    });
  }

  SummarySourceBlock? _findSourceBlock(String title) {
    final blocks = widget.summary.sourceBlocks;
    if (blocks == null) return null;
    for (final block in blocks) {
      if (block.sourceName.trim() == title) return block;
    }
    return null;
  }

  /// Empareja primero por igualdad exacta con el título crudo, así una
  /// fuente cuyo nombre real empieza con `Fuente:`/`Source:` sigue
  /// funcionando; solo si no hay match reintenta sin la etiqueta que el
  /// modelo a veces copia al encabezado (ver `normalizeSummaryBlockTitle`).
  /// Devuelve también el título a mostrar: el crudo si hubo match exacto, el
  /// normalizado en cualquier otro caso.
  ({String title, SummarySourceBlock? sourceBlock}) _resolveBlockTitle(
    String rawTitle,
  ) {
    final exact = _findSourceBlock(rawTitle);
    if (exact != null) return (title: rawTitle, sourceBlock: exact);
    final normalized = normalizeSummaryBlockTitle(rawTitle);
    return (title: normalized, sourceBlock: _findSourceBlock(normalized));
  }

  Widget _buildBlock(ParsedSummaryBlock block) {
    final rawTitle = block.title;
    if (rawTitle == null) return SummaryPlainBlock(text: block.text);

    final resolved = _resolveBlockTitle(rawTitle);
    final sourceBlock = resolved.sourceBlock;
    if (sourceBlock == null) {
      return SummaryPlainBlock(title: resolved.title, text: block.text);
    }

    final articles = sourceBlock.articleIds
        .map((id) => _resolvedArticles[id])
        .whereType<Article>()
        .toList();
    return SummarySourceCard(
      title: resolved.title,
      text: block.text,
      iconUrl: _resolvedSources[sourceBlock.sourceId]?.iconUrl,
      articles: articles,
      // Antes de resolver se usa el conteo guardado para que el contador no
      // parpadee de 0 a N; después, solo lo que realmente se muestra.
      articleCount: _resolved ? articles.length : sourceBlock.articleIds.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocks = parseSummaryBlocks(widget.summary.content);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.summaryDetailTitle(
            LocalizedDateFormatter.longDate(context, widget.summary.date),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SummaryHeader(
                  summary: widget.summary,
                  sources: _resolvedSources,
                ),
                const SizedBox(height: 16),
                for (final block in blocks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildBlock(block),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
