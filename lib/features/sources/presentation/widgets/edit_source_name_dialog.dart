import 'package:flutter/material.dart';

import 'package:newsreader/l10n/app_localizations.dart';

class EditSourceNameDialog extends StatefulWidget {
  final String initialName;
  final void Function(String name) onSave;

  const EditSourceNameDialog({
    super.key,
    required this.initialName,
    required this.onSave,
  });

  @override
  State<EditSourceNameDialog> createState() =>
      _EditSourceNameDialogState();
}

class _EditSourceNameDialogState extends State<EditSourceNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.sourcesEditNameDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.sourcesEditNameFieldLabel,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            final isValid = value.text.trim().isNotEmpty;
            return TextButton(
              onPressed: isValid
                  ? () {
                      widget.onSave(_controller.text.trim());
                      Navigator.of(context).pop();
                    }
                  : null,
              child: Text(l10n.commonSave),
            );
          },
        ),
      ],
    );
  }
}
