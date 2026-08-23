import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:newsreader/core/constants/app_constants.dart';
import 'package:newsreader/presentation/theme/theme_cubit.dart';

class MockSettingsBox extends Mock implements Box<dynamic> {}

void main() {
  late Map<String, dynamic> store;
  late MockSettingsBox settingsBox;

  ThemeCubit buildCubit() => ThemeCubit(settingsBox);

  setUp(() {
    store = {};
    settingsBox = MockSettingsBox();
    // Fake in-memory backing para get/put -- soporta cualquier key sin
    // necesitar un `when` por combinación, ya que ThemeCubit lee/escribe
    // dos keys distintas (`settingsThemeModeKey` y
    // `settingsThemeModeMigratedKey`) en distintos pasos.
    when(() => settingsBox.get(any(), defaultValue: any(named: 'defaultValue')))
        .thenAnswer((invocation) {
      final key = invocation.positionalArguments[0] as String;
      final defaultValue = invocation.namedArguments[#defaultValue];
      return store.containsKey(key) ? store[key] : defaultValue;
    });
    when(() => settingsBox.put(any(), any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1];
      store[key] = value;
    });
  });

  group('ThemeCubit - estado inicial', () {
    test('usuario nuevo sin preferencia guardada arranca en system', () {
      final cubit = buildCubit();
      expect(cubit.state, ThemeMode.system);
    });

    test('migra una preferencia explícita "light" previa a system', () {
      store[AppConstants.settingsThemeModeKey] = 'light';

      final cubit = buildCubit();

      expect(cubit.state, ThemeMode.system);
      expect(store[AppConstants.settingsThemeModeKey], 'system');
      expect(store[AppConstants.settingsThemeModeMigratedKey], true);
    });

    test('migra una preferencia explícita "dark" previa a system', () {
      store[AppConstants.settingsThemeModeKey] = 'dark';

      final cubit = buildCubit();

      expect(cubit.state, ThemeMode.system);
      expect(store[AppConstants.settingsThemeModeKey], 'system');
    });

    test(
        'no re-migra una elección explícita de dark hecha después de la migración',
        () {
      // Simula un usuario que ya pasó por la migración en una apertura
      // anterior y luego eligió "oscuro" a propósito desde la UI nueva.
      store[AppConstants.settingsThemeModeMigratedKey] = true;
      store[AppConstants.settingsThemeModeKey] = 'dark';

      final cubit = buildCubit();

      expect(cubit.state, ThemeMode.dark);
    });

    test('respeta "system" ya persistido sin re-evaluar la migración', () {
      store[AppConstants.settingsThemeModeMigratedKey] = true;
      store[AppConstants.settingsThemeModeKey] = 'system';

      final cubit = buildCubit();

      expect(cubit.state, ThemeMode.system);
    });
  });

  group('ThemeCubit - setThemeMode', () {
    test('setThemeMode(light) emite y persiste light', () {
      final cubit = buildCubit();

      cubit.setThemeMode(ThemeMode.light);

      expect(cubit.state, ThemeMode.light);
      expect(store[AppConstants.settingsThemeModeKey], 'light');
    });

    test('setThemeMode(dark) emite y persiste dark', () {
      final cubit = buildCubit();

      cubit.setThemeMode(ThemeMode.dark);

      expect(cubit.state, ThemeMode.dark);
      expect(store[AppConstants.settingsThemeModeKey], 'dark');
    });

    test('setThemeMode(system) emite y persiste system', () {
      final cubit = buildCubit();
      cubit.setThemeMode(ThemeMode.light);

      cubit.setThemeMode(ThemeMode.system);

      expect(cubit.state, ThemeMode.system);
      expect(store[AppConstants.settingsThemeModeKey], 'system');
    });
  });
}
