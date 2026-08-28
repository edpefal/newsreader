import 'package:newsreader/core/ai/article_summary_generator.dart';
import 'package:newsreader/core/ai/mention_enricher.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/article_summary.dart';
import 'package:newsreader/core/domain/repositories/article_summary_repository.dart';
import 'package:newsreader/core/utils/feed_content_checker.dart';
import 'package:newsreader/core/utils/html_to_plain_text.dart';

/// Orquesta la generación (o el lookup) del resumen+menciones de un
/// artículo -- ver capabilities `article-summaries`/`article-mentions`.
class GenerateArticleSummary {
  final ArticleSummaryRepository _articleSummaryRepository;
  final ArticleSummaryGenerator _articleSummaryGenerator;
  final MentionEnricher _mentionEnricher;

  const GenerateArticleSummary(
    this._articleSummaryRepository,
    this._articleSummaryGenerator,
    this._mentionEnricher,
  );

  /// Mismo criterio que `GenerateDailySummary`: texto plano de
  /// `contentHtml` cuando el artículo no está truncado, `excerpt` si lo
  /// está o está vacío.
  static String _articleContentFor(Article article) {
    if (!FeedContentChecker.isTruncated(article.contentHtml)) {
      return HtmlToPlainText.convert(article.contentHtml!);
    }
    return article.excerpt ?? '';
  }

  static List<EnrichedMention> _asUnenriched(List<RawMention> mentions) =>
      mentions
          .map((m) => (type: m.type, name: m.name, imageUrl: null, link: null))
          .toList();

  /// Si ya existe un resumen persistido para [article], lo devuelve directo
  /// sin invocar a la API de IA ni al enriquecimiento. Si no existe, genera,
  /// enriquece (mejor esfuerzo -- una falla de enriquecimiento no bloquea
  /// persistir el resumen, ver design.md) y persiste antes de devolver.
  Future<ArticleSummary> execute(
    Article article, {
    required String language,
  }) async {
    final existing = await _articleSummaryRepository.getByArticleId(
      article.id,
    );
    if (existing != null) return existing;

    final result = await _articleSummaryGenerator.summarizeArticle(
      article.title,
      _articleContentFor(article),
      language: language,
    );

    List<EnrichedMention> mentions;
    try {
      mentions = await _mentionEnricher.enrich(result.mentions);
    } catch (_) {
      mentions = _asUnenriched(result.mentions);
    }

    final summary = ArticleSummary(
      articleId: article.id,
      summary: result.summary,
      mentions: mentions,
      createdAt: DateTime.now(),
    );
    await _articleSummaryRepository.save(summary);
    return summary;
  }
}
