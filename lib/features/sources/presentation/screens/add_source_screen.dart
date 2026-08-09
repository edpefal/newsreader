import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:newsreader/core/di/injection.dart';
import 'package:newsreader/core/email_feed/email_feed_generator.dart';
import 'package:newsreader/features/sources/domain/usecases/add_source.dart';
import 'package:newsreader/features/sources/domain/usecases/generate_email_feed.dart';
import 'package:newsreader/features/sources/presentation/cubit/add_source_cubit.dart';

class AddSourceScreen extends StatelessWidget {
  const AddSourceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddSourceCubit(
        getIt<AddSource>(),
        getIt<GenerateEmailFeed>(),
      ),
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
  ScaffoldMessengerState? _scaffoldMessenger;
  bool _emailCardExpanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    // Se difiere a después del frame actual: dispose() se ejecuta con el
    // árbol de widgets bloqueado, y ocultar el SnackBar dispara un setState
    // síncrono en ScaffoldMessenger que fallaría si se llama directamente acá.
    final messenger = _scaffoldMessenger;
    if (messenger != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (messenger.mounted) messenger.removeCurrentSnackBar();
      });
    }
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddSourceCubit, AddSourceState>(
      listener: (context, state) {
        if (state is AddSourceSuccess) {
          setState(() => _emailCardExpanded = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${state.source.name}" agregado.')),
          );
          Navigator.of(context).pop(state.source);
        } else if (state is AddSourceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        } else if (state is AddSourceFeedDiscoveryFailed) {
          _showFeedDiscoveryFailedSnackBar(context, state.message);
        } else if (state is AddSourceEmailFeedGenerated) {
          setState(() => _emailCardExpanded = false);
          _showGeneratedEmailDialog(context, state.feed);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Agregar newsletter')),
        body: SingleChildScrollView(
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
                  final isLoading = state is AddSourceValidating ||
                      state is AddSourceValidatingHeuristics;
                  return FilledButton(
                    onPressed: isLoading ? null : () => _submit(context),
                    child: isLoading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              if (state is AddSourceValidatingHeuristics) ...[
                                const SizedBox(width: 12),
                                const Text('Buscando en varios lugares posibles...'),
                              ],
                            ],
                          )
                        : const Text('Agregar'),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Otras formas de agregar',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              _SourceOptionCard(
                icon: Icons.upload_file_outlined,
                title: 'Importar desde OPML',
                description: 'Traé tus suscripciones desde otro lector de feeds.',
                onTap: () => _importOpml(context),
              ),
              const SizedBox(height: 12),
              BlocBuilder<AddSourceCubit, AddSourceState>(
                builder: (context, state) {
                  final isGenerating = state is AddSourceGeneratingEmailFeed;
                  return _EmailFeedCard(
                    expanded: _emailCardExpanded,
                    isGenerating: isGenerating,
                    onToggle: () => setState(
                      () => _emailCardExpanded = !_emailCardExpanded,
                    ),
                    onGenerate: isGenerating
                        ? null
                        : () => context.read<AddSourceCubit>().generateEmailFeed(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    context.read<AddSourceCubit>().addSource(_controller.text);
  }

  void _showFeedDiscoveryFailedSnackBar(BuildContext context, String message) {
    // No se usan `action`/`showCloseIcon` nativos de SnackBar: cuando están
    // presentes, SnackBar reserva ~40% del ancho para su propia fila de
    // acción y el `content` solo recibe el 60% restante, lo que rompe
    // cualquier alineación absoluta (ej. a la esquina superior derecha) que
    // se intente armar dentro del `content`. Al no declararlos, `content`
    // recibe el ancho completo y podemos controlar el layout nosotros.
    final onError = Theme.of(context).colorScheme.onError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(message)),
            SizedBox(
              width: 24,
              height: 24,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
                icon: const Icon(Icons.close),
                tooltip: 'Cerrar',
                color: onError,
                onPressed: () =>
                    ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _showGeneratedEmailDialog(
    BuildContext context,
    GeneratedEmailFeed feed,
  ) async {
    final cubit = context.read<AddSourceCubit>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dirección generada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suscribí el newsletter usando esta dirección. El primer '
              'correo puede tardar unos minutos en aparecer.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    feed.email,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined),
                  tooltip: 'Copiar',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: feed.email));
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Dirección copiada.')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.addSource(feed.feedUrl);
            },
            child: const Text('Ya me suscribí'),
          ),
        ],
      ),
    );
  }
}

class _SourceOptionCard extends StatelessWidget {
  const _SourceOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailFeedCard extends StatelessWidget {
  const _EmailFeedCard({
    required this.expanded,
    required this.isGenerating,
    required this.onToggle,
    required this.onGenerate,
  });

  final bool expanded;
  final bool isGenerating;
  final VoidCallback onToggle;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.mail_outline, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generar dirección de email',
                            style: textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Para newsletters sin RSS: los correos se '
                            'convierten en artículos.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Te damos una dirección única. Suscribí el newsletter '
                    'con ella y cada correo que llegue aparecerá acá.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: onGenerate,
                      child: isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Generar dirección de email'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
