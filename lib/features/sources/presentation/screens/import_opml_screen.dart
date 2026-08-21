import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/widgets/source_icon.dart';
import 'package:newsreader/features/inbox/presentation/cubit/inbox_cubit.dart';
import 'package:newsreader/features/sources/presentation/cubit/import_opml_cubit.dart';
import 'package:newsreader/l10n/app_localizations.dart';

class ImportOpmlScreen extends StatefulWidget {
  final String xmlContent;

  const ImportOpmlScreen({super.key, required this.xmlContent});

  @override
  State<ImportOpmlScreen> createState() => _ImportOpmlScreenState();
}

class _ImportOpmlScreenState extends State<ImportOpmlScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ImportOpmlCubit>().loadPreview(widget.xmlContent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<ImportOpmlCubit, ImportOpmlState>(
      listener: (context, state) {
        if (state is ImportOpmlDone) {
          final message = state.failedCount == 0
              ? l10n.sourcesOpmlImportedOnly(state.importedCount)
              : l10n.sourcesOpmlImportedWithFailures(
                  state.importedCount,
                  state.failedCount,
                );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          context.read<InboxCubit>().syncAndReload();
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.sourcesImportOpmlScreenTitle)),
          body: switch (state) {
            ImportOpmlValidating() => const _ValidatingView(),
            ImportOpmlPreview() => _PreviewView(state: state),
            ImportOpmlImporting() => const _ImportingView(),
            ImportOpmlError() => _ErrorView(message: state.message),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}

class _ValidatingView extends StatelessWidget {
  const _ValidatingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).sourcesValidatingFeeds),
        ],
      ),
    );
  }
}

class _ImportingView extends StatelessWidget {
  const _ImportingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).sourcesImportingSources),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewView extends StatelessWidget {
  final ImportOpmlPreview state;

  const _PreviewView({required this.state});

  @override
  Widget build(BuildContext context) {
    final selectedCount = state.selectedFeeds.length;
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        if (state.isValidating)
          LinearProgressIndicator(
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        Expanded(
          child: ListView.builder(
            itemCount: state.feeds.length +
                (state.isValidating ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == state.feeds.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Text(
                    l10n.sourcesValidatingMoreFeeds(state.pendingCount),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                );
              }
              final item = state.feeds[index];
              return switch (item.status) {
                OpmlFeedStatus.valid => _ValidFeedTile(item: item),
                OpmlFeedStatus.duplicate => _DuplicateFeedTile(item: item),
                OpmlFeedStatus.error => _ErrorFeedTile(item: item),
              };
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: state.hasSelection
                  ? () => context.read<ImportOpmlCubit>().confirmImport()
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(
                selectedCount > 0
                    ? l10n.sourcesImportButtonWithCount(selectedCount)
                    : l10n.sourcesImportButton,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ValidFeedTile extends StatelessWidget {
  final OpmlFeedItem item;

  const _ValidFeedTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: item.selected,
      onChanged: (_) =>
          context.read<ImportOpmlCubit>().toggleSelection(item.url),
      secondary: SourceIcon(iconUrl: item.iconUrl, name: item.name, size: 40),
      title: Text(item.name),
      subtitle: Text(
        item.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _DuplicateFeedTile extends StatelessWidget {
  final OpmlFeedItem item;

  const _DuplicateFeedTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: false,
      leading: SourceIcon(iconUrl: item.iconUrl, name: item.name, size: 40),
      title: Text(item.name),
      subtitle: Text(AppLocalizations.of(context).sourcesAlreadySubscribed),
      trailing: const Icon(Icons.check_circle_outline),
    );
  }
}

class _ErrorFeedTile extends StatelessWidget {
  final OpmlFeedItem item;

  const _ErrorFeedTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: false,
      leading: const CircleAvatar(child: Icon(Icons.error_outline)),
      title: Text(
        item.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        item.errorMessage ??
            AppLocalizations.of(context).sourcesFeedValidationFailed,
      ),
      trailing: Icon(
        Icons.warning_amber_outlined,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
