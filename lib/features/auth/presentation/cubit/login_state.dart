part of 'login_cubit.dart';

sealed class LoginState extends Equatable {
  const LoginState();
}

final class LoginIdle extends LoginState {
  const LoginIdle();

  @override
  List<Object?> get props => [];
}

final class LoginInProgress extends LoginState {
  const LoginInProgress();

  @override
  List<Object?> get props => [];
}

final class LoginError extends LoginState {
  final AppErrorCode code;

  const LoginError(this.code);

  @override
  List<Object?> get props => [code];
}

/// Paso 1 del login con correo: el usuario escribe su correo. [email]
/// conserva lo escrito al volver desde el paso del código. Los errores de
/// este flujo se muestran en la propia vista ([error]), no como snackbar.
final class LoginEmailEntry extends LoginState {
  final String email;
  final bool isLoading;
  final AppErrorCode? error;

  const LoginEmailEntry({this.email = '', this.isLoading = false, this.error});

  @override
  List<Object?> get props => [email, isLoading, error];
}

/// Paso 2: el código ya se envió a [email]. [resendAvailableAt] es la hora
/// absoluta desde la que se puede pedir otro código.
final class LoginCodeSent extends LoginState {
  final String email;
  final DateTime resendAvailableAt;
  final bool isLoading;
  final AppErrorCode? error;

  const LoginCodeSent({
    required this.email,
    required this.resendAvailableAt,
    this.isLoading = false,
    this.error,
  });

  @override
  List<Object?> get props => [email, resendAvailableAt, isLoading, error];
}
