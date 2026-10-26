import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/features/auth/presentation/cubit/email_login_availability_cubit.dart';
import 'package:newsreader/features/auth/presentation/cubit/login_cubit.dart';
import 'package:newsreader/l10n/app_localizations.dart';

/// Vista inicial del login: logo, Google, Apple y, como alternativa
/// secundaria, el acceso con correo -- solo si el flag `email-login` está
/// activo (ver `EmailLoginAvailabilityCubit`).
class LoginOptionsView extends StatelessWidget {
  final bool isLoading;

  const LoginOptionsView({super.key, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<LoginCubit>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset('assets/reevo_logo.png', height: 72),
        const SizedBox(height: 16),
        Text(
          l10n.appTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.loginSubtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 40),
        FilledButton.icon(
          onPressed: isLoading ? null : cubit.signInWithGoogle,
          icon: const Icon(Icons.g_mobiledata),
          label: Text(l10n.loginContinueWithGoogle),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isLoading ? null : cubit.signInWithApple,
          icon: const Icon(Icons.apple),
          label: Text(l10n.loginContinueWithApple),
        ),
        BlocBuilder<EmailLoginAvailabilityCubit, bool>(
          builder: (context, emailLoginEnabled) {
            if (!emailLoginEnabled) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.loginOrSeparator,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: isLoading ? null : cubit.startEmailFlow,
                  child: Text(l10n.loginContinueWithEmail),
                ),
              ],
            );
          },
        ),
        if (isLoading) ...[
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}
