/// Cliente genérico para sincronizar filas con las tablas de usuario en
/// Postgres (`sources`, `articles`, `daily_summaries`). Trabaja con mapas
/// JSON (columnas snake_case) en vez de tipos fuertes por tabla, para no
/// duplicar la misma pareja de métodos 3 veces — el mapeo entre los modelos
/// de Hive y estas filas vive en `SyncUserData`, no acá.
abstract class CloudSyncClient {
  /// Inserta o actualiza (por `id`) un lote de filas en [table]. Las filas
  /// ya deben incluir `user_id`: este cliente no lo agrega.
  Future<void> upsert(String table, List<Map<String, dynamic>> rows);

  /// Actualiza (nunca inserta) un lote de filas en [table] por su `id`. Si
  /// el `id` de una fila no existe todavía, esa fila no tiene efecto (no es
  /// un error) -- se usa para sincronizar campos que solo el servidor puede
  /// originar (como el contenido de un artículo), donde el cliente solo
  /// puede actualizar el estado de una fila que ya existe.
  Future<void> updatePartial(String table, List<Map<String, dynamic>> rows);

  /// Devuelve las filas de [table] pertenecientes al usuario actual (vía
  /// RLS, sin necesidad de filtrar `user_id` del lado del cliente) cuyo
  /// `updated_at` es posterior a [since]. Si [since] es `null`, devuelve
  /// todas las filas del usuario (primera sincronización).
  Future<List<Map<String, dynamic>>> fetchChangedSince(
    String table,
    DateTime? since,
  );
}

class CloudSyncException implements Exception {
  final String message;

  const CloudSyncException(this.message);

  @override
  String toString() => 'CloudSyncException: $message';
}
