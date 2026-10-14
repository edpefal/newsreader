import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/features/auth/presentation/cubit/login_cubit.dart';

import '../../../../../support/fake_telemetry_client.dart';

class MockAuthClient extends Mock implements AuthClient {}

class _FakeStackTrace extends Fake implements StackTrace {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeStackTrace());
    registerFallbackValue(TelemetryLevel.info);
  });

  late MockAuthClient mockAuthClient;
  late MockTelemetryClient mockTelemetryClient;

  LoginCubit buildCubit() => LoginCubit(mockAuthClient, mockTelemetryClient);

  setUp(() {
    mockAuthClient = MockAuthClient();
    mockTelemetryClient = MockTelemetryClient();
  });

  group('LoginCubit', () {
    test('estado inicial es LoginIdle', () {
      expect(buildCubit().state, const LoginIdle());
    });

    blocTest<LoginCubit, LoginState>(
      'signInWithGoogle() emite InProgress y vuelve a Idle en éxito',
      build: () {
        when(
          () => mockAuthClient.signInWithGoogle(),
        ).thenAnswer((_) async => AuthResult.success);
        return buildCubit();
      },
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => [const LoginInProgress(), const LoginIdle()],
    );

    blocTest<LoginCubit, LoginState>(
      'signInWithGoogle() vuelve a Idle sin error si el usuario cancela',
      build: () {
        when(
          () => mockAuthClient.signInWithGoogle(),
        ).thenAnswer((_) async => AuthResult.cancelled);
        return buildCubit();
      },
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => [const LoginInProgress(), const LoginIdle()],
    );

    blocTest<LoginCubit, LoginState>(
      'signInWithGoogle() emite LoginError si falla el intercambio de token',
      build: () {
        when(
          () => mockAuthClient.signInWithGoogle(),
        ).thenThrow(const AuthException(AppErrorCode.authProviderError));
        return buildCubit();
      },
      act: (cubit) => cubit.signInWithGoogle(),
      expect: () => [
        const LoginInProgress(),
        const LoginError(AppErrorCode.authProviderError),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'signInWithApple() emite InProgress y vuelve a Idle en éxito',
      build: () {
        when(
          () => mockAuthClient.signInWithApple(),
        ).thenAnswer((_) async => AuthResult.success);
        return buildCubit();
      },
      act: (cubit) => cubit.signInWithApple(),
      expect: () => [const LoginInProgress(), const LoginIdle()],
    );

    blocTest<LoginCubit, LoginState>(
      'signInWithApple() emite LoginError si falla el intercambio de token',
      build: () {
        when(
          () => mockAuthClient.signInWithApple(),
        ).thenThrow(const AuthException(AppErrorCode.authProviderError));
        return buildCubit();
      },
      act: (cubit) => cubit.signInWithApple(),
      expect: () => [
        const LoginInProgress(),
        const LoginError(AppErrorCode.authProviderError),
      ],
    );
  });

  group('LoginCubit — login con correo y código', () {
    final t0 = DateTime(2026, 10, 13, 12);
    const email = 'ana@example.com';
    final resendAt = t0.add(loginResendCooldown);

    LoginCubit buildAt(DateTime Function() now) =>
        LoginCubit(mockAuthClient, mockTelemetryClient, now: now);

    setUp(() {
      when(
        () => mockTelemetryClient.trackEvent(
          any(),
          properties: any(named: 'properties'),
        ),
      ).thenReturn(null);
    });

    blocTest<LoginCubit, LoginState>(
      'startEmailFlow() abre el paso del correo',
      build: () => buildCubit(),
      act: (cubit) => cubit.startEmailFlow(),
      expect: () => [const LoginEmailEntry()],
    );

    blocTest<LoginCubit, LoginState>(
      'submitEmail() con formato inválido no llama al servidor',
      build: () => buildCubit(),
      act: (cubit) => cubit.submitEmail('no-es-un-correo'),
      expect: () => [
        const LoginEmailEntry(
          email: 'no-es-un-correo',
          error: AppErrorCode.invalidEmail,
        ),
      ],
      verify: (_) => verifyNever(() => mockAuthClient.requestEmailCode(any())),
    );

    blocTest<LoginCubit, LoginState>(
      'submitEmail() pide el código y pasa al paso del código',
      build: () {
        when(
          () => mockAuthClient.requestEmailCode(email),
        ).thenAnswer((_) async {});
        return buildAt(() => t0);
      },
      act: (cubit) => cubit.submitEmail('  $email '),
      expect: () => [
        const LoginEmailEntry(email: email, isLoading: true),
        LoginCodeSent(email: email, resendAvailableAt: resendAt),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'submitEmail() deja el error en el paso del correo si el servidor rechaza',
      build: () {
        when(
          () => mockAuthClient.requestEmailCode(email),
        ).thenThrow(const AuthException(AppErrorCode.tooManyAuthRequests));
        return buildAt(() => t0);
      },
      act: (cubit) => cubit.submitEmail(email),
      expect: () => [
        const LoginEmailEntry(email: email, isLoading: true),
        const LoginEmailEntry(
          email: email,
          error: AppErrorCode.tooManyAuthRequests,
        ),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'verifyCode() abre la sesión, registra login_completed con method email y vuelve a Idle',
      build: () {
        when(
          () => mockAuthClient.verifyEmailCode(email: email, code: '123456'),
        ).thenAnswer((_) async => AuthResult.success);
        return buildAt(() => t0);
      },
      seed: () => LoginCodeSent(email: email, resendAvailableAt: resendAt),
      act: (cubit) => cubit.verifyCode('123456'),
      expect: () => [
        LoginCodeSent(
          email: email,
          resendAvailableAt: resendAt,
          isLoading: true,
        ),
        const LoginIdle(),
      ],
      verify: (_) => verify(
        () => mockTelemetryClient.trackEvent(
          'login_completed',
          properties: {'method': 'email'},
        ),
      ).called(1),
    );

    blocTest<LoginCubit, LoginState>(
      'verifyCode() con código incorrecto se queda en el paso del código y no registra el evento',
      build: () {
        when(
          () => mockAuthClient.verifyEmailCode(email: email, code: '000000'),
        ).thenThrow(const AuthException(AppErrorCode.invalidEmailCode));
        return buildAt(() => t0);
      },
      seed: () => LoginCodeSent(email: email, resendAvailableAt: resendAt),
      act: (cubit) => cubit.verifyCode('000000'),
      expect: () => [
        LoginCodeSent(
          email: email,
          resendAvailableAt: resendAt,
          isLoading: true,
        ),
        LoginCodeSent(
          email: email,
          resendAvailableAt: resendAt,
          error: AppErrorCode.invalidEmailCode,
        ),
      ],
      verify: (_) => verifyNever(
        () => mockTelemetryClient.trackEvent(
          any(),
          properties: any(named: 'properties'),
        ),
      ),
    );

    blocTest<LoginCubit, LoginState>(
      'verifyCode() con menos de 6 dígitos no llama al servidor',
      build: () => buildAt(() => t0),
      seed: () => LoginCodeSent(email: email, resendAvailableAt: resendAt),
      act: (cubit) => cubit.verifyCode('123'),
      expect: () => [
        LoginCodeSent(
          email: email,
          resendAvailableAt: resendAt,
          error: AppErrorCode.invalidEmailCode,
        ),
      ],
      verify: (_) => verifyNever(
        () => mockAuthClient.verifyEmailCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ),
    );

    blocTest<LoginCubit, LoginState>(
      'resendCode() no hace nada antes de que pase el enfriamiento',
      build: () => buildAt(() => t0.add(const Duration(seconds: 30))),
      seed: () => LoginCodeSent(email: email, resendAvailableAt: resendAt),
      act: (cubit) => cubit.resendCode(),
      expect: () => <LoginState>[],
      verify: (_) => verifyNever(() => mockAuthClient.requestEmailCode(any())),
    );

    blocTest<LoginCubit, LoginState>(
      'resendCode() tras el enfriamiento envía otro código y reinicia el contador',
      build: () {
        when(
          () => mockAuthClient.requestEmailCode(email),
        ).thenAnswer((_) async {});
        return buildAt(() => resendAt);
      },
      seed: () => LoginCodeSent(email: email, resendAvailableAt: resendAt),
      act: (cubit) => cubit.resendCode(),
      expect: () => [
        LoginCodeSent(
          email: email,
          resendAvailableAt: resendAt,
          isLoading: true,
        ),
        LoginCodeSent(
          email: email,
          resendAvailableAt: resendAt.add(loginResendCooldown),
        ),
      ],
    );

    blocTest<LoginCubit, LoginState>(
      'resendCode() con límite del servidor muestra el error y reinicia el contador',
      build: () {
        when(
          () => mockAuthClient.requestEmailCode(email),
        ).thenThrow(const AuthException(AppErrorCode.tooManyAuthRequests));
        return buildAt(() => resendAt);
      },
      seed: () => LoginCodeSent(email: email, resendAvailableAt: resendAt),
      act: (cubit) => cubit.resendCode(),
      expect: () => [
        LoginCodeSent(
          email: email,
          resendAvailableAt: resendAt,
          isLoading: true,
        ),
        LoginCodeSent(
          email: email,
          resendAvailableAt: resendAt.add(loginResendCooldown),
          error: AppErrorCode.tooManyAuthRequests,
        ),
      ],
    );

    group('señal login_email_rate_limited en Sentry', () {
      void verifyRateLimited(String step) => verify(
        () => mockTelemetryClient.captureMessage(
          'login_email_rate_limited: $step',
          level: TelemetryLevel.warning,
        ),
      ).called(1);

      blocTest<LoginCubit, LoginState>(
        'submitEmail() con límite registra step send',
        build: () {
          when(
            () => mockAuthClient.requestEmailCode(email),
          ).thenThrow(const AuthException(AppErrorCode.tooManyAuthRequests));
          return buildAt(() => t0);
        },
        act: (cubit) => cubit.submitEmail(email),
        verify: (_) => verifyRateLimited('send'),
      );

      blocTest<LoginCubit, LoginState>(
        'resendCode() con límite registra step resend',
        build: () {
          when(
            () => mockAuthClient.requestEmailCode(email),
          ).thenThrow(const AuthException(AppErrorCode.tooManyAuthRequests));
          return buildAt(() => resendAt);
        },
        seed: () => LoginCodeSent(email: email, resendAvailableAt: resendAt),
        act: (cubit) => cubit.resendCode(),
        verify: (_) => verifyRateLimited('resend'),
      );

      blocTest<LoginCubit, LoginState>(
        'verifyCode() con límite registra step verify',
        build: () {
          when(
            () => mockAuthClient.verifyEmailCode(email: email, code: '123456'),
          ).thenThrow(const AuthException(AppErrorCode.tooManyAuthRequests));
          return buildAt(() => t0);
        },
        seed: () => LoginCodeSent(email: email, resendAvailableAt: resendAt),
        act: (cubit) => cubit.verifyCode('123456'),
        verify: (_) => verifyRateLimited('verify'),
      );

      for (final code in [
        AppErrorCode.invalidEmailCode,
        AppErrorCode.invalidEmail,
        AppErrorCode.network,
        AppErrorCode.unknown,
      ]) {
        blocTest<LoginCubit, LoginState>(
          'un error $code no registra la señal',
          build: () {
            when(
              () => mockAuthClient.requestEmailCode(email),
            ).thenThrow(AuthException(code));
            return buildAt(() => t0);
          },
          act: (cubit) => cubit.submitEmail(email),
          verify: (_) => verifyNever(
            () => mockTelemetryClient.captureMessage(
              any(),
              level: any(named: 'level'),
            ),
          ),
        );
      }
    });

    blocTest<LoginCubit, LoginState>(
      'back() del paso del código vuelve al correo conservándolo',
      build: () => buildCubit(),
      seed: () => LoginCodeSent(email: email, resendAvailableAt: resendAt),
      act: (cubit) => cubit.back(),
      expect: () => [const LoginEmailEntry(email: email)],
    );

    blocTest<LoginCubit, LoginState>(
      'back() del paso del correo vuelve a la vista inicial',
      build: () => buildCubit(),
      seed: () => const LoginEmailEntry(email: email),
      act: (cubit) => cubit.back(),
      expect: () => [const LoginIdle()],
    );

    blocTest<LoginCubit, LoginState>(
      'back() en la vista inicial no emite nada',
      build: () => buildCubit(),
      act: (cubit) => cubit.back(),
      expect: () => <LoginState>[],
    );

    blocTest<LoginCubit, LoginState>(
      'un error inesperado se reporta y se muestra como unknown',
      build: () {
        when(
          () => mockAuthClient.requestEmailCode(email),
        ).thenThrow(StateError('boom'));
        return buildAt(() => t0);
      },
      act: (cubit) => cubit.submitEmail(email),
      expect: () => [
        const LoginEmailEntry(email: email, isLoading: true),
        const LoginEmailEntry(email: email, error: AppErrorCode.unknown),
      ],
      verify: (_) => verify(
        () => mockTelemetryClient.captureException(any(), any()),
      ).called(1),
    );
  });
}
