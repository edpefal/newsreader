import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/core/data/datasources/local/article_local_datasource.dart';

/// Migración de una sola vez para el change `centralize-feed-fetching`: los
/// artículos pasan a nacer en el servidor con `id` generado ahí, así que el
/// historial local con ids viejos (generados en el cliente) no puede
/// converger con el resto de los dispositivos. Se limpia una vez por
/// dispositivo (marcado en settings) y el próximo sync/fetch repuebla todo
/// con ids canónicos.
class ResetLocalArticles {
  final ArticleLocalDataSource _articleLocalDataSource;
  final Box<dynamic> _settingsBox;

  const ResetLocalArticles(this._articleLocalDataSource, this._settingsBox);

  Future<void> execute() async {
    final alreadyReset =
        _settingsBox.get(AppConstants.settingsArticlesResetV3Key) as bool? ??
            false;
    if (alreadyReset) return;

    await _articleLocalDataSource.clearAll();
    // El cursor de sincronización también se resetea: si no, el dispositivo
    // sigue pensando que ya está al día desde antes de la limpieza, y
    // `SyncUserData` nunca vuelve a pedir artículos con `updated_at`
    // anterior a esa fecha -- quedarían invisibles para siempre, aunque la
    // box local esté vacía. Resetearlo fuerza una re-sincronización
    // completa (sources/artículos/resúmenes), inofensiva porque el pull es
    // idempotente por `id`.
    await _settingsBox.delete(AppConstants.settingsLastSyncedAtKey);
    await _settingsBox.put(AppConstants.settingsArticlesResetV3Key, true);
  }
}
