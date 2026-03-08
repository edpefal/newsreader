import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/sources/domain/usecases/get_source_articles.dart';

part 'source_detail_state.dart';

class SourceDetailCubit extends Cubit<SourceDetailState> {
  final GetSourceArticles _getSourceArticles;

  SourceDetailCubit(this._getSourceArticles) : super(const SourceDetailLoading());

  Future<void> loadArticles(String sourceId) async {
    emit(const SourceDetailLoading());
    final articles = await _getSourceArticles.execute(sourceId);
    emit(SourceDetailLoaded(articles));
  }
}
