import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/inbox/domain/usecases/get_inbox_articles.dart';
import 'package:newsreader/features/inbox/domain/usecases/mark_article_as_read.dart';
import 'package:newsreader/features/inbox/domain/usecases/sync_sources.dart';
import 'package:newsreader/features/sources/domain/usecases/get_sources.dart';

part 'inbox_state.dart';

class InboxCubit extends Cubit<InboxState> {
  final GetInboxArticles _getInboxArticles;
  final GetSources _getSources;
  final SyncSources _syncSources;
  final MarkArticleAsRead _markArticleAsRead;

  InboxCubit(
    this._getInboxArticles,
    this._getSources,
    this._syncSources,
    this._markArticleAsRead,
  ) : super(const InboxLoading());

  Future<void> loadArticles() async {
    emit(const InboxLoading());
    await _reload();
  }

  Future<void> loadArticlesAfterReading(String articleId) =>
      _reload(readArticleId: articleId);

  Future<void> markAsRead(String articleId) async {
    await _markArticleAsRead.execute(articleId);
    await _reload(readArticleId: articleId);
  }

  Future<SyncResult> syncAndReload() async {
    final result = await _syncSources.execute();
    await _reload();
    return result;
  }

  Future<void> _reload({String? readArticleId}) async {
    final results = await Future.wait([
      _getInboxArticles.execute(),
      _getSources.execute(),
    ]);
    final articles = results[0] as List<Article>;
    final hasSources = (results[1] as List).isNotEmpty;
    emit(InboxLoaded(articles, hasSources: hasSources, readArticleId: readArticleId));
  }
}
