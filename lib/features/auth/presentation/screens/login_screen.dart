import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/errors/app_error_code_localizations.dart';
import 'package:newsreader/features/auth/presentation/cubit/login_cubit.dart';
import 'package:newsreader/features/auth/presentation/widgets/login_code_view.dart';
import 'package:newsreader/features/auth/presentation/widgets/login_email_entry_view.dart';
import 'package:newsreader/features/auth/presentation/widgets/login_options_view.dart';
import 'package:newsreader/l10n/app_localizations.dart';

/// Ancho máximo del formulario de login para que los botones no se estiren
/// al ancho completo de la pantalla en tablets/pantallas anchas.
const double kLoginMaxContentWidth = 400;

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        // Los errores del flujo de correo se muestran dentro de su vista.
        if (state is LoginError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.code.localize(AppLocalizations.of(context))),
            ),
          );
        }
      },
      builder: (context, state) {
        // En los pasos del correo, "atrás" vuelve un paso dentro del login en
        // vez de cerrar la pantalla.
        final inEmailFlow = state is LoginEmailEntry || state is LoginCodeSent;

        return PopScope(
          canPop: !inEmailFlow,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.read<LoginCubit>().back();
          },
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: kLoginMaxContentWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    // El scroll evita que el teclado desborde las vistas del
                    // correo; el `minHeight` mantiene el contenido centrado
                    // verticalmente cuando sí cabe.
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: switch (state) {
                              LoginEmailEntry() => LoginEmailEntryView(
                                state: state,
                              ),
                              LoginCodeSent() => LoginCodeView(state: state),
                              _ => LoginOptionsView(
                                isLoading: state is LoginInProgress,
                              ),
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
