import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/get_latest_daily_summary.dart';

part 'summaries_state.dart';

/// Pantalla de solo lectura: el resumen diario se genera automáticamente
/// del lado del servidor (ver capability `daily-summaries`), sin ninguna
/// acción del usuario -- este Cubit solo carga lo que ya sincronizó
/// `SyncUserData`, sin botón de generar, paywall, ni indicador de cupo.
class SummariesCubit extends Cubit<SummariesState> {
  final GetLatestDailySummary _getLatestDailySummary;

  SummariesCubit(this._getLatestDailySummary) : super(const SummariesLoading());

  Future<void> loadSummaries() async {
    emit(const SummariesLoading());
    final summary = await _getLatestDailySummary.execute();
    emit(SummariesLoaded(summary: summary));
  }
}
