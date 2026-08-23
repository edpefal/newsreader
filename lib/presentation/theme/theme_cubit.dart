import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive.dart';

import 'package:newsreader/core/constants/app_constants.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final Box<dynamic> _settingsBox;

  ThemeCubit(this._settingsBox) : super(_initialMode(_settingsBox));

  static ThemeMode _initialMode(Box<dynamic> settingsBox) {
    final alreadyMigrated = settingsBox.get(
      AppConstants.settingsThemeModeMigratedKey,
      defaultValue: false,
    ) as bool;

    if (!alreadyMigrated) {
      settingsBox.put(AppConstants.settingsThemeModeMigratedKey, true);
      final legacyValue =
          settingsBox.get(AppConstants.settingsThemeModeKey) as String?;
      // Solo el formato binario previo (sin 'system') se migra; un
      // usuario nuevo sin valor guardado ya cae en el default 'system' de
      // la lectura de abajo, sin necesitar sobreescribir nada acá.
      if (legacyValue == 'light' || legacyValue == 'dark') {
        settingsBox.put(
          AppConstants.settingsThemeModeKey,
          ThemeMode.system.name,
        );
        return ThemeMode.system;
      }
    }

    final stored =
        settingsBox.get(AppConstants.settingsThemeModeKey) as String?;
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  void setThemeMode(ThemeMode mode) {
    _settingsBox.put(AppConstants.settingsThemeModeKey, mode.name);
    emit(mode);
  }
}
