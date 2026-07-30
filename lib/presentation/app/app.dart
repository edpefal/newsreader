import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/di/injection.dart';
import 'package:newsreader/features/archive/presentation/cubit/archive_cubit.dart';
import 'package:newsreader/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/sources/presentation/cubit/sources_cubit.dart';
import 'package:newsreader/features/summaries/presentation/cubit/summaries_cubit.dart';
import 'package:newsreader/presentation/app/router.dart';
import 'package:newsreader/presentation/theme/app_theme.dart';
import 'package:newsreader/presentation/theme/theme_cubit.dart';

class App extends StatefulWidget {
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
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  StreamSubscription<bool>? _authSubscription;
  bool _wasSignedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wasSignedIn = getIt<AuthClient>().isSignedIn;
    // `InboxCubit` es un singleton que no se reconstruye al navegar de
    // `/login` a `/` (el router solo redirige, ver GoRouter.redirect):
    // sin este listener, un login (primero o después de cerrar sesión)
    // deja el Inbox con el estado vacío que tenía antes de loguearse hasta
    // el próximo pull-to-refresh, aunque los datos ya estén en la nube.
    // Se dispara solo en la transición false -> true para no repetir el
    // sync en cada refresh de token mientras la sesión sigue activa.
    _authSubscription =
        getIt<AuthClient>().authStateChanges.listen((isSignedIn) {
      if (isSignedIn && !_wasSignedIn) {
        widget.inboxCubit.syncAfterSignIn();
      }
      _wasSignedIn = isSignedIn;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sincroniza también al volver del background (no solo al abrir la app
    // desde cero), para que un cambio hecho en otro dispositivo se refleje
    // sin necesitar forzar el cierre completo de la app. `syncInBackground()`
    // (a diferencia de `loadArticles()`) no reemplaza el Inbox ya cargado
    // por un spinner a pantalla completa mientras sincroniza.
    if (state == AppLifecycleState.resumed) {
      widget.inboxCubit.syncInBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.themeCubit),
        BlocProvider.value(value: widget.inboxCubit),
        BlocProvider.value(value: widget.favoritesCubit),
        BlocProvider.value(value: widget.archiveCubit),
        BlocProvider.value(value: widget.sourcesCubit),
        BlocProvider.value(value: widget.summariesCubit),
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
