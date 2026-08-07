import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/feed/feed_data.dart';
import 'package:newsreader/core/feed/feed_parser.dart';
import 'package:newsreader/core/feed/feed_url_resolver.dart';
import 'package:newsreader/core/feed/html_feed_link_extractor.dart';
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

  /// [onHeuristicStageStarted], si se provee, se invoca cuando la URL
  /// ingresada tal cual no resultó ser un feed válido y el sistema pasa a
  /// probar los candidatos heurísticos en paralelo — útil para que la UI
  /// refleje ese cambio de etapa.
  Future<NewsSource> execute(
    String feedUrl, {
    void Function()? onHeuristicStageStarted,
  }) async {
    final normalizedUrl = feedUrl.trim();

    final resolved = await _resolveFeed(normalizedUrl, onHeuristicStageStarted);

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

  /// Resolución en tres etapas: primero prueba [rawUrl] en solitario (etapa
  /// 1); si no resulta un feed válido, dispara el resto de los candidatos
  /// heurísticos en paralelo (etapa 2) y elige el ganador respetando el
  /// orden de prioridad de [FeedUrlResolver.candidatesFor], no el orden en
  /// que respondieron por red — así el resultado es determinista para el
  /// mismo input. Si la etapa 2 tampoco resuelve nada, y la etapa 1 alcanzó
  /// a descargar HTML (falló el parseo como feed, no la conexión), se
  /// intenta un último candidato extraído de un `<link rel="alternate">`
  /// declarado en ese HTML (etapa 3, auto-descubrimiento) — ver
  /// [HtmlFeedLinkExtractor].
  Future<({String feedUrl, FeedData feedData})> _resolveFeed(
    String rawUrl,
    void Function()? onHeuristicStageStarted,
  ) async {
    final candidates = _feedUrlResolver.candidatesFor(rawUrl);

    final firstStage = await _tryFirstStageCandidate(candidates.first);
    if (firstStage.result != null) return firstStage.result!;

    final heuristicCandidates = candidates.skip(1).toList();
    if (heuristicCandidates.isNotEmpty) {
      onHeuristicStageStarted?.call();

      final results = await Future.wait(
        heuristicCandidates.map(_tryCandidateIgnoringErrors),
      );

      for (final result in results) {
        if (result != null) return result;
      }
    }

    final retainedHtml = firstStage.html;
    if (retainedHtml != null) {
      final discoveredUrl = HtmlFeedLinkExtractor.extract(
        retainedHtml,
        Uri.parse(candidates.first),
      );
      if (discoveredUrl != null) {
        final discoveredResult =
            await _tryCandidateIgnoringErrors(discoveredUrl);
        if (discoveredResult != null) return discoveredResult;
      }
    }

    throw const FeedDiscoveryException();
  }

  /// Prueba el candidato de la etapa 1. A diferencia de [_tryCandidate],
  /// retiene el HTML descargado cuando el parseo como feed falla, para que
  /// la etapa 3 (auto-descubrimiento) pueda inspeccionarlo sin volver a
  /// pedirlo. Un error de red/timeout se sigue propagando tal cual (aborta
  /// la detección, no pasa a ninguna etapa siguiente).
  Future<({({String feedUrl, FeedData feedData})? result, String? html})>
      _tryFirstStageCandidate(String candidate) async {
    final content = await _httpClient.get(candidate);
    try {
      final feedData = _feedParser.parse(content);
      return (result: (feedUrl: candidate, feedData: feedData), html: null);
    } on ParseException {
      return (result: null, html: content);
    }
  }

  /// Prueba un único candidato. Un feed inválido (no parseable) se traduce
  /// en `null` para que el caller pueda seguir con el siguiente candidato;
  /// cualquier otro [AppException] (red, timeout) se propaga tal cual.
  Future<({String feedUrl, FeedData feedData})?> _tryCandidate(
    String candidate,
  ) async {
    try {
      final xmlContent = await _httpClient.get(candidate);
      final feedData = _feedParser.parse(xmlContent);
      return (feedUrl: candidate, feedData: feedData);
    } on ParseException {
      return null;
    }
  }

  /// Igual que [_tryCandidate], pero además absorbe errores de red/timeout
  /// como `null` en vez de propagarlos — usado en la etapa 2, donde varios
  /// candidatos están en vuelo a la vez y el fallo de uno no debe abortar
  /// la evaluación de los demás.
  Future<({String feedUrl, FeedData feedData})?> _tryCandidateIgnoringErrors(
    String candidate,
  ) async {
    try {
      return await _tryCandidate(candidate);
    } on AppException {
      return null;
    }
  }
}
