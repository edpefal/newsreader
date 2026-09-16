import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/data/datasources/local/user_preferences_local_datasource.dart';
import 'package:newsreader/core/data/models/user_preferences_model.dart';

class HiveUserPreferencesDatasource implements UserPreferencesLocalDataSource {
  // Una sola fila (la del dispositivo actual), mismo patrón que
  // `HiveAiUsageDatasource`.
  static const _key = 'current';

  final Box<UserPreferencesModel> _box;

  const HiveUserPreferencesDatasource(this._box);

  @override
  Future<UserPreferencesModel?> get() async => _box.get(_key);

  @override
  Future<void> save(UserPreferencesModel model) async => _box.put(_key, model);
}
