import 'package:flutter/material.dart';

import 'package:newsreader/l10n/app_localizations.dart';

class DeleteAccountDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  /// Si el usuario tiene una suscripción activa: eliminar la cuenta no la
  /// cancela, así que se le avisa. Nunca bloquea ni condiciona el borrado.
  final bool showSubscriptionNotice;

  /// Abre la gestión de suscripciones de Apple. Solo se usa con
  /// [showSubscriptionNotice].
  final VoidCallback? onManageSubscription;

  const DeleteAccountDialog({
    super.key,
    required this.onConfirm,
    this.showSubscriptionNotice = false,
    this.onManageSubscription,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.accountDeleteDialogTitle),
      content: showSubscriptionNotice
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.accountDeleteDialogBody),
                const SizedBox(height: 16),
                Text(l10n.accountDeleteSubscriptionNotice),
                if (onManageSubscription != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onManageSubscription,
                      child: Text(l10n.commonManageSubscription),
                    ),
                  ),
              ],
            )
          : Text(l10n.accountDeleteDialogBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(l10n.accountDeleteDialogTitle),
        ),
      ],
    );
  }
}
