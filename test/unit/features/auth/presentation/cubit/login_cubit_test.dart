import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/features/auth/presentation/cubit/login_cubit.dart';

class MockAuthClient extends Mock implements AuthClient {}

void main() {
  late MockAuthClient mockAuthClient;

  LoginCubit buildCubit() => LoginCubit(mockAuthClient);

  setUp(() {
    mockAuthClient = MockAuthClient();
  });

  group('LoginCubit', () {
    test('estado inicial es LoginIdle', () {
      expect(buildCubit().state, const LoginIdle());
    });

    blocTest<LoginCubit, LoginState>(
      'signInWithGoogle() emite InProgress y vuelve a Idle en éxito',
      build: () {
        when(() => mockAuthClient.signInWithGoogle())
            .thenAnswer((_) async => AuthResult.success);
        return buildCubit();
      },
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => [const LoginInProgress(), const LoginIdle()],
    );

    blocTest<LoginCubit, LoginState>(
      'signInWithGoogle() vuelve a Idle sin error si el usuario cancela',
      build: () {
        when(() => mockAuthClient.signInWithGoogle())
            .thenAnswer((_) async => AuthResult.cancelled);
        return buildCubit();
      },
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => [const LoginInProgress(), const LoginIdle()],
    );

    blocTest<LoginCubit, LoginState>(
      'signInWithGoogle() emite LoginError si falla el intercambio de token',
      build: () {
        when(() => mockAuthClient.signInWithGoogle())
            .thenThrow(const AuthException(AppErrorCode.authProviderError));
        return buildCubit();
      },
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => [const LoginInProgress(), const LoginError(AppErrorCode.authProviderError)],
    );

    blocTest<LoginCubit, LoginState>(
      'signInWithApple() emite InProgress y vuelve a Idle en éxito',
      build: () {
        when(() => mockAuthClient.signInWithApple())
            .thenAnswer((_) async => AuthResult.success);
        return buildCubit();
      },
      act: (cubit) => cubit.signInWithApple(),
      expect: () => [const LoginInProgress(), const LoginIdle()],
    );

    blocTest<LoginCubit, LoginState>(
      'signInWithApple() emite LoginError si falla el intercambio de token',
      build: () {
        when(() => mockAuthClient.signInWithApple())
            .thenThrow(const AuthException(AppErrorCode.authProviderError));
        return buildCubit();
      },
      act: (cubit) => cubit.signInWithApple(),
      expect: () => [const LoginInProgress(), const LoginError(AppErrorCode.authProviderError)],
    );
  });
}
