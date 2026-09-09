import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/auth/auth_client.dart';
import 'package:newsreader/core/errors/app_error_code_localizations.dart';
import 'package:newsreader/core/errors/app_exception.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/core/theme/reevo_accent.dart';
import 'package:newsreader/features/account/domain/usecases/delete_account.dart';
import 'package:newsreader/features/account/domain/usecases/export_user_data.dart';
import 'package:newsreader/features/account/presentation/widgets/delete_account_dialog.dart';
import 'package:newsreader/features/sync/domain/usecases/clear_local_user_data.dart';
import 'package:newsreader/l10n/app_localizations.dart';
import 'package:newsreader/presentation/theme/theme_cubit.dart';

/// Ancho máximo del contenido de Ajustes para que no quede pegado al borde
/// izquierdo en pantallas anchas (iPad); mismo criterio que
/// `kReaderMaxContentWidth` en el lector.
const double kSettingsMaxContentWidth = 680;

class SettingsScreen extends StatefulWidget {
  final ExportUserData exportUserData;
  final DeleteAccount deleteAccount;
  final ClearLocalUserData clearLocalUserData;
  final AuthClient authClient;
  final SubscriptionStatusProvider subscriptionStatusProvider;

  const SettingsScreen({
    super.key,
    required this.exportUserData,
    required this.deleteAccount,
    required this.clearLocalUserData,
    required this.authClient,
    required this.subscriptionStatusProvider,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextStyle? _sectionHeaderStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium;

  TextStyle? _rowTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge;

  TextStyle? _secondaryTextStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent =
        Theme.of(context).extension<ReevoAccent>()!.unreadFavoriteAccent;
    final errorColor = Theme.of(context).colorScheme.error;
    final dividerColor = Theme.of(context).colorScheme.outline;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreenTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kSettingsMaxContentWidth),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsAccountTierSectionTitle,
                  style: _sectionHeaderStyle(context),
                ),
                if (widget.authClient.currentUserEmail case final email?) ...[
                  const SizedBox(height: 4),
                  Text(email, style: _secondaryTextStyle(context)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (widget.subscriptionStatusProvider.isSubscribed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.settingsAccountTierPremium.toUpperCase(),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                        ),
                      )
                    else
                      Text(l10n.settingsAccountTierFree, style: _rowTextStyle(context)),
                    if (!widget.subscriptionStatusProvider.isSubscribed) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accent,
                          side: BorderSide(color: accent),
                        ),
                        onPressed: () => _upgradeToPremium(context),
                        child: Text(l10n.settingsAccountTierUpgradeButton),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.settingsThemeSectionTitle,
                  style: _sectionHeaderStyle(context),
                ),
                const SizedBox(height: 12),
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, themeMode) {
                    return SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(l10n.settingsThemeSystem),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(l10n.settingsThemeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(l10n.settingsThemeDark),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (selection) => context
                          .read<ThemeCubit>()
                          .setThemeMode(selection.first),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.settingsDataAndSessionSectionTitle,
                  style: _sectionHeaderStyle(context),
                ),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.ios_share),
                  title: Text(l10n.navExportData, style: _rowTextStyle(context)),
                  onTap: () => _exportUserData(context),
                ),
                Divider(height: 1, thickness: 1, color: dividerColor),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout),
                  title: Text(l10n.navSignOut, style: _rowTextStyle(context)),
                  onTap: () => _signOut(context),
                ),
                Divider(height: 1, thickness: 1, color: dividerColor),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_forever, color: errorColor),
                  title: Text(
                    l10n.accountDeleteDialogTitle,
                    style: _rowTextStyle(context)?.copyWith(color: errorColor),
                  ),
                  onTap: () => _confirmDeleteAccount(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _upgradeToPremium(BuildContext context) async {
    await widget.subscriptionStatusProvider.showPaywall(
      onSubscribed: () async {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    // Se limpian los datos locales antes de cerrar sesión para que la
    // próxima cuenta que inicie sesión en este dispositivo arranque sin
    // datos de la cuenta anterior (evita colisiones de `id` entre cuentas
    // al sincronizar).
    await widget.clearLocalUserData.execute();
    await widget.authClient.signOut();
  }

  Future<void> _exportUserData(BuildContext context) async {
    try {
      await widget.exportUserData.execute();
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.code.localize(AppLocalizations.of(context))),
          ),
        );
      }
    }
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) =>
          DeleteAccountDialog(onConfirm: () => _deleteAccount(context)),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      await widget.deleteAccount.execute();
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.code.localize(AppLocalizations.of(context))),
          ),
        );
      }
    }
  }
}
