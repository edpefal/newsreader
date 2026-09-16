import 'package:hive_ce/hive.dart';

part 'user_preferences_model.g.dart';

/// Copia local del locale activo y el offset horario UTC del dispositivo,
/// subidos a la nube en cada ciclo de `SyncUserData` (ver capability
/// `user-preferences`). Sin entidad de dominio propia -- ninguna pantalla la
/// muestra, es un valor auxiliar para que procesos del servidor sin sesión
/// en vivo (la generación automática del resumen diario) sepan en qué
/// idioma y a qué hora local generar contenido para este usuario.
@HiveType(typeId: 6)
class UserPreferencesModel extends HiveObject {
  @HiveField(0)
  String locale;

  @HiveField(1)
  int utcOffsetMinutes;

  UserPreferencesModel({
    required this.locale,
    required this.utcOffsetMinutes,
  });
}
