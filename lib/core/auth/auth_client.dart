import 'package:newsreader/core/errors/app_error_code.dart';

/// Resultado de un intento de login. [cancelled] indica que el usuario
/// abandonó el flujo nativo (selector de cuenta, diálogo de Apple) antes de
/// completarlo — no es un error, la UI debe volver a la pantalla de login
/// sin mostrar ningún mensaje.
enum AuthResult { success, cancelled }

abstract class AuthClient {
  /// Emite el estado de sesión (true = hay sesión activa) cada vez que
  /// cambia: login, logout, o expiración/refresh de token.
  Stream<bool> get authStateChanges;

  /// Si hay una sesión activa en este momento.
  bool get isSignedIn;

  /// El `id` del usuario autenticado actual, o `null` si no hay sesión.
  String? get currentUserId;

  /// El email del usuario autenticado actual, o `null` si no hay sesión o
  /// el proveedor de auth no lo devolvió.
  String? get currentUserEmail;

  /// El access token (JWT) de la sesión activa, o `null` si no hay sesión.
  /// Se usa para autenticar llamadas a Edge Functions como el usuario
  /// actual (por ejemplo, disparar el fetch de feeds on-demand).
  String? get currentAccessToken;

  /// Inicia sesión con Google. Lanza [AuthException] si el intercambio de
  /// token falla; devuelve [AuthResult.cancelled] si el usuario cierra el
  /// selector de cuenta sin elegir ninguna.
  Future<AuthResult> signInWithGoogle();

  /// Inicia sesión con Apple. Lanza [AuthException] si el intercambio de
  /// token falla; devuelve [AuthResult.cancelled] si el usuario cancela el
  /// flujo nativo de Sign in with Apple.
  Future<AuthResult> signInWithApple();

  /// Cierra la sesión activa.
  Future<void> signOut();
}

class AuthException implements Exception {
  final AppErrorCode code;

  const AuthException(this.code);

  @override
  String toString() => 'AuthException: $code';
}
