import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/feed/feed_parser.dart';
import 'package:newsreader/core/network/http_client.dart';
import 'package:newsreader/core/utils/id_generator.dart';
import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/domain/repositories/article_repository.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';

class SyncResult {
  final int synced;
  final List<String> failedSourceIds;
  final bool isNetworkError;

  const SyncResult({
    required this.synced,
    required this.failedSourceIds,
    this.isNetworkError = false,
  });
}

class SyncSources {
  final SourceRepository _sourceRepository;
  final ArticleRepository _articleRepository;
  final HttpClient _httpClient;
  final FeedParser _feedParser;
  final IdGenerator _idGenerator;

  const SyncSources(
    this._sourceRepository,
    this._articleRepository,
    this._httpClient,
    this._feedParser,
    this._idGenerator,
  );

  Future<SyncResult> execute() async {
    final sources = await _sourceRepository.getSources();
    int synced = 0;
    final failedSourceIds = <String>[];
    bool networkErrorOccurred = false;

    await Future.wait(
      sources.map((source) async {
        try {
          final xml = await _httpClient.get(source.feedUrl);
          final feedData = _feedParser.parse(xml);

          for (final item in feedData.items) {
            final url = item.link;
            if (url == null || url.isEmpty) continue;
            if (await _articleRepository.articleExists(url)) continue;

            final article = Article(
              id: _idGenerator.generate(),
              sourceId: source.id,
              sourceName: source.name,
              sourceIconUrl: source.iconUrl,
              title: item.title,
              author: item.author ?? source.author,
              publishedAt: item.publishedAt ?? DateTime.now(),
              contentHtml: item.contentHtml,
              excerpt: item.excerpt,
              articleUrl: url,
            );

            await _articleRepository.saveArticle(article);
            synced++;
          }

          await _sourceRepository.updateSource(
            source.copyWith(lastSyncedAt: DateTime.now(), hasError: false),
          );
        } catch (e) {
          failedSourceIds.add(source.id);
          if (e is NetworkException || e is TimeoutException) {
            networkErrorOccurred = true;
          }
          await _sourceRepository.updateSource(source.copyWith(hasError: true));
        }
      }),
    );

    return SyncResult(
      synced: synced,
      failedSourceIds: failedSourceIds,
      isNetworkError: networkErrorOccurred,
    );
  }
}
