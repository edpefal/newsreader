import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/data/datasources/local/article_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/source_local_datasource.dart';
import 'package:newsreader/core/data/datasources/local/summary_local_datasource.dart';

/// Borra todos los datos locales (fuentes, artículos, resúmenes) y el
/// cursor de sincronización, para que la próxima cuenta que inicie sesión
/// en este dispositivo arranque sin datos de la cuenta anterior — evita
/// colisiones de `id` entre cuentas distintas al sincronizar con la nube.
/// Se ejecuta al cerrar sesión.
class ClearLocalUserData {
  final SourceLocalDataSource _sourceLocalDataSource;
  final ArticleLocalDataSource _articleLocalDataSource;
  final SummaryLocalDataSource _summaryLocalDataSource;
  final Box<dynamic> _settingsBox;

  const ClearLocalUserData(
    this._sourceLocalDataSource,
    this._articleLocalDataSource,
    this._summaryLocalDataSource,
    this._settingsBox,
  );

  Future<void> execute() async {
    await _sourceLocalDataSource.clearAll();
    await _articleLocalDataSource.clearAll();
    await _summaryLocalDataSource.clearAll();
    await _settingsBox.delete(AppConstants.settingsLastSyncedAtKey);
  }
}
