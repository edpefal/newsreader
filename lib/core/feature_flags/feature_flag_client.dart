/// Abstracción sobre el proveedor de feature flags remotos (hoy PostHog) --
/// ver capability `feature-flags`. Ningún archivo fuera de `core/` debe
/// importar el SDK del proveedor directamente.
abstract class FeatureFlagClient {
  /// Si el flag [key] está activo. Falla del lado seguro: devuelve `false`
  /// cuando el valor no se conoce (flags sin cargar, sin red, error del
  /// proveedor, flag inexistente o de un tipo que no es booleano).
  Future<bool> isEnabled(String key);

  /// Emite cada vez que los flags terminan de cargar o cambian de valor, para
  /// que una pantalla ya visible vuelva a leer los que le importan.
  Stream<void> get changes;
}
