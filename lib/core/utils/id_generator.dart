abstract class IdGenerator {
  String generate();

  /// Genera un id determinístico a partir de [seed]: el mismo seed siempre
  /// produce el mismo id, en cualquier dispositivo. Se usa para entidades
  /// descubiertas de forma independiente en varios dispositivos (por
  /// ejemplo artículos de RSS, identificados por su URL) para que no se
  /// dupliquen al sincronizar.
  String generateFromSeed(String seed);
}
