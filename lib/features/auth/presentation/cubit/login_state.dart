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
