import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/errors/app_error_code_localizations.dart';
import 'package:newsreader/features/auth/presentation/cubit/login_cubit.dart';
import 'package:newsreader/l10n/app_localizations.dart';

/// Paso 1 del login con correo: el usuario escribe su correo.
class LoginEmailEntryView extends StatefulWidget {
  final LoginEmailEntry state;

  const LoginEmailEntryView({super.key, required this.state});

  @override
  State<LoginEmailEntryView> createState() => _LoginEmailEntryViewState();
}

class _LoginEmailEntryViewState extends State<LoginEmailEntryView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.email);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => context.read<LoginCubit>().submitEmail(_controller.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = widget.state;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: state.isLoading
                ? null
                : () => context.read<LoginCubit>().back(),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.loginEmailTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          l10n.loginEmailSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          enabled: !state.isLoading,
          autofocus: true,
          autocorrect: false,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: l10n.loginEmailFieldLabel,
            errorText: state.error?.localize(l10n),
            errorMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.loginEmailLinkedAccountsHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: state.isLoading ? null : _submit,
          child: state.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.loginSendCode),
        ),
      ],
    );
  }
}
