import 'package:flutter/material.dart';

import 'package:newsreader/l10n/app_localizations.dart';

/// Diálogo mostrado cuando el flush de cambios pendientes antes de cerrar
/// sesión falla (sin red, Supabase caído). Devuelve `true` (vía
/// `Navigator.pop`) si el usuario decide cerrar sesión de todos modos,
/// `false`/`null` si cancela.
class SignOutUnsyncedChangesDialog extends StatelessWidget {
  const SignOutUnsyncedChangesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.settingsSignOutUnsyncedTitle),
      content: Text(l10n.settingsSignOutUnsyncedBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(l10n.settingsSignOutUnsyncedConfirm),
        ),
      ],
    );
  }
}
