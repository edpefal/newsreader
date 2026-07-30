import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/core/feed/feed_sync_trigger.dart';
import 'package:newsreader/features/inbox/domain/usecases/get_inbox_articles.dart';
import 'package:newsreader/features/inbox/domain/usecases/mark_article_as_read.dart';
import 'package:newsreader/features/sources/domain/usecases/get_sources.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_user_data.dart';

part 'inbox_state.dart';

class InboxCubit extends Cubit<InboxState> {
  final GetInboxArticles _getInboxArticles;
  final GetSources _getSources;
  final FeedSyncTrigger _feedSyncTrigger;
  final MarkArticleAsRead _markArticleAsRead;
  final SyncUserData _syncUserData;

  InboxCubit(
    this._getInboxArticles,
    this._getSources,
    this._feedSyncTrigger,
    this._markArticleAsRead,
    this._syncUserData,
  ) : super(const InboxLoading());

  Future<void> loadArticles() async {
    emit(const InboxLoading());
    await _reload();
  }

  /// Sincroniza y recarga tras detectar una sesión nueva (primer login, o
  /// login después de cerrar sesión). Emite `InboxLoading` antes de
  /// arrancar el sync -- sin esto, la pantalla se queda mostrando el
  /// estado vacío de antes del login (sin spinner) durante los segundos
  /// que tarda `SyncUserData`, dando la impresión de que no hay fuentes.
  Future<void> syncAfterSignIn() async {
    emit(const InboxLoading(message: 'Sincronizando fuentes...'));
    await _syncUserData.execute();
    await _reload();
  }

  Future<void> loadArticlesAfterReading(String articleId) =>
      _reload(readArticleId: articleId);

  Future<void> markAsRead(String articleId) async {
    await _markArticleAsRead.execute(articleId);
    await _reload(readArticleId: articleId);
  }

  Future<FeedSyncResult> syncAndReload() async {
    // Subir el estado local (incluyendo borrados de fuentes) antes de
    // disparar el fetch: si se dispara primero, `sync-feeds` todavía ve en
    // Postgres una fuente que el usuario acaba de borrar localmente y le
    // crea artículos nuevos, que después el pull de abajo resucita en el
    // Inbox. Se vuelve a llamar después del fetch para bajar esos artículos
    // nuevos en la misma pasada de refresh.
    await _syncUserData.execute();
    final result = await _feedSyncTrigger.execute();
    await _syncUserData.execute();
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
