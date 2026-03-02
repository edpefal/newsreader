import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/features/sources/domain/usecases/get_sources.dart';
import 'package:newsreader/features/sources/domain/usecases/update_source_name.dart';

part 'sources_state.dart';

class SourcesCubit extends Cubit<SourcesState> {
  final GetSources _getSources;
  final UpdateSourceName _updateSourceName;

  SourcesCubit(this._getSources, this._updateSourceName)
      : super(const SourcesLoading());

  Future<void> loadSources() async {
    emit(const SourcesLoading());
    await _reload();
  }

  Future<void> updateSourceName(String id, String name) async {
    await _updateSourceName.execute(id, name);
    await _reload();
  }

  Future<void> _reload() async {
    final sources = await _getSources.execute();
    emit(SourcesLoaded(sources));
  }
}
