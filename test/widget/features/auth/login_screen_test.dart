import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/features/auth/presentation/cubit/login_cubit.dart';
import 'package:newsreader/features/auth/presentation/screens/login_screen.dart';

import '../../../support/pump_localized_app.dart';

class MockLoginCubit extends MockCubit<LoginState> implements LoginCubit {}

Widget _buildSubject(LoginCubit cubit) {
  return MaterialApp(
    locale: testLocale,
    localizationsDelegates: testLocalizationsDelegates,
    supportedLocales: testSupportedLocales,
    home: BlocProvider<LoginCubit>.value(
      value: cubit,
      child: const LoginScreen(),
    ),
  );
}

void main() {
  late MockLoginCubit cubit;

  setUp(() {
    cubit = MockLoginCubit();
    when(() => cubit.state).thenReturn(const LoginIdle());
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
    });
  });
}
