import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/features/sources/domain/usecases/get_sources.dart';

part 'sources_state.dart';

class SourcesCubit extends Cubit<SourcesState> {
  final GetSources _getSources;

  SourcesCubit(this._getSources) : super(const SourcesLoading());

  Future<void> loadSources() async {
    emit(const SourcesLoading());
    final sources = await _getSources.execute();
    emit(SourcesLoaded(sources));
  }
}
