import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/feature_flags/feature_flag_client.dart';
import 'package:newsreader/core/feature_flags/feature_flag_keys.dart';
import 'package:newsreader/features/auth/presentation/cubit/email_login_availability_cubit.dart';

class MockFeatureFlagClient extends Mock implements FeatureFlagClient {}

void main() {
  late MockFeatureFlagClient flags;
  late StreamController<void> changes;

  setUp(() {
    flags = MockFeatureFlagClient();
    changes = StreamController<void>.broadcast();
    when(() => flags.changes).thenAnswer((_) => changes.stream);
  });

  tearDown(() => changes.close());

  test('arranca oculto (false) antes de leer el flag', () {
    when(
      () => flags.isEnabled(FeatureFlagKeys.emailLogin),
    ).thenAnswer((_) async => false);

    final sut = EmailLoginAvailabilityCubit(flags);

    expect(sut.state, isFalse);
    sut.close();
  });

  blocTest<EmailLoginAvailabilityCubit, bool>(
    'pasa a true cuando el flag está activo',
    setUp: () => when(
      () => flags.isEnabled(FeatureFlagKeys.emailLogin),
    ).thenAnswer((_) async => true),
    build: () => EmailLoginAvailabilityCubit(flags),
    expect: () => [true],
  );

  blocTest<EmailLoginAvailabilityCubit, bool>(
    'se queda oculto cuando el flag está apagado',
    setUp: () => when(
      () => flags.isEnabled(FeatureFlagKeys.emailLogin),
    ).thenAnswer((_) async => false),
    build: () => EmailLoginAvailabilityCubit(flags),
    expect: () => <bool>[],
  );

  blocTest<EmailLoginAvailabilityCubit, bool>(
    'se activa cuando los flags llegan después con la pantalla visible',
    setUp: () {
      var enabled = false;
      when(
        () => flags.isEnabled(FeatureFlagKeys.emailLogin),
      ).thenAnswer((_) async => enabled);
      // El primer cambio del flag ocurre luego de crear el cubit.
      addTearDown(() => enabled = false);
      Future<void>.delayed(const Duration(milliseconds: 10), () {
        enabled = true;
        changes.add(null);
      });
    },
    build: () => EmailLoginAvailabilityCubit(flags),
    wait: const Duration(milliseconds: 50),
    expect: () => [true],
  );

  blocTest<EmailLoginAvailabilityCubit, bool>(
    'vuelve a ocultarse cuando el flag se apaga',
    setUp: () {
      var enabled = true;
      when(
        () => flags.isEnabled(FeatureFlagKeys.emailLogin),
      ).thenAnswer((_) async => enabled);
      Future<void>.delayed(const Duration(milliseconds: 10), () {
        enabled = false;
        changes.add(null);
      });
    },
    build: () => EmailLoginAvailabilityCubit(flags),
    wait: const Duration(milliseconds: 50),
    expect: () => [true, false],
  );

  test('close cancela la suscripción a los cambios', () async {
    when(
      () => flags.isEnabled(FeatureFlagKeys.emailLogin),
    ).thenAnswer((_) async => false);
    final sut = EmailLoginAvailabilityCubit(flags);

    await sut.close();

    expect(changes.hasListener, isFalse);
  });
}
