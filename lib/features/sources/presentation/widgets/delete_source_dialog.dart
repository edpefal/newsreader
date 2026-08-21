import 'package:flutter/material.dart';

import 'package:newsreader/l10n/app_localizations.dart';

class DeleteSourceDialog extends StatelessWidget {
  final String sourceName;
  final VoidCallback onConfirm;

  const DeleteSourceDialog({
    super.key,
    required this.sourceName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.sourcesDeleteDialogTitle),
      content: Text(l10n.sourcesDeleteDialogBody(sourceName)),
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
          child: Text(l10n.commonDelete),
        ),
      ],
    );
  }
}
