import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../../../shared/formatters/numbers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_number_field.dart';
import '../../../shared/widgets/app_snack.dart';
import '../application/pricing_controllers.dart';
import '../domain/pricing_calculator.dart';
import '../domain/pricing_models.dart';

/// Fatores do preco que podem ser alterados onde aparecem.
enum PricingFactor {
  structure,
  professional,
  card,
  commission,
  fees,
  tax,
  profit;

  String get label => switch (this) {
    structure => Strings.structureHour,
    professional => Strings.professionalHour,
    card => Strings.cardRate,
    commission => Strings.commissionRate,
    fees => Strings.paramsFeesTitle,
    tax => Strings.taxRegime,
    profit => Strings.profitRate,
  };

  IconData get icon => switch (this) {
    structure => Icons.apartment_rounded,
    professional => Icons.person_outline_rounded,
    card => Icons.credit_card_rounded,
    commission => Icons.handshake_outlined,
    fees => Icons.percent_rounded,
    tax => Icons.account_balance_outlined,
    profit => Icons.trending_up_rounded,
  };

  /// Comissao e lucro aceitam um valor so para o procedimento.
  bool get hasOverride => this == commission || this == profit;
}

/// Resultado: parametros da filial ja salvos e, para comissao/lucro, o valor
/// "so neste procedimento" (null = padrao da filial).
class FactorEditResult {
  const FactorEditResult({
    required this.data,
    this.overrideValue,
    this.overrideChanged = false,
  });

  final PricingParamsData data;
  final double? overrideValue;
  final bool overrideChanged;
}

/// Edita UM fator do preco (estrutura, hora clinica, cartao, comissao, taxas,
/// regime/IR ou lucro) sem sair da tela: salva em pricing_param_save e devolve
/// os dados atualizados. Devolve null quando cancelado.
class FactorEditDialog extends ConsumerStatefulWidget {
  const FactorEditDialog({
    super.key,
    required this.factor,
    this.overrideValue,
    this.withOverride = false,
  });

  final PricingFactor factor;

  /// Valor atual "so neste procedimento" (comissao/lucro), quando aplicavel.
  final double? overrideValue;
  final bool withOverride;

  static Future<FactorEditResult?> show(
    BuildContext context, {
    required PricingFactor factor,
    double? overrideValue,
    bool withOverride = false,
  }) => showDialog<FactorEditResult>(
    context: context,
    builder: (_) => FactorEditDialog(
      factor: factor,
      overrideValue: overrideValue,
      withOverride: withOverride && factor.hasOverride,
    ),
  );

  @override
  ConsumerState<FactorEditDialog> createState() => _FactorEditDialogState();
}

class _FeeRow {
  _FeeRow(this.fee)
    : name = TextEditingController(text: fee.vcName),
      rate = TextEditingController(
        text: fee.pcRate == 0 ? '' : Numbers.toField(fee.pcRate),
      ),
      active = fee.idActive;

  final PricingFee fee;
  final TextEditingController name;
  final TextEditingController rate;
  bool active;

  PricingFee toFee() => fee.copyWith(
    vcName: name.text.trim(),
    pcRate: Numbers.parse(rate.text) ?? 0,
    idActive: active,
  );

  void dispose() {
    name.dispose();
    rate.dispose();
  }
}

