import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/errors/app_error_code_localizations.dart';
import 'package:newsreader/features/auth/presentation/cubit/login_cubit.dart';
import 'package:newsreader/l10n/app_localizations.dart';

/// Paso 2 del login con correo: el usuario escribe el código recibido.
class LoginCodeView extends StatefulWidget {
  final LoginCodeSent state;

  const LoginCodeView({super.key, required this.state});

  @override
  State<LoginCodeView> createState() => _LoginCodeViewState();
}

class _LoginCodeViewState extends State<LoginCodeView> {
  final _controller = TextEditingController();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Solo repinta el contador; el cubit no emite cada segundo.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  int get _secondsLeft {
    final ms = widget.state.resendAvailableAt
        .difference(DateTime.now())
        .inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  void _verify() => context.read<LoginCubit>().verifyCode(_controller.text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<LoginCubit>();
    final state = widget.state;
    final secondsLeft = _secondsLeft;
    final canResend = secondsLeft == 0 && !state.isLoading;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: state.isLoading ? null : cubit.back,
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.loginCodeTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          l10n.loginCodeSubtitle(state.email),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _controller,
          enabled: !state.isLoading,
          autofocus: true,
          maxLength: loginEmailCodeLength,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onSubmitted: (_) => _verify(),
          style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 6),
          decoration: InputDecoration(
            labelText: l10n.loginCodeFieldLabel,
            errorText: state.error?.localize(l10n),
            errorMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: state.isLoading ? null : _verify,
          child: state.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.loginVerifyCode),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: canResend ? cubit.resendCode : null,
          child: Text(
            secondsLeft > 0
                ? l10n.loginResendCodeIn(secondsLeft)
                : l10n.loginResendCode,
          ),
        ),
        TextButton(
          onPressed: state.isLoading ? null : cubit.back,
          child: Text(l10n.loginChangeEmail),
        ),
      ],
    );
  }
}
