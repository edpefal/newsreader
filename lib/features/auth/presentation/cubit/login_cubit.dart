import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthClient _authClient;
  final TelemetryClient _observabilityClient;

  LoginCubit(this._authClient, this._observabilityClient)
      : super(const LoginIdle());

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
        _observabilityClient.trackEvent('login_completed', properties: {
          'method': method,
        });
      }
      emit(const LoginIdle());
    } on AuthException catch (e) {
      emit(LoginError(e.code));
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      emit(const LoginError(AppErrorCode.unknown));
    }
  }
}
