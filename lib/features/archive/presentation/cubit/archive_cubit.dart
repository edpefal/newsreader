import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/article.dart';
import 'package:newsreader/features/archive/domain/usecases/get_archive.dart';

part 'archive_state.dart';

class ArchiveCubit extends Cubit<ArchiveState> {
  final GetArchive _getArchive;

  ArchiveCubit(this._getArchive) : super(const ArchiveLoading());

  Future<void> loadArchive() async {
    emit(const ArchiveLoading());
    final articles = await _getArchive.execute();
    emit(ArchiveLoaded(articles));
  }
}
