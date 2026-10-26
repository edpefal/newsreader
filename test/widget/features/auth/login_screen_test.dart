import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/errors/app_error_code.dart';
import 'package:newsreader/features/auth/presentation/cubit/email_login_availability_cubit.dart';
import 'package:newsreader/features/auth/presentation/cubit/login_cubit.dart';
import 'package:newsreader/features/auth/presentation/screens/login_screen.dart';

import '../../../support/pump_localized_app.dart';

class MockLoginCubit extends MockCubit<LoginState> implements LoginCubit {}

class MockEmailLoginAvailabilityCubit extends MockCubit<bool>
    implements EmailLoginAvailabilityCubit {}

/// Por defecto el flag `email-login` está activo, para que los tests del
/// flujo de correo lo vean; los tests del flag lo pasan en [emailLoginEnabled].
Widget _buildSubject(
  LoginCubit cubit, {
  EmailLoginAvailabilityCubit? availability,
}) {
  final emailLogin = availability ?? _availabilityCubit(enabled: true);
  return MaterialApp(
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<LoginCubit>.value(value: cubit),
        BlocProvider<EmailLoginAvailabilityCubit>.value(value: emailLogin),
      ],
      child: const LoginScreen(),
    ),
  );
}

MockEmailLoginAvailabilityCubit _availabilityCubit({required bool enabled}) {
  final cubit = MockEmailLoginAvailabilityCubit();
  when(() => cubit.state).thenReturn(enabled);
  return cubit;
}

