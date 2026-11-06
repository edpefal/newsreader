import 'package:flutter/material.dart';

import 'package:newsreader/core/subscription/subscription_plan.dart';
import 'package:newsreader/core/theme/reevo_accent.dart';
import 'package:newsreader/l10n/app_localizations.dart';

/// Opción seleccionable de un plan en el paywall. El precio llega formateado
/// por la tienda; la prueba gratis solo se muestra si [plan] la trae (es decir,
/// si el usuario es elegible).
class PlanOptionCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const PlanOptionCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent =
        theme.extension<ReevoAccent>()?.unreadFavoriteAccent ??
        colorScheme.primary;

    final title = switch (plan.type) {
      SubscriptionPlanType.monthly => l10n.paywallPlanMonthly,
      SubscriptionPlanType.annual => l10n.paywallPlanAnnual,
    };
    final price = switch (plan.type) {
      SubscriptionPlanType.monthly => l10n.paywallPricePerMonth(
        plan.priceString,
      ),
      SubscriptionPlanType.annual => l10n.paywallPricePerYear(plan.priceString),
    };

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: enabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accent : colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? accent : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        price,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (plan.freeTrialDays case final days?)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.paywallFreeTrialBadge(days),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
