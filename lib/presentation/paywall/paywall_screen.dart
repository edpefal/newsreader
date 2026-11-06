import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:newsreader/core/config/app_config.dart';
import 'package:newsreader/core/errors/app_error_code_localizations.dart';
import 'package:newsreader/core/navigation/external_link_launcher.dart';
import 'package:newsreader/core/subscription/subscription_plan.dart';
import 'package:newsreader/l10n/app_localizations.dart';
import 'package:newsreader/presentation/paywall/cubit/paywall_cubit.dart';
import 'package:newsreader/presentation/paywall/cubit/paywall_state.dart';
import 'package:newsreader/presentation/paywall/widgets/plan_option_card.dart';

/// Cómo se presenta el paywall: pantalla completa por debajo de 840dp,
/// diálogo centrado desde ese ancho (ver `AppPaywallLauncher`).
enum PaywallPresentation { fullScreen, dialog }

/// Ancho máximo del contenido del paywall; evita que se estire en iPad o en
/// una ventana ancha.
const double kPaywallMaxContentWidth = 480;

/// Paywall de suscripción. Necesita un [PaywallCubit] por encima en el árbol.
/// Al quedar el usuario suscrito se cierra devolviendo `true`; cerrarlo antes
/// devuelve `null` (quien lo abrió lo toma como "no suscrito").
class PaywallScreen extends StatelessWidget {
  final ExternalLinkLauncher externalLinkLauncher;
  final PaywallPresentation presentation;

  const PaywallScreen({
    super.key,
    required this.externalLinkLauncher,
    required this.presentation,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaywallCubit, PaywallState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == PaywallStatus.subscribed,
      listener: (context, state) => Navigator.of(context).pop(true),
      builder: (context, state) {
        final content = _PaywallContent(
          state: state,
          externalLinkLauncher: externalLinkLauncher,
        );
        // Mientras hay una compra o restauración en curso no se puede cerrar:
        // se perdería el resultado de una operación ya iniciada.
        return PopScope(
          canPop: !state.isBusy,
          child: switch (presentation) {
            PaywallPresentation.fullScreen => Scaffold(
              body: SafeArea(child: content),
            ),
            PaywallPresentation.dialog => Dialog(
              clipBehavior: Clip.antiAlias,
              child: content,
            ),
          },
        );
      },
    );
  }
}

class _PaywallContent extends StatelessWidget {
  final PaywallState state;
  final ExternalLinkLauncher externalLinkLauncher;

  const _PaywallContent({
    required this.state,
    required this.externalLinkLauncher,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kPaywallMaxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: l10n.commonClose,
                  icon: const Icon(Icons.close),
                  onPressed: state.isBusy
                      ? null
                      : () => Navigator.of(context).maybePop(),
                ),
              ),
              Text(l10n.paywallTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                l10n.paywallSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              switch (state.status) {
                PaywallStatus.loading => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                ),
                PaywallStatus.error => _OffersError(state: state),
                _ => _Plans(
                  state: state,
                  externalLinkLauncher: externalLinkLauncher,
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _OffersError extends StatelessWidget {
  final PaywallState state;

  const _OffersError({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final code = state.errorCode;
    return Column(
      children: [
        Text(
          code?.localize(l10n) ?? l10n.errorUnknown,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: context.read<PaywallCubit>().loadPlans,
          child: Text(l10n.paywallRetry),
        ),
      ],
    );
  }
}

class _Plans extends StatelessWidget {
  final PaywallState state;
  final ExternalLinkLauncher externalLinkLauncher;

  const _Plans({required this.state, required this.externalLinkLauncher});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final cubit = context.read<PaywallCubit>();
    final selected = state.selectedPlan;
    final isPurchasing = state.status == PaywallStatus.purchasing;

    // El anual primero: es el plan recomendado y el que lleva la prueba.
    final plans = [...state.plans]
      ..sort((a, b) => b.type.index.compareTo(a.type.index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final plan in plans) ...[
          PlanOptionCard(
            plan: plan,
            isSelected: plan.id == state.selectedPlanId,
            enabled: !state.isBusy,
            onTap: () => cubit.selectPlan(plan.id),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        if (state.errorCode case final code?) ...[
          Text(
            code.localize(l10n),
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        if (state.restoreFoundNothing) ...[
          Text(
            l10n.commonRestoreNothingFound,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
        ],
        // El texto de renovación va antes del botón de compra (requisito de
        // App Review): qué se cobra, cuándo y cómo cancelar.
        if (selected != null) ...[
          Text(
            _legalText(l10n, selected),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: selected == null || state.isBusy ? null : cubit.purchase,
          child: isPurchasing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_ctaText(l10n, selected)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: state.isBusy ? null : cubit.restore,
          child: state.status == PaywallStatus.restoring
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.commonRestorePurchases),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              onPressed: () => externalLinkLauncher.open(AppConfig.termsUrl),
              child: Text(l10n.paywallTermsLink),
            ),
            TextButton(
              onPressed: () => externalLinkLauncher.open(AppConfig.privacyUrl),
              child: Text(l10n.paywallPrivacyLink),
            ),
          ],
        ),
      ],
    );
  }

  static String _ctaText(AppLocalizations l10n, SubscriptionPlan? plan) {
    if (plan?.freeTrialDays case final days?) {
      return l10n.paywallCtaStartTrial(days);
    }
    return l10n.paywallCtaSubscribe;
  }

  static String _legalText(AppLocalizations l10n, SubscriptionPlan plan) {
    if (plan.freeTrialDays case final days?) {
      return l10n.paywallLegalTrial(days, plan.priceString);
    }
    return switch (plan.type) {
      SubscriptionPlanType.monthly => l10n.paywallLegalMonthly(
        plan.priceString,
      ),
      SubscriptionPlanType.annual => l10n.paywallLegalAnnual(plan.priceString),
    };
  }
}
