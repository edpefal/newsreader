import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/presentation/theme/app_theme.dart';
import 'package:newsreader/presentation/theme/theme_cubit.dart';
import 'package:newsreader/presentation/app/router.dart';

class App extends StatelessWidget {
  final ThemeCubit themeCubit;

  const App({super.key, required this.themeCubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: themeCubit,
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Newsletter Hub',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
