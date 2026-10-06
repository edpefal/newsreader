/// Consulta si el usuario actual ya tiene como fuente activa un feed en la
/// nube, aunque este dispositivo todavía no lo haya sincronizado (por
/// ejemplo, porque lo agregó desde otro dispositivo).
///
/// Es una verificación de mejor esfuerzo para dar el aviso de "ya estás
/// suscrito" antes de crear la fuente; la garantía de unicidad real vive en
/// el servidor (índice único parcial de `sources`) y en la reconciliación de
/// `SyncUserData`.
abstract class RemoteSourceChecker {
  /// `true` solo si se pudo confirmar que existe una fuente activa (no
  /// borrada) del usuario con exactamente esa [feedUrl]. Ante cualquier
  /// imposibilidad de consultar (sin sesión, sin red, timeout, error del
  /// servidor) devuelve `false` en vez de lanzar: no debe impedir agregar
  /// la fuente.
  Future<bool> existsActive(String feedUrl);
}
