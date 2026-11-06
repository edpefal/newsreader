import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/navigation/external_link_launcher.dart';
import 'package:newsreader/core/observability/telemetry_client.dart';
import 'package:newsreader/core/subscription/paywall_launcher.dart';
import 'package:newsreader/core/subscription/subscription_status_provider.dart';
import 'package:newsreader/core/utils/window_size_class.dart';
import 'package:newsreader/features/settings/domain/usecases/restore_purchases.dart';
import 'package:newsreader/features/sync/domain/usecases/sync_entitlement.dart';
import 'package:newsreader/presentation/paywall/cubit/paywall_cubit.dart';
import 'package:newsreader/presentation/paywall/paywall_screen.dart';

/// Implementación del [PaywallLauncher] a nivel de app. Por debajo de 840dp
/// (`kExpandedWidthBreakpoint`) presenta el paywall como ruta modal a pantalla
/// completa; desde 840dp, como diálogo centrado. En ambos casos usa el
/// navegador raíz, para que no quede embebido en el panel derecho del
/// master-detail de iPad ni duplique su chrome.
class AppPaywallLauncher implements PaywallLauncher {
  final SubscriptionStatusProvider _subscriptionStatusProvider;
  final SyncEntitlement _syncEntitlement;
  final RestorePurchases _restorePurchases;
  final TelemetryClient _telemetryClient;
  final ExternalLinkLauncher _externalLinkLauncher;

  const AppPaywallLauncher(
    this._subscriptionStatusProvider,
    this._syncEntitlement,
    this._restorePurchases,
    this._telemetryClient,
    this._externalLinkLauncher,
  );

  @override
  Future<bool> show(
    BuildContext context, {
    required PaywallTrigger trigger,
  }) async {
    final isExpanded = context.windowSizeClass == WindowSizeClass.expanded;

    Widget build(BuildContext _) => BlocProvider<PaywallCubit>(
      create: (_) => PaywallCubit(
        _subscriptionStatusProvider,
        _syncEntitlement,
        _restorePurchases,
        _telemetryClient,
        trigger,
      )..start(),
      child: PaywallScreen(
        externalLinkLauncher: _externalLinkLauncher,
        presentation: isExpanded
            ? PaywallPresentation.dialog
            : PaywallPresentation.fullScreen,
      ),
    );

    final subscribed = isExpanded
        ? await showDialog<bool>(context: context, builder: build)
        : await Navigator.of(context, rootNavigator: true).push<bool>(
            MaterialPageRoute(fullscreenDialog: true, builder: build),
          );
    return subscribed ?? false;
  }
}
