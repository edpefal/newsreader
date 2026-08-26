import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/errors/app_error_code_localizations.dart';
import 'package:newsreader/features/auth/presentation/cubit/login_cubit.dart';
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
        if (state is LoginError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.code.localize(AppLocalizations.of(context))),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is LoginInProgress;
        final l10n = AppLocalizations.of(context);

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: kLoginMaxContentWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset('assets/reevo_logo.png', height: 72),
                      const SizedBox(height: 16),
                      Text(
                        l10n.appTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 40),
                      FilledButton.icon(
                        onPressed: isLoading
                            ? null
                            : () =>
                                  context.read<LoginCubit>().signInWithGoogle(),
                        icon: const Icon(Icons.g_mobiledata),
                        label: Text(l10n.loginContinueWithGoogle),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () =>
                                  context.read<LoginCubit>().signInWithApple(),
                        icon: const Icon(Icons.apple),
                        label: Text(l10n.loginContinueWithApple),
                      ),
                      if (isLoading) ...[
                        const SizedBox(height: 24),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    ],
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
