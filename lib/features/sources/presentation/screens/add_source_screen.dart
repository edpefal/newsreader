import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/di/injection.dart';
import 'package:newsreader/features/sources/domain/usecases/add_source.dart';
import 'package:newsreader/features/sources/presentation/cubit/add_source_cubit.dart';

class AddSourceScreen extends StatelessWidget {
  const AddSourceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddSourceCubit(getIt<AddSource>()),
      child: const AddSourceView(),
    );
  }
}

class AddSourceView extends StatefulWidget {
  const AddSourceView({super.key});

  @override
  State<AddSourceView> createState() => _AddSourceViewState();
}

class _AddSourceViewState extends State<AddSourceView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddSourceCubit, AddSourceState>(
      listener: (context, state) {
        if (state is AddSourceSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${state.source.name}" agregado.')),
          );
          Navigator.of(context).pop(true);
        } else if (state is AddSourceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Agregar newsletter')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pega el link de tu newsletter (o la URL del feed RSS si la tienes).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.url,
                autocorrect: false,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'URL del feed',
                  hintText: 'https://autor.substack.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.rss_feed),
                ),
                onSubmitted: (_) => _submit(context),
              ),
              const SizedBox(height: 32),
              BlocBuilder<AddSourceCubit, AddSourceState>(
                builder: (context, state) {
                  final isLoading = state is AddSourceValidating;
                  return FilledButton(
                    onPressed: isLoading ? null : () => _submit(context),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Agregar'),
                  );
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _importOpml(context),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Importar desde OPML'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    context.read<AddSourceCubit>().addSource(_controller.text);
  }

  Future<void> _importOpml(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['opml', 'xml'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final xmlContent = String.fromCharCodes(bytes);

    if (context.mounted) {
      context.push('/sources/import-opml', extra: xmlContent);
    }
  }
}
