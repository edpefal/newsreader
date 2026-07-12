import 'package:newsreader/core/ai/summary_generator.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';
import 'package:newsreader/core/domain/repositories/summary_repository.dart';
import 'package:newsreader/core/utils/date_key.dart';

/// Lanzada al intentar generar un resumen sin artículos del inbox de hoy.
class NoArticlesTodayException implements Exception {
  const NoArticlesTodayException();
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
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Future<List<Article>> _todayInboxArticles() async {
    final inbox = await _articleRepository.getInboxArticles();
    return inbox.where((a) => _isToday(a.publishedAt)).toList();
  }

  Future<int> countTodayArticles() async => (await _todayInboxArticles()).length;

  Future<DailySummary> execute() async {
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
                excerpt: a.excerpt ?? '',
                sourceName: a.sourceName,
              ))
          .toList(),
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final summary = DailySummary(
      id: dateKey(today),
      date: today,
      content: content,
      articleCount: todayArticles.length,
      createdAt: now,
    );

    await _summaryRepository.save(summary);
    return summary;
  }
}