class _FactorEditDialogState extends ConsumerState<FactorEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _c = {};
  PricingParamsData? _source;
  List<_FeeRow> _fees = [];
  int _regime = TaxRegime.pf;
  bool _saving = false;

  PricingFactor get _f => widget.factor;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    for (final r in _fees) {
      r.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrl(String key, String text) =>
      _c.putIfAbsent(key, () => TextEditingController(text: text));

  void _load(PricingParamsData data) {
    _source = data;
    final p = data.params;
    _regime = p.itTaxRegime;
    _ctrl('manual', Numbers.toField(p.vlStructureHourManual));
    _ctrl('rooms', Numbers.toField(p.qtRooms, decimals: 0));
    _ctrl('hours', Numbers.toField(p.qtHoursWeek));
    _ctrl('weeks', Numbers.toField(p.qtWeeksMonth));
    _ctrl('occupancy', Numbers.toField(p.pcOccupancy));
    _ctrl('professional', Numbers.toField(p.vlProfessionalHour));
    _ctrl('card', Numbers.toField(p.pcCard));
    _ctrl('commission', Numbers.toField(p.pcCommission));
    _ctrl('profit', Numbers.toField(p.pcProfit));
    _ctrl('taxPf', Numbers.toField(p.pcTaxPf));
    _ctrl('taxPj', Numbers.toField(p.pcTaxPj));
    _ctrl('override', Numbers.toField(widget.overrideValue));
    for (final r in _fees) {
      r.dispose();
    }
    _fees = [for (final f in data.fees) _FeeRow(f)];
  }

  double _num(String key) => Numbers.parse(_c[key]!.text) ?? 0;

  double? _numOrNull(String key) =>
      _c[key]!.text.trim().isEmpty ? null : Numbers.parse(_c[key]!.text);

  PricingParams _edited(PricingParams p) => switch (_f) {
    PricingFactor.structure => p.copyWith(
      qtRooms: _num('rooms').round(),
      qtHoursWeek: _num('hours'),
      qtWeeksMonth: _num('weeks'),
      pcOccupancy: _num('occupancy'),
      vlStructureHourManual: _numOrNull('manual'),
      clearStructureManual: _numOrNull('manual') == null,
    ),
    PricingFactor.professional => p.copyWith(
      vlProfessionalHour: _num('professional'),
    ),
    PricingFactor.card => p.copyWith(pcCard: _num('card')),
    PricingFactor.commission => p.copyWith(pcCommission: _num('commission')),
    PricingFactor.fees => p,
    PricingFactor.tax => p.copyWith(
      itTaxRegime: _regime,
      pcTaxPf: _num('taxPf'),
      pcTaxPj: _num('taxPj'),
    ),
    PricingFactor.profit => p.copyWith(pcProfit: _num('profit')),
  };

  Future<void> _save() async {
    final data = _source;
    if (data == null || _saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_f == PricingFactor.fees &&
        _fees.any((r) => r.name.text.trim().isEmpty)) {
      AppSnack.error(
        context,
        Strings.errorMessage('PRICING_FEE_NAME_REQUIRED', const {}),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(pricingParamsProvider.notifier)
          .save(
            params: _edited(data.params),
            fees: _f == PricingFactor.fees
                ? [for (final r in _fees) r.toFee()]
                : null,
          );
      final fresh = await ref.read(pricingParamsProvider.future);
      if (!mounted) return;
      final override = widget.withOverride ? _numOrNull('override') : null;
      Navigator.of(context).pop(
        FactorEditResult(
          data: fresh ?? data,
          overrideValue: override,
          overrideChanged:
              widget.withOverride && override != widget.overrideValue,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnack.error(context, describeError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = context.isMobile;
    final async = ref.watch(pricingParamsProvider);

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.xxl),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _f == PricingFactor.fees || _f == PricingFactor.structure
              ? 640
              : 480,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
          child: async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => AppEmptyState.error(
              message: describeError(e),
              onRetry: () => ref.invalidate(pricingParamsProvider),
            ),
            data: (data) {
              if (data == null) return const SizedBox.shrink();
              if (!identical(data, _source)) _load(data);
              final canEdit =
                  (data.params.idSaved
                      ? data.permission.idUpdate
                      : data.permission.idCreate) &&
                  !_saving;
              return Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(_f.icon, color: AppColors.primaryDark),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _f.label,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      Strings.appliesToBranch,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _body(data, canEdit),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: Strings.cancel,
                            variant: AppButtonVariant.secondary,
                            onPressed: _saving
                                ? null
                                : () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            label: Strings.save,
                            loading: _saving,
                            onPressed: canEdit ? _save : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _body(PricingParamsData data, bool canEdit) {
    void refresh(String _) => setState(() {});
    switch (_f) {
      case PricingFactor.structure:
        final calc = PricingCalculator.structureHour(
          monthlyCost: data.summary.vlMonthlyCost,
          rooms: _num('rooms').round(),
          hoursWeek: _num('hours'),
          weeksMonth: _num('weeks'),
          pcOccupancy: _num('occupancy'),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNumberField(
              label: Strings.structureManual,
              controller: _c['manual'],
              prefixText: 'R\$ ',
              helper: Strings.structureManualHelp,
              enabled: canEdit,
              onChanged: refresh,
            ),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(
              label: Strings.structureCalc,
              value: '${Numbers.money(calc)}${Strings.perHour}',
              detail:
                  '${Strings.monthlyCost}: ${Numbers.money(data.summary.vlMonthlyCost)}${Strings.perMonth}',
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SizedBox(
                  width: 140,
                  child: AppNumberField(
                    label: Strings.rooms,
                    controller: _c['rooms'],
                    decimals: 0,
                    required: true,
                    positive: true,
                    enabled: canEdit,
                    onChanged: refresh,
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: AppNumberField(
                    label: Strings.hoursWeek,
                    controller: _c['hours'],
                    suffixText: 'h',
                    required: true,
                    positive: true,
                    enabled: canEdit,
                    onChanged: refresh,
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: AppNumberField(
                    label: Strings.weeksMonth,
                    controller: _c['weeks'],
                    required: true,
                    positive: true,
                    enabled: canEdit,
                    onChanged: refresh,
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: AppNumberField(
                    label: Strings.occupancy,
                    controller: _c['occupancy'],
                    suffixText: '%',
                    required: true,
                    positive: true,
                    enabled: canEdit,
                    onChanged: refresh,
                  ),
                ),
              ],
            ),
          ],
        );
      case PricingFactor.professional:
        return AppNumberField(
          label: Strings.professionalHour,
          controller: _c['professional'],
          prefixText: 'R\$ ',
          helper: Strings.professionalHourHelp,
          required: true,
          enabled: canEdit,
          autofocus: true,
        );
      case PricingFactor.card:
        return AppNumberField(
          label: Strings.cardRate,
          controller: _c['card'],
          suffixText: '%',
          helper: Strings.cardRateHelp,
          required: true,
          enabled: canEdit,
          autofocus: true,
        );
      case PricingFactor.commission:
      case PricingFactor.profit:
        final key = _f == PricingFactor.commission ? 'commission' : 'profit';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.withOverride) ...[
              AppNumberField(
                label: '${Strings.onlyThisProcedure} (%)',
                controller: _c['override'],
                suffixText: '%',
                helper: Strings.onlyThisProcedureHelp,
                enabled: !_saving,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppNumberField(
              label: '${Strings.branchDefault} (%)',
              controller: _c[key],
              suffixText: '%',
              helper: _f == PricingFactor.commission
                  ? Strings.commissionRateHelp
                  : null,
              required: true,
              enabled: canEdit,
              autofocus: !widget.withOverride,
            ),
          ],
        );
      case PricingFactor.tax:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: TaxRegime.pf,
                  label: Text(Strings.taxRegimePf),
                  icon: Icon(Icons.person_outline_rounded),
                ),
                ButtonSegment(
                  value: TaxRegime.pj,
                  label: Text(Strings.taxRegimePj),
                  icon: Icon(Icons.business_outlined),
                ),
              ],
              selected: {_regime},
              onSelectionChanged: canEdit
                  ? (s) => setState(() => _regime = s.first)
                  : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _regime == TaxRegime.pj
                  ? Strings.taxRegimePjHelp
                  : Strings.taxRegimePfHelp,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            AppNumberField(
              label: Strings.taxPf,
              controller: _c['taxPf'],
              suffixText: '%',
              helper: Strings.taxPfHelp,
              required: true,
              enabled: canEdit,
            ),
            const SizedBox(height: AppSpacing.md),
            AppNumberField(
              label: Strings.taxPj,
              controller: _c['taxPj'],
              suffixText: '%',
              helper: Strings.taxPjHelp,
              required: true,
              enabled: canEdit,
            ),
          ],
        );
      case PricingFactor.fees:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              Strings.feesHelp,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_fees.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  Strings.noFees,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            for (final r in _fees)
              Padding(
                key: ObjectKey(r),
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Switch(
                          value: r.active,
                          onChanged: canEdit
                              ? (v) => setState(() => r.active = v)
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: TextFormField(
                            controller: r.name,
                            enabled: canEdit,
                            maxLength: 60,
                            decoration: const InputDecoration(
                              labelText: Strings.feeName,
                              isDense: true,
                              counterText: '',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: 104,
                          child: AppNumberField(
                            label: Strings.feeRate,
                            controller: r.rate,
                            suffixText: '%',
                            dense: true,
                            enabled: canEdit,
                            onChanged: refresh,
                          ),
                        ),
                        IconButton(
                          tooltip: Strings.remove,
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: canEdit
                              ? () => setState(() {
                                  _fees = _fees.where((x) => x != r).toList();
                                  r.dispose();
                                })
                              : null,
                        ),
                      ],
                    ),
                    if (r.fee.vcHint != null && r.fee.vcHint!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 60, right: 48),
                        child: Text(
                          r.fee.vcHint!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ),
                  ],
                ),
              ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: canEdit
                      ? () => setState(
                          () => _fees = [
                            ..._fees,
                            _FeeRow(
                              const PricingFee(vcName: '', idActive: true),
                            ),
                          ],
                        )
                      : null,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(Strings.addFee),
                ),
                const Spacer(),
                Text(
                  '${Strings.extraFees}: ${Numbers.percent(PricingCalculator.activeFees([for (final r in _fees) r.toFee()]), decimals: 2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.detail});

  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
