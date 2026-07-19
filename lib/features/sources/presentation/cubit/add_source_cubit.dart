import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/email_feed/email_feed_generator.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/features/sources/domain/usecases/add_source.dart';
import 'package:newsreader/features/sources/domain/usecases/generate_email_feed.dart';

part 'add_source_state.dart';

class AddSourceCubit extends Cubit<AddSourceState> {
  final AddSource _addSource;
  final GenerateEmailFeed _generateEmailFeed;

  AddSourceCubit(this._addSource, this._generateEmailFeed)
      : super(const AddSourceInitial());

  Future<void> addSource(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      emit(const AddSourceError('Ingresa una URL válida.'));
      return;
    }

    emit(const AddSourceValidating());

    try {
      final source = await _addSource.execute(trimmed);
      emit(AddSourceSuccess(source));
    } on FeedDiscoveryException catch (e) {
      emit(AddSourceFeedDiscoveryFailed(e.message, trimmed));
    } on AppException catch (e) {
      emit(AddSourceError(e.message));
    } catch (_) {
      emit(const AddSourceError('Ocurrió un error inesperado.'));
    }
  }

  Future<void> generateEmailFeed({String? label}) async {
    emit(const AddSourceGeneratingEmailFeed());

    try {
      final feed = await _generateEmailFeed.execute(label: label);
      emit(AddSourceEmailFeedGenerated(feed));
    } on EmailFeedGenerationException catch (e) {
      emit(AddSourceError(e.message));
    } catch (_) {
      emit(const AddSourceError('Ocurrió un error inesperado.'));
    }
  }

  void reset() => emit(const AddSourceInitial());
}
