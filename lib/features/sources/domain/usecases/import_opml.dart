import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/domain/repositories/source_repository.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/feed/feed_parser.dart';
import 'package:newsreader/core/network/http_client.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/core/opml/opml_parser.dart';
import 'package:newsreader/core/utils/id_generator.dart';

class OpmlFeedValidation {
  final String url;
  final String name;
  final String? iconUrl;
  final OpmlFeedValidationStatus status;
  final AppErrorCode? errorCode;

  const OpmlFeedValidation({
    required this.url,
    required this.name,
    this.iconUrl,
    required this.status,
    this.errorCode,
  });
}

enum OpmlFeedValidationStatus { valid, duplicate, error }

class ImportOpmlResult {
  final List<NewsSource> imported;
  final List<String> skippedDuplicates;
  final List<String> failed;

  const ImportOpmlResult({
    required this.imported,
    required this.skippedDuplicates,
    required this.failed,
  });
}

class ImportOpml {
  final OPMLParser _opmlParser;
  final HttpClient _httpClient;
  final FeedParser _feedParser;
  final SourceRepository _sourceRepository;
  final IdGenerator _idGenerator;
  final TelemetryClient _observabilityClient;

  const ImportOpml(
    this._opmlParser,
    this._httpClient,
    this._feedParser,
    this._sourceRepository,
    this._idGenerator,
    this._observabilityClient,
  );

  List<String> parseUrls(String xmlContent) => _opmlParser.parse(xmlContent);

  Future<void> validateFeeds(
    List<String> urls, {
    required void Function(OpmlFeedValidation) onResult,
    int batchSize = 5,
  }) async {
    for (var i = 0; i < urls.length; i += batchSize) {
      final batch = urls.skip(i).take(batchSize).toList();
      await Future.wait(batch.map((url) async {
        final result = await _validateSingle(url);
        onResult(result);
      }));
    }
  }

  Future<OpmlFeedValidation> _validateSingle(String url) async {
    if (await _sourceRepository.sourceExists(url)) {
      return OpmlFeedValidation(
        url: url,
        name: url,
        status: OpmlFeedValidationStatus.duplicate,
      );
    }
    try {
      final xmlContent = await _httpClient.get(url);
      final feedData = _feedParser.parse(xmlContent);
      return OpmlFeedValidation(
        url: url,
        name: feedData.title,
        iconUrl: feedData.iconUrl,
        status: OpmlFeedValidationStatus.valid,
      );
    } on AppException catch (e) {
      return OpmlFeedValidation(
        url: url,
        name: url,
        status: OpmlFeedValidationStatus.error,
        errorCode: e.code,
      );
    } catch (_) {
      // No se reporta a observabilidad a propósito: validar una URL
      // individual dentro de un OPML es lo mismo que el parser de feeds,
      // control de flujo esperado sobre input del usuario (ver design.md
      // de add-observability-provider, sección 4).
      return OpmlFeedValidation(
        url: url,
        name: url,
        status: OpmlFeedValidationStatus.error,
        errorCode: AppErrorCode.opmlFeedValidationFailed,
      );
    }
  }

  Future<ImportOpmlResult> execute(List<String> selectedUrls) async {
    final results = await Future.wait(selectedUrls.map(_importSingle));

    final imported = <NewsSource>[];
    final skippedDuplicates = <String>[];
    final failed = <String>[];

    for (final result in results) {
      switch (result) {
        case _ImportSuccess(:final source):
          imported.add(source);
        case _ImportDuplicate(:final url):
          skippedDuplicates.add(url);
        case _ImportFailure(:final url):
          failed.add(url);
      }
    }

    return ImportOpmlResult(
      imported: imported,
      skippedDuplicates: skippedDuplicates,
      failed: failed,
    );
  }

  Future<_ImportOutcome> _importSingle(String url) async {
    try {
      final xmlContent = await _httpClient.get(url);
      final feedData = _feedParser.parse(xmlContent);

      final source = NewsSource(
        id: _idGenerator.generate(),
        name: feedData.title,
        feedUrl: url,
        author: feedData.author,
        iconUrl: feedData.iconUrl,
        addedAt: DateTime.now(),
      );

      return _ImportSuccess(await _sourceRepository.addSource(source));
    } on DuplicateSourceException {
      return _ImportDuplicate(url);
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      return _ImportFailure(url);
    }
  }
}

sealed class _ImportOutcome {}

final class _ImportSuccess extends _ImportOutcome {
  final NewsSource source;
  _ImportSuccess(this.source);
}

final class _ImportDuplicate extends _ImportOutcome {
  final String url;
  _ImportDuplicate(this.url);
}

final class _ImportFailure extends _ImportOutcome {
  final String url;
  _ImportFailure(this.url);
}