void main() {
  late MockLoginCubit cubit;

  setUp(() {
    cubit = MockLoginCubit();
    when(() => cubit.state).thenReturn(const LoginIdle());
    when(() => cubit.startEmailFlow()).thenReturn(null);
    when(() => cubit.back()).thenReturn(null);
    when(() => cubit.submitEmail(any())).thenAnswer((_) async {});
    when(() => cubit.verifyCode(any())).thenAnswer((_) async {});
    when(() => cubit.resendCode()).thenAnswer((_) async {});
  });

  group('LoginScreen', () {
    testWidgets('muestra los botones de Google y Apple', (tester) async {
      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Continuar con Apple'), findsOneWidget);
    });

    testWidgets(
      'limita el ancho de los botones en pantallas anchas en vez de estirarlos',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_buildSubject(cubit));

        final size = tester.getSize(
          find.byWidgetPredicate(
            (widget) =>
                widget is ConstrainedBox &&
                widget.constraints.maxWidth == kLoginMaxContentWidth,
          ),
        );
        expect(size.width, kLoginMaxContentWidth);
      },
    );

    testWidgets('ofrece el acceso con correo bajo un separador "o"', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('o'), findsOneWidget);
      expect(find.text('Continuar con correo'), findsOneWidget);
    });

    testWidgets('con el flag apagado muestra solo Google y Apple', (
      tester,
    ) async {
      final availability = _availabilityCubit(enabled: false);
      await tester.pumpWidget(_buildSubject(cubit, availability: availability));

      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Continuar con Apple'), findsOneWidget);
      expect(find.text('o'), findsNothing);
      expect(find.text('Continuar con correo'), findsNothing);
    });

    testWidgets('el acceso con correo aparece cuando el flag se activa', (
      tester,
    ) async {
      final availability = MockEmailLoginAvailabilityCubit();
      whenListen(availability, Stream<bool>.value(true), initialState: false);
      await tester.pumpWidget(_buildSubject(cubit, availability: availability));
      expect(find.text('Continuar con correo'), findsNothing);

      await tester.pump();

      expect(find.text('o'), findsOneWidget);
      expect(find.text('Continuar con correo'), findsOneWidget);
    });

    testWidgets('tocar "Continuar con correo" abre el flujo de correo', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(cubit));

      await tester.tap(find.text('Continuar con correo'));

      verify(() => cubit.startEmailFlow()).called(1);
    });
  });

  group('LoginScreen — paso del correo', () {
    setUp(() {
      when(() => cubit.state).thenReturn(const LoginEmailEntry());
    });

    testWidgets('el flujo en curso sigue visible si el flag está apagado', (
      tester,
    ) async {
      final availability = _availabilityCubit(enabled: false);
      await tester.pumpWidget(_buildSubject(cubit, availability: availability));

      expect(
        find.textContaining('Entraste antes con Apple o Google'),
        findsOneWidget,
      );
    });

    testWidgets('muestra el aviso para quien entró con Apple o Google', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(cubit));

      expect(
        find.textContaining('Entraste antes con Apple o Google'),
        findsOneWidget,
      );
      expect(find.text('Continuar con Google'), findsNothing);
    });

    testWidgets('enviar el código pasa el correo escrito al cubit', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(cubit));

      await tester.enterText(find.byType(TextField), 'ana@example.com');
      await tester.tap(find.text('Enviar código'));

      verify(() => cubit.submitEmail('ana@example.com')).called(1);
    });

    testWidgets('muestra el error localizado dentro de la vista', (
      tester,
    ) async {
      when(
        () => cubit.state,
      ).thenReturn(const LoginEmailEntry(error: AppErrorCode.invalidEmail));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('Ingresa un correo válido.'), findsOneWidget);
    });

    testWidgets('conserva el correo al volver desde el paso del código', (
      tester,
    ) async {
      when(
        () => cubit.state,
      ).thenReturn(const LoginEmailEntry(email: 'ana@example.com'));

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.text('ana@example.com'), findsOneWidget);
    });

    testWidgets('el botón atrás de la vista vuelve un paso', (tester) async {
      await tester.pumpWidget(_buildSubject(cubit));

      await tester.tap(find.byIcon(Icons.arrow_back));

      verify(() => cubit.back()).called(1);
    });

    testWidgets('el atrás del sistema vuelve un paso en vez de cerrar', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSubject(cubit));

      await tester.binding.handlePopRoute();
      await tester.pump();

      verify(() => cubit.back()).called(1);
    });
  });

  group('LoginScreen — paso del código', () {
    final past = DateTime.now().subtract(const Duration(minutes: 1));
    final future = DateTime.now().add(const Duration(minutes: 10));

    testWidgets('muestra el correo al que se envió el código', (tester) async {
      when(() => cubit.state).thenReturn(
        LoginCodeSent(email: 'ana@example.com', resendAvailableAt: past),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(find.textContaining('ana@example.com'), findsOneWidget);
    });

    testWidgets(
      'reenviar está deshabilitado y muestra los segundos restantes',
      (tester) async {
        when(() => cubit.state).thenReturn(
          LoginCodeSent(email: 'ana@example.com', resendAvailableAt: future),
        );

        await tester.pumpWidget(_buildSubject(cubit));

        final label = find.textContaining('Reenviar código en ');
        expect(label, findsOneWidget);
        final button = tester.widget<TextButton>(
          find.ancestor(of: label, matching: find.byType(TextButton)),
        );
        expect(button.onPressed, isNull);
      },
    );

    testWidgets('reenviar se habilita al terminar el contador', (tester) async {
      when(() => cubit.state).thenReturn(
        LoginCodeSent(email: 'ana@example.com', resendAvailableAt: past),
      );

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.text('Reenviar código'));

      verify(() => cubit.resendCode()).called(1);
    });

    testWidgets('verificar pasa el código escrito al cubit', (tester) async {
      when(() => cubit.state).thenReturn(
        LoginCodeSent(email: 'ana@example.com', resendAvailableAt: past),
      );

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Verificar'));

      verify(() => cubit.verifyCode('123456')).called(1);
    });

    testWidgets('solo acepta dígitos y hasta 6', (tester) async {
      when(() => cubit.state).thenReturn(
        LoginCodeSent(email: 'ana@example.com', resendAvailableAt: past),
      );

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.enterText(find.byType(TextField), '12ab3456789');

      expect(find.text('123456'), findsOneWidget);
    });

    testWidgets('muestra el error de código inválido o expirado', (
      tester,
    ) async {
      when(() => cubit.state).thenReturn(
        LoginCodeSent(
          email: 'ana@example.com',
          resendAvailableAt: past,
          error: AppErrorCode.invalidEmailCode,
        ),
      );

      await tester.pumpWidget(_buildSubject(cubit));

      expect(
        find.textContaining('El código no es válido o ya venció'),
        findsOneWidget,
      );
    });

    testWidgets('cambiar correo vuelve al paso del correo', (tester) async {
      when(() => cubit.state).thenReturn(
        LoginCodeSent(email: 'ana@example.com', resendAvailableAt: past),
      );

      await tester.pumpWidget(_buildSubject(cubit));
      await tester.tap(find.text('Cambiar correo'));

      verify(() => cubit.back()).called(1);
    });
  });
}
