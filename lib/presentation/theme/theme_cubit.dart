import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final Box<dynamic> _settingsBox;

  ThemeCubit(this._settingsBox)
      : super(
          _settingsBox.get(
                AppConstants.settingsThemeModeKey,
                defaultValue: 'light',
              ) ==
              'dark'
              ? ThemeMode.dark
              : ThemeMode.light,
        );

  void toggleTheme() {
    final isDark = state == ThemeMode.light;
    _settingsBox.put(
      AppConstants.settingsThemeModeKey,
      isDark ? 'dark' : 'light',
    );
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
