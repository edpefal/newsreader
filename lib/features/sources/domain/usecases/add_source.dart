import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/feed/feed_data.dart';
import 'package:newsreader/core/feed/feed_parser.dart';
import 'package:newsreader/core/feed/feed_url_resolver.dart';
import 'package:newsreader/core/network/http_client.dart';
import 'package:newsreader/core/utils/id_generator.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';

class AddSource {
  final SourceRepository _sourceRepository;
  final HttpClient _httpClient;
  final FeedParser _feedParser;
  final IdGenerator _idGenerator;
  final FeedUrlResolver _feedUrlResolver;

  const AddSource(
    this._sourceRepository,
    this._httpClient,
    this._feedParser,
    this._idGenerator,
    this._feedUrlResolver,
  );

  Future<NewsSource> execute(String feedUrl) async {
    final normalizedUrl = feedUrl.trim();

    final resolved = await _resolveFeed(normalizedUrl);

    if (await _sourceRepository.sourceExists(resolved.feedUrl)) {
      throw const DuplicateSourceException();
    }

    final source = NewsSource(
      id: _idGenerator.generate(),
      name: resolved.feedData.title,
      feedUrl: resolved.feedUrl,
      author: resolved.feedData.author,
      iconUrl: resolved.feedData.iconUrl,
      addedAt: DateTime.now(),
    );

    return _sourceRepository.addSource(source);
  }

  Future<({String feedUrl, FeedData feedData})> _resolveFeed(
    String rawUrl,
  ) async {
    final candidates = _feedUrlResolver.candidatesFor(rawUrl);

    for (final candidate in candidates) {
      try {
        final xmlContent = await _httpClient.get(candidate);
        final feedData = _feedParser.parse(xmlContent);
        return (feedUrl: candidate, feedData: feedData);
      } on ParseException {
        continue;
      }
    }

    throw const FeedDiscoveryException();
  }
}
