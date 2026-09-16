import 'package:newsreader/core/data/models/user_preferences_model.dart';

abstract class UserPreferencesLocalDataSource {
  /// Última copia local de las preferencias de este dispositivo, o `null`
  /// si `SyncUserData` todavía no corrió ni una vez.
  Future<UserPreferencesModel?> get();

  /// Reemplaza la copia local con el valor actual del dispositivo (locale +
  /// offset horario), justo antes de subirlo a la nube -- ver
  /// `SyncUserData._syncUserPreferences`.
  Future<void> save(UserPreferencesModel model);
}
