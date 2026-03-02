import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/inbox/domain/usecases/get_inbox_articles.dart';

part 'inbox_state.dart';

class InboxCubit extends Cubit<InboxState> {
  final GetInboxArticles _getInboxArticles;

  InboxCubit(this._getInboxArticles) : super(const InboxLoading());

  Future<void> loadArticles() async {
    emit(const InboxLoading());
    final articles = await _getInboxArticles.execute();
    emit(InboxLoaded(articles));
  }
}
