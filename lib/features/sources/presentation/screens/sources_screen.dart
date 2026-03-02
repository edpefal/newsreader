import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fuentes')),
      body: const Center(child: Text('Fuentes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/sources/add'),
        tooltip: 'Agregar newsletter',
        child: const Icon(Icons.add),
      ),
    );
  }
}
