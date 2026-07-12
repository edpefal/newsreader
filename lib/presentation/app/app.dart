import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/features/archive/presentation/cubit/archive_cubit.dart';
import 'package:newsreader/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/sources/presentation/cubit/sources_cubit.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';
import 'package:newsreader/presentation/app/router.dart';
import 'package:newsreader/presentation/theme/app_theme.dart';
import 'package:newsreader/presentation/theme/theme_cubit.dart';

class App extends StatelessWidget {
  final ThemeCubit themeCubit;
  final InboxCubit inboxCubit;
  final FavoritesCubit favoritesCubit;
  final ArchiveCubit archiveCubit;
  final SourcesCubit sourcesCubit;
  final SummariesCubit summariesCubit;

  const App({
    super.key,
    required this.themeCubit,
    required this.inboxCubit,
    required this.favoritesCubit,
    required this.archiveCubit,
    required this.sourcesCubit,
    required this.summariesCubit,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: themeCubit),
        BlocProvider.value(value: inboxCubit),
        BlocProvider.value(value: favoritesCubit),
        BlocProvider.value(value: archiveCubit),
        BlocProvider.value(value: sourcesCubit),
        BlocProvider.value(value: summariesCubit),
      ],
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
