part of 'import_opml_cubit.dart';

enum OpmlFeedStatus { valid, duplicate, error }

class OpmlFeedItem extends Equatable {
  final String url;
  final String name;
  final String? iconUrl;
  final OpmlFeedStatus status;
  final AppErrorCode? errorCode;
  final bool selected;

  const OpmlFeedItem({
    required this.url,
    required this.name,
    this.iconUrl,
    required this.status,
    this.errorCode,
    this.selected = false,
  });

  OpmlFeedItem copyWith({bool? selected}) {
    return OpmlFeedItem(
      url: url,
      name: name,
      iconUrl: iconUrl,
      status: status,
      errorCode: errorCode,
      selected: selected ?? this.selected,
    );
  }

  @override
  List<Object?> get props => [url, name, iconUrl, status, errorCode, selected];
}

sealed class ImportOpmlState extends Equatable {
  const ImportOpmlState();

  @override
  List<Object?> get props => [];
}

final class ImportOpmlInitial extends ImportOpmlState {
  const ImportOpmlInitial();
}

final class ImportOpmlValidating extends ImportOpmlState {
  const ImportOpmlValidating();
}

final class ImportOpmlPreview extends ImportOpmlState {
  final List<OpmlFeedItem> feeds;
  final int pendingCount;

  const ImportOpmlPreview(this.feeds, {this.pendingCount = 0});

  bool get isValidating => pendingCount > 0;

  List<OpmlFeedItem> get selectedFeeds =>
      feeds.where((f) => f.status == OpmlFeedStatus.valid && f.selected).toList();

  bool get hasSelection => selectedFeeds.isNotEmpty;

  @override
  List<Object?> get props => [feeds, pendingCount];
}

final class ImportOpmlImporting extends ImportOpmlState {
  const ImportOpmlImporting();
}

final class ImportOpmlDone extends ImportOpmlState {
  final int importedCount;
  final int failedCount;

  const ImportOpmlDone({required this.importedCount, required this.failedCount});

  @override
  List<Object?> get props => [importedCount, failedCount];
}

final class ImportOpmlError extends ImportOpmlState {
  final AppErrorCode code;

  const ImportOpmlError(this.code);

  @override
  List<Object?> get props => [code];
}
