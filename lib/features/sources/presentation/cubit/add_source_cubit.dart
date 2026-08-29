import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/news_source.dart';
import 'package:newsreader/core/email_feed/email_feed_generator.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/features/sources/domain/usecases/add_source.dart';
import 'package:newsreader/features/sources/domain/usecases/generate_email_feed.dart';

part 'add_source_state.dart';

class AddSourceCubit extends Cubit<AddSourceState> {
  final AddSource _addSource;
  final GenerateEmailFeed _generateEmailFeed;
  final TelemetryClient _observabilityClient;

  AddSourceCubit(
    this._addSource,
    this._generateEmailFeed,
    this._observabilityClient,
  ) : super(const AddSourceInitial());

  Future<void> addSource(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      emit(const AddSourceError(AppErrorCode.emptyUrl));
      return;
    }

    emit(const AddSourceValidating());

    try {
      final source = await _addSource.execute(
        trimmed,
        onHeuristicStageStarted: () => emit(const AddSourceValidatingHeuristics()),
      );
      _observabilityClient.trackEvent('source_added');
      emit(AddSourceSuccess(source));
    } on FeedDiscoveryException catch (e) {
      emit(AddSourceFeedDiscoveryFailed(e.code, trimmed));
    } on AppException catch (e) {
      emit(AddSourceError(e.code));
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      emit(const AddSourceError(AppErrorCode.unknown));
    }
  }

  Future<void> generateEmailFeed({String? label}) async {
    emit(const AddSourceGeneratingEmailFeed());

    try {
      final feed = await _generateEmailFeed.execute(label: label);
      emit(AddSourceEmailFeedGenerated(feed));
    } on EmailFeedGenerationException catch (e) {
      emit(AddSourceError(e.code));
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      emit(const AddSourceError(AppErrorCode.unknown));
    }
  }

  void reset() => emit(const AddSourceInitial());
}
