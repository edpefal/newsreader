import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/features/sources/domain/usecases/import_opml.dart';

part 'import_opml_state.dart';

class ImportOpmlCubit extends Cubit<ImportOpmlState> {
  final ImportOpml _importOpml;

  ImportOpmlCubit(this._importOpml) : super(const ImportOpmlInitial());

  Future<void> loadPreview(String xmlContent) async {
    emit(const ImportOpmlValidating());

    try {
      final urls = _importOpml.parseUrls(xmlContent);

      if (urls.isEmpty) {
        emit(const ImportOpmlError('No se encontraron feeds en este archivo.'));
        return;
      }

      final validations = await _importOpml.validateFeeds(urls);

      final items = validations.map((v) {
        return OpmlFeedItem(
          url: v.url,
          name: v.name,
          iconUrl: v.iconUrl,
          status: _toItemStatus(v.status),
          errorMessage: v.errorMessage,
          selected: v.status == OpmlFeedValidationStatus.valid,
        );
      }).toList();

      emit(ImportOpmlPreview(items));
    } on ParseException catch (e) {
      emit(ImportOpmlError(e.message));
    } catch (_) {
      emit(const ImportOpmlError('Ocurrió un error al leer el archivo.'));
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
