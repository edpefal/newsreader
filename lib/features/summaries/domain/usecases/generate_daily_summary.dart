import 'package:newsreader/core/ai/summary_generator.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/entities/summary_source_block.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';
import 'package:newsreader/core/domain/repositories/summary_repository.dart';
import 'package:newsreader/core/utils/date_key.dart';
import 'package:newsreader/core/utils/feed_content_checker.dart';
import 'package:newsreader/core/utils/html_to_plain_text.dart';

/// Lanzada al intentar generar un resumen sin artículos del inbox de hoy.
class NoArticlesTodayException implements Exception {
  const NoArticlesTodayException();
}

/// Lanzada al intentar generar un resumen cuando ya existe uno para hoy --
/// el resumen diario permite como máximo una generación exitosa por día, sin
/// regenerar (ver capability `daily-summaries`).
class DailySummaryAlreadyGeneratedException implements Exception {
  const DailySummaryAlreadyGeneratedException();
}

class GenerateDailySummary {
  final ArticleRepository _articleRepository;
  final SummaryGenerator _summaryGenerator;
  final SummaryRepository _summaryRepository;

  const GenerateDailySummary(
    this._articleRepository,
    this._summaryGenerator,
    this._summaryRepository,
  );

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();
    return localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day;
  }

  Future<List<Article>> _todayInboxArticles() async {
    final inbox = await _articleRepository.getInboxArticles();
    return inbox.where((a) => _isToday(a.publishedAt)).toList();
  }

  Future<int> countTodayArticles() async => (await _todayInboxArticles()).length;

  /// `true` cuando ya existe un `DailySummary` para hoy -- el resumen diario
  /// permite como máximo una generación exitosa por día, sin regenerar.
  Future<bool> hasGeneratedToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return await _summaryRepository.getByDate(today) != null;
  }

  /// Usa el texto completo de `contentHtml` cuando el artículo no está
  /// truncado (mismo criterio que decide el modo lector vs WebView); si
  /// está truncado o vacío, cae a `excerpt` como antes.
  static String _articleContentFor(Article article) {
    if (!FeedContentChecker.isTruncated(article.contentHtml)) {
      return HtmlToPlainText.convert(article.contentHtml!);
    }
    return article.excerpt ?? '';
  }

  /// Agrupa los artículos de hoy por fuente, preservando el orden de
  /// primera aparición — misma agrupación que ya se arma implícitamente al
  /// construir el request al backend, pero persistida para poder linkear
  /// cada bloque del resumen a sus artículos de origen.
  static List<SummarySourceBlock> _sourceBlocksFor(List<Article> articles) {
    final bySourceId = <String, SummarySourceBlock>{};
    for (final article in articles) {
      final existing = bySourceId[article.sourceId];
      if (existing == null) {
        bySourceId[article.sourceId] = SummarySourceBlock(
          sourceId: article.sourceId,
          sourceName: article.sourceName,
          articleIds: [article.id],
        );
      } else {
        existing.articleIds.add(article.id);
      }
    }
    return bySourceId.values.toList();
  }

  Future<DailySummary> execute({required String language}) async {
    if (await hasGeneratedToday()) {
      throw const DailySummaryAlreadyGeneratedException();
    }

    final todayArticles = await _todayInboxArticles();
    if (todayArticles.isEmpty) {
      throw const NoArticlesTodayException();
    }

    // Una sola llamada con todas las fuentes: el backend organiza el
    // resumen por feed en el prompt (ver supabase/functions/summarize-articles).
    // Se prefirió a N llamadas (una por fuente) por la cuota muy ajustada
    // del free tier de Gemini (20 requests/día).
    final content = await _summaryGenerator.summarize(
      todayArticles
          .map((a) => (
                title: a.title,
                excerpt: _articleContentFor(a),
                sourceName: a.sourceName,
              ))
          .toList(),
      language: language,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final summary = DailySummary(
      id: dateKey(today),
      date: today,
      content: content,
      articleCount: todayArticles.length,
      createdAt: now,
      sourceBlocks: _sourceBlocksFor(todayArticles),
    );

    await _summaryRepository.save(summary);
    return summary;
  }
}
