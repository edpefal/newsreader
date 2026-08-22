import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/observability/observability_client.dart';
import 'package:newsreader/features/sources/domain/usecases/import_opml.dart';

part 'import_opml_state.dart';

class ImportOpmlCubit extends Cubit<ImportOpmlState> {
  final ImportOpml _importOpml;
  final ObservabilityClient _observabilityClient;

  ImportOpmlCubit(this._importOpml, this._observabilityClient)
      : super(const ImportOpmlInitial());

  Future<void> loadPreview(String xmlContent) async {
    emit(const ImportOpmlValidating());

    try {
      final urls = _importOpml.parseUrls(xmlContent);

      if (urls.isEmpty) {
        emit(const ImportOpmlError(AppErrorCode.opmlNoFeedsFound));
        return;
      }

      final items = <OpmlFeedItem>[];
      var pending = urls.length;

      await _importOpml.validateFeeds(urls, onResult: (v) {
        items.add(OpmlFeedItem(
          url: v.url,
          name: v.name,
          iconUrl: v.iconUrl,
          status: _toItemStatus(v.status),
          errorCode: v.errorCode,
          selected: v.status == OpmlFeedValidationStatus.valid,
        ));
        pending--;
        emit(ImportOpmlPreview(List.unmodifiable(items), pendingCount: pending));
      });
    } on ParseException catch (e) {
      emit(ImportOpmlError(e.code));
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      emit(const ImportOpmlError(AppErrorCode.invalidOpmlFile));
    }
  }

  OpmlFeedStatus _toItemStatus(OpmlFeedValidationStatus status) {
    return switch (status) {
      OpmlFeedValidationStatus.valid => OpmlFeedStatus.valid,
      OpmlFeedValidationStatus.duplicate => OpmlFeedStatus.duplicate,
      OpmlFeedValidationStatus.error => OpmlFeedStatus.error,
    };
  }

  void toggleSelection(String url) {
    final current = state;
    if (current is! ImportOpmlPreview) return;

    final updated = current.feeds.map((item) {
      if (item.url == url && item.status == OpmlFeedStatus.valid) {
        return item.copyWith(selected: !item.selected);
      }
      return item;
    }).toList();

    emit(ImportOpmlPreview(updated));
  }

  Future<void> confirmImport() async {
    final current = state;
    if (current is! ImportOpmlPreview) return;

    final selectedUrls = current.selectedFeeds.map((f) => f.url).toList();
    if (selectedUrls.isEmpty) return;

    emit(const ImportOpmlImporting());

    final result = await _importOpml.execute(selectedUrls);

    emit(ImportOpmlDone(
      importedCount: result.imported.length,
      failedCount: result.failed.length,
    ));
  }
}
