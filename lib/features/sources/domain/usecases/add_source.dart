import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/feed/feed_parser.dart';
import 'package:newsreader/core/network/http_client.dart';
import 'package:newsreader/core/utils/id_generator.dart';
import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';

class AddSource {
  final SourceRepository _sourceRepository;
  final HttpClient _httpClient;
  final FeedParser _feedParser;
  final IdGenerator _idGenerator;

  const AddSource(
    this._sourceRepository,
    this._httpClient,
    this._feedParser,
    this._idGenerator,
  );

  Future<NewsSource> execute(String feedUrl) async {
    final normalizedUrl = feedUrl.trim();

    if (await _sourceRepository.sourceExists(normalizedUrl)) {
      throw const DuplicateSourceException();
    }

    final xmlContent = await _httpClient.get(normalizedUrl);
    final feedData = _feedParser.parse(xmlContent);

    final source = NewsSource(
      id: _idGenerator.generate(),
      name: feedData.title,
      feedUrl: normalizedUrl,
      author: feedData.author,
      iconUrl: feedData.iconUrl,
      addedAt: DateTime.now(),
    );

    return _sourceRepository.addSource(source);
  }
}
