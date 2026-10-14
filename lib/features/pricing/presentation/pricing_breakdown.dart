import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../../../shared/formatters/numbers.dart';
import '../domain/pricing_models.dart';

/// Composicao do preco de um procedimento: custos, percentuais e o preco
/// sugerido. Usada na simulacao do formulario e no detalhe do procedimento.
class PricingBreakdown extends StatelessWidget {
  const PricingBreakdown({
    super.key,
    required this.result,
    this.currentPrice,
    this.pcCard,
    this.pcCommission,
    this.pcFees,
    this.pcTax,
    this.pcProfit,
  });

  final PricingResult result;
  final double? currentPrice;
  final double? pcCard;
  final double? pcCommission;
  final double? pcFees;
  final double? pcTax;
  final double? pcProfit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = result;
    final diff = currentPrice == null || r.vlPrice == null
        ? null
        : r.vlPrice! - currentPrice!;
    final taxLabel = r.itTaxRegime == TaxRegime.pj
        ? '${Strings.incomeTax} (${Strings.taxRegimePjShort})'
        : '${Strings.incomeTax} (${Strings.taxRegimePfShort})';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Line(Strings.materialsCost, Numbers.money(r.vlMaterial)),
        _Line(Strings.labCostShort, Numbers.money(r.vlLab)),
        _Line(Strings.structureCost, Numbers.money(r.vlStructure)),
        _Line(Strings.professionalCost, Numbers.money(r.vlProfessional)),
        _Line(Strings.directCost, Numbers.money(r.vlDirectCost), strong: true),
        const Divider(height: AppSpacing.lg),
        if (!r.idValid)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    Strings.priceInvalid,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ],
            ),
          )
        else ...[
          _Line(_pct(Strings.cardFee, pcCard), Numbers.money(r.vlCard)),
          _Line(_pct(Strings.commission, pcCommission), Numbers.money(r.vlCommission)),
          _Line(_pct(Strings.extraFees, pcFees), Numbers.money(r.vlFees)),
          _Line(_pct(taxLabel, pcTax), Numbers.money(r.vlTax)),
          _Line(
            '${Strings.profit} (${Numbers.percent(r.pcProfitReal)})',
            Numbers.money(r.vlProfit),
            strong: true,
            color: AppColors.success,
          ),
          const Divider(height: AppSpacing.lg),
          _Line(
            Strings.minPrice,
            Numbers.money(r.vlPriceMin),
            help: Strings.minPriceHelp,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    Strings.suggestedPrice,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  Numbers.money(r.vlPrice),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (diff != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _Line(
              '${Strings.diffToCurrent} (${Numbers.money(currentPrice)})',
              '${diff >= 0 ? '+' : ''}${Numbers.money(diff)}',
              color: diff >= 0 ? AppColors.success : AppColors.danger,
            ),
          ],
        ],
      ],
    );
  }

  static String _pct(String label, double? pc) =>
      pc == null ? label : '$label (${Numbers.percent(pc, decimals: 2)})';
}

class _Line extends StatelessWidget {
  const _Line(
    this.label,
    this.value, {
    this.strong = false,
    this.color,
    this.help,
  });

  final String label;
  final String value;
  final bool strong;
  final Color? color;
  final String? help;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
      color: color ?? (strong ? AppColors.ink : AppColors.muted),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: style),
                if (help != null)
                  Text(
                    help!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            value,
            style: style?.copyWith(
              fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
              color: color ?? AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chips de alerta do procedimento.
class ProcedureAlertChips extends StatelessWidget {
  const ProcedureAlertChips({super.key, required this.alerts});

  final List<String> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final a in alerts)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 13,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  ProcedureAlert.label(a),
                  style: const TextStyle(
                    color: Color(0xFF8A5A0B),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
