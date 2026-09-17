import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/domain/entities/daily_summary.dart';
import 'package:newsreader/features/summaries/domain/usecases/get_daily_summaries.dart';

part 'summaries_state.dart';

/// Pantalla de solo lectura: el resumen diario se genera automáticamente
/// del lado del servidor (ver capability `daily-summaries`), sin ninguna
/// acción del usuario -- este Cubit solo carga lo que ya sincronizó
/// `SyncUserData`, sin botón de generar, paywall, ni indicador de cupo.
class SummariesCubit extends Cubit<SummariesState> {
  final GetDailySummaries _getDailySummaries;

  SummariesCubit(this._getDailySummaries) : super(const SummariesLoading());

  Future<void> loadSummaries() async {
    emit(const SummariesLoading());
    final summaries = await _getDailySummaries.execute();
    emit(SummariesLoaded(summaries: summaries));
  }
}
