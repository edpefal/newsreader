import 'package:newsreader/core/ai/article_summary_generator.dart';
import 'package:newsreader/core/ai/mention_enricher.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/article_summary.dart';
import 'package:newsreader/core/domain/repositories/ai_usage_repository.dart';
import 'package:newsreader/core/domain/repositories/article_summary_repository.dart';
import 'package:newsreader/core/utils/feed_content_checker.dart';
import 'package:newsreader/core/utils/html_to_linked_text.dart';

/// Orquesta la generación (o el lookup) del resumen+menciones de un
/// artículo -- ver capabilities `article-summaries`/`article-mentions`.
class GenerateArticleSummary {
  final ArticleSummaryRepository _articleSummaryRepository;
  final ArticleSummaryGenerator _articleSummaryGenerator;
  final MentionEnricher _mentionEnricher;
  final AiUsageRepository _aiUsageRepository;

  const GenerateArticleSummary(
    this._articleSummaryRepository,
    this._articleSummaryGenerator,
    this._mentionEnricher,
    this._aiUsageRepository,
  );

  /// Mismo criterio que `GenerateDailySummary` para elegir la fuente del
  /// contenido (texto de `contentHtml` cuando el artículo no está
  /// truncado, `excerpt` si lo está o está vacío), pero preservando los
  /// links del artículo como markdown (`HtmlToLinkedText`, no
  /// `HtmlToPlainText`) para que la API de IA pueda detectar menciones de
  /// tipo artículo -- ver capability `article-mentions`. `daily-summaries`
  /// sigue usando `HtmlToPlainText` sin cambios.
  static String _articleContentFor(Article article) {
    if (!FeedContentChecker.isTruncated(article.contentHtml)) {
      return HtmlToLinkedText.convert(
        article.contentHtml!,
        baseUrl: article.articleUrl,
      );
    }
    return article.excerpt ?? '';
  }

  /// Si el enriquecimiento entero falla, una mención de tipo artículo
  /// SHALL igual quedar con su `link` (la URL ya la extrajo la API de IA
  /// directamente del artículo, no depende del enriquecimiento) -- ver
  /// capability `article-mentions`, requirement "siempre tappable".
  static List<EnrichedMention> _asUnenriched(List<RawMention> mentions) =>
      mentions
          .map((m) => (
                type: m.type,
                name: m.name,
                imageUrl: null,
                link: m.type == MentionType.article ? m.url : null,
              ))
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
    // Solo se registra acá (generación fresca), nunca en el early return de
    // arriba -- reabrir un resumen ya persistido no descuenta del límite
    // diario, ver capability `article-summaries`.
    await _aiUsageRepository.recordLocalUsage();
    return summary;
  }
}
