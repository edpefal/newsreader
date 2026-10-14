import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';

part 'login_state.dart';

/// Espera mínima entre dos envíos del código de acceso por correo.
const loginResendCooldown = Duration(seconds: 60);

/// Longitud del código de acceso por correo (ver capability `user-auth`).
const loginEmailCodeLength = 6;

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

class LoginCubit extends Cubit<LoginState> {
  final AuthClient _authClient;
  final TelemetryClient _observabilityClient;
  final DateTime Function() _now;

  LoginCubit(
    this._authClient,
    this._observabilityClient, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const LoginIdle());

  Future<void> signInWithGoogle() =>
      _signIn(_authClient.signInWithGoogle, method: 'google');

  Future<void> signInWithApple() =>
      _signIn(_authClient.signInWithApple, method: 'apple');

  Future<void> _signIn(
    Future<AuthResult> Function() signIn, {
    required String method,
  }) async {
    emit(const LoginInProgress());
    try {
      final result = await signIn();
      // No hace falta distinguir éxito de cancelación para la UI ni navegar
      // manualmente: el router reacciona solo al cambio de sesión (ver
      // GoRouter.redirect). Solo volvemos a LoginIdle para no dejar el
      // botón en loading si la redirección tarda un instante. El evento de
      // producto sí distingue: una cancelación no es un login completado.
      if (result == AuthResult.success) {
        _trackLoginCompleted(method);
      }
      emit(const LoginIdle());
    } on AuthException catch (e) {
      emit(LoginError(e.code));
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      emit(const LoginError(AppErrorCode.unknown));
    }
  }

  void _trackLoginCompleted(String method) {
    _observabilityClient.trackEvent(
      'login_completed',
      properties: {'method': method},
    );
  }

  /// Señal del tope de correos, para alertar en Sentry: `send`/`resend`
  /// indican el límite global del servicio y `verify` el límite por origen al
  /// verificar. Cada paso es un mensaje distinto (un issue por paso) y no lleva
  /// el correo ni ningún dato personal.
  void _trackRateLimited(AppErrorCode code, String step) {
    if (code != AppErrorCode.tooManyAuthRequests) return;
    _observabilityClient.captureMessage(
      'login_email_rate_limited: $step',
      level: TelemetryLevel.warning,
    );
  }

  // --- Login con correo y código ------------------------------------------

  /// Abre el paso de ingresar el correo.
  void startEmailFlow() => emit(const LoginEmailEntry());

  /// Valida el formato y pide el código. Con éxito pasa al paso del código.
  Future<void> submitEmail(String rawEmail) async {
    final email = rawEmail.trim();
    if (!_emailPattern.hasMatch(email)) {
      emit(LoginEmailEntry(email: email, error: AppErrorCode.invalidEmail));
      return;
    }

    emit(LoginEmailEntry(email: email, isLoading: true));
    try {
      await _authClient.requestEmailCode(email);
      emit(LoginCodeSent(email: email, resendAvailableAt: _nextResendAt()));
    } on AuthException catch (e) {
      _trackRateLimited(e.code, 'send');
      emit(LoginEmailEntry(email: email, error: e.code));
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      emit(LoginEmailEntry(email: email, error: AppErrorCode.unknown));
    }
  }

  /// Verifica el código del paso actual. Un código con formato inválido ni
  /// siquiera se envía al servidor.
  Future<void> verifyCode(String rawCode) async {
    final current = state;
    if (current is! LoginCodeSent || current.isLoading) return;

    final code = rawCode.trim();
    if (!RegExp('^\\d{$loginEmailCodeLength}\$').hasMatch(code)) {
      emit(_codeSent(current, error: AppErrorCode.invalidEmailCode));
      return;
    }

    emit(_codeSent(current, isLoading: true));
    try {
      await _authClient.verifyEmailCode(email: current.email, code: code);
      _trackLoginCompleted('email');
      emit(const LoginIdle());
    } on AuthException catch (e) {
      _trackRateLimited(e.code, 'verify');
      emit(_codeSent(current, error: e.code));
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      emit(_codeSent(current, error: AppErrorCode.unknown));
    }
  }

  /// Pide un nuevo código si ya pasó el enfriamiento; si no, no hace nada.
  Future<void> resendCode() async {
    final current = state;
    if (current is! LoginCodeSent || current.isLoading) return;
    if (_now().isBefore(current.resendAvailableAt)) return;

    emit(_codeSent(current, isLoading: true));
    try {
      await _authClient.requestEmailCode(current.email);
      emit(
        LoginCodeSent(email: current.email, resendAvailableAt: _nextResendAt()),
      );
    } on AuthException catch (e) {
      _trackRateLimited(e.code, 'resend');
      emit(_codeSent(current, error: e.code, restartCooldown: true));
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      emit(_codeSent(current, error: AppErrorCode.unknown));
    }
  }

  /// Vuelve un paso: del código al correo (conservándolo), y del correo a la
  /// vista inicial. Sin efecto en cualquier otro estado.
  void back() {
    final current = state;
    if (current is LoginCodeSent) {
      emit(LoginEmailEntry(email: current.email));
    } else if (current is LoginEmailEntry) {
      emit(const LoginIdle());
    }
  }

  DateTime _nextResendAt() => _now().add(loginResendCooldown);

  LoginCodeSent _codeSent(
    LoginCodeSent from, {
    bool isLoading = false,
    AppErrorCode? error,
    bool restartCooldown = false,
  }) => LoginCodeSent(
    email: from.email,
    resendAvailableAt: restartCooldown
        ? _nextResendAt()
        : from.resendAvailableAt,
    isLoading: isLoading,
    error: error,
  );
}
