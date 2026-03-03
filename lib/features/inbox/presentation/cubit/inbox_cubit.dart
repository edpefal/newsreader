import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/inbox/domain/usecases/get_inbox_articles.dart';
import 'package:newsreader/features/inbox/domain/usecases/sync_sources.dart';
import 'package:newsreader/features/sources/domain/usecases/get_sources.dart';

part 'inbox_state.dart';

class InboxCubit extends Cubit<InboxState> {
  final GetInboxArticles _getInboxArticles;
  final GetSources _getSources;
  final SyncSources _syncSources;

  InboxCubit(this._getInboxArticles, this._getSources, this._syncSources)
      : super(const InboxLoading());

  Future<void> loadArticles() async {
    emit(const InboxLoading());
    await _reload();
  }

  Future<SyncResult> syncAndReload() async {
    final result = await _syncSources.execute();
    await _reload();
    return result;
  }

  Future<void> _reload() async {
    final results = await Future.wait([
      _getInboxArticles.execute(),
      _getSources.execute(),
    ]);
    final articles = results[0] as List<Article>;
    final hasSources = (results[1] as List).isNotEmpty;
    emit(InboxLoaded(articles, hasSources: hasSources));
  }
}
