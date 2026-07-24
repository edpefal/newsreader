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
  final String message;

  const LoginError(this.message);

  @override
  List<Object?> get props => [message];
}
