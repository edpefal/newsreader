import 'package:flutter/material.dart';

/// Estado vacío mostrado cuando una búsqueda activa no arroja resultados,
/// distinguible del estado vacío "sin artículos" de cada pantalla.
class NoSearchResultsState extends StatelessWidget {
  const NoSearchResultsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin resultados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
