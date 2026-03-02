import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: const Text('Eliminar fuente'),
      content: Text(
        '¿Eliminar "$sourceName"? También se eliminarán sus artículos no guardados como favoritos.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}
