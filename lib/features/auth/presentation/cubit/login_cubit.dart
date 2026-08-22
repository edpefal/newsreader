import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/observability/observability_client.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthClient _authClient;
  final ObservabilityClient _observabilityClient;

  LoginCubit(this._authClient, this._observabilityClient)
      : super(const LoginIdle());

  Future<void> signInWithGoogle() => _signIn(_authClient.signInWithGoogle);

  Future<void> signInWithApple() => _signIn(_authClient.signInWithApple);

  Future<void> _signIn(Future<AuthResult> Function() signIn) async {
    emit(const LoginInProgress());
    try {
      await signIn();
      // No hace falta distinguir éxito de cancelación acá ni navegar
      // manualmente: el router reacciona solo al cambio de sesión (ver
      // GoRouter.redirect). Solo volvemos a LoginIdle para no dejar el
      // botón en loading si la redirección tarda un instante.
      emit(const LoginIdle());
    } on AuthException catch (e) {
      emit(LoginError(e.code));
    } catch (e, st) {
      _observabilityClient.captureException(e, st);
      emit(const LoginError(AppErrorCode.unknown));
    }
  }
}
