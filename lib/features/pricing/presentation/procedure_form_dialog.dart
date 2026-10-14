import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../../../shared/formatters/numbers.dart';
import '../../../shared/validators/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_number_field.dart';
import '../../../shared/widgets/app_snack.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/searchable_dropdown.dart';
import '../application/pricing_controllers.dart';
import '../data/pricing_repository.dart';
import '../domain/pricing_calculator.dart';
import '../domain/pricing_models.dart';
import 'pricing_breakdown.dart';

/// Novo procedimento (procedure = null) ou edicao: dados, materiais x
/// quantidade e a simulacao do preco ao vivo (PricingCalculator) com a
/// escolha PF / PJ. Devolve true quando salvou.
class ProcedureFormDialog extends ConsumerStatefulWidget {
  const ProcedureFormDialog({
    super.key,
    this.procedure,
    required this.params,
    required this.summary,
    this.readOnly = false,
  });

  final Procedure? procedure;
  final PricingParams params;
  final PricingSummary summary;
  final bool readOnly;

  static Future<bool> show(
    BuildContext context, {
    Procedure? procedure,
    required PricingParams params,
    required PricingSummary summary,
    bool readOnly = false,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ProcedureFormDialog(
        procedure: procedure,
        params: params,
        summary: summary,
        readOnly: readOnly,
      ),
    );
    return saved ?? false;
  }

  @override
  ConsumerState<ProcedureFormDialog> createState() =>
      _ProcedureFormDialogState();
}

class _ProcedureFormDialogState extends ConsumerState<ProcedureFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _code = TextEditingController(text: _p?.vcCode ?? '');
  late final _name = TextEditingController(text: _p?.vcName ?? '');
  late final _category = TextEditingController(text: _p?.vcCategory ?? '');
  late final _minutes = TextEditingController(
    text: Numbers.toField(_p?.qtMinutes ?? 0, decimals: 0),
  );
  late final _lab = TextEditingController(text: Numbers.toField(_p?.vlLabCost));
  late final _other = TextEditingController(
    text: Numbers.toField(_p?.vlMaterialOther),
  );
  late final _current = TextEditingController(
    text: Numbers.toField(_p?.vlCurrentPrice),
  );
  late final _commission = TextEditingController(
    text: Numbers.toField(_p?.pcCommission),
  );
  late final _profit = TextEditingController(
    text: Numbers.toField(_p?.pcProfit),
  );
  late List<ProcedureMaterial> _materials = [...?_p?.materials];
  final Map<int, TextEditingController> _qty = {};
  late bool _active = _p?.isActive ?? true;
  late int _regime = widget.summary.itTaxRegime ?? widget.params.itTaxRegime;
  bool _saving = false;

  Procedure? get _p => widget.procedure;
  bool get _isEdit => _p != null;
  bool get _canEdit => !widget.readOnly && !_saving;

  @override
  void initState() {
    super.initState();
    for (final m in _materials) {
      _qty[m.nrMaterial] = TextEditingController(
        text: Numbers.toField(m.qtUsed, decimals: 3),
      );
    }
  }

  @override
  void dispose() {
    for (final c in [
      _code,
      _name,
      _category,
      _minutes,
      _lab,
      _other,
      _current,
      _commission,
      _profit,
      ..._qty.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) => Numbers.parse(c.text) ?? 0;

  double? _numOrNull(TextEditingController c) =>
      c.text.trim().isEmpty ? null : Numbers.parse(c.text);

  double get _materialsCost => _materials.fold<double>(
    0,
    (s, m) => s + PricingCalculator.round2(m.qtUsed * m.vlUnitCost),
  );

  PricingResult get _result => PricingCalculator.calculate(
    PricingInput(
      vlMaterial: _materialsCost + _num(_other),
      vlLab: _num(_lab),
      qtMinutes: _num(_minutes),
      vlStructureHour: widget.summary.vlStructureHour,
      vlProfessionalHour: widget.params.vlProfessionalHour,
      pcCard: widget.params.pcCard,
      pcCommission: _numOrNull(_commission) ?? widget.params.pcCommission,
      pcFees: widget.summary.pcFees,
      itTaxRegime: _regime,
      pcTax: widget.params.pcTaxFor(_regime),
      pcProfit: _numOrNull(_profit) ?? widget.params.pcProfit,
    ),
  );

  void _addMaterial(MaterialItem m) {
    if (_materials.any((x) => x.nrMaterial == m.nrMaterial)) return;
    setState(() {
      _materials = [..._materials, ProcedureMaterial.fromMaterial(m, 1)];
      _qty[m.nrMaterial] = TextEditingController(text: '1');
    });
  }

  void _setQty(int nrMaterial, String text) {
    final qty = Numbers.parse(text) ?? 0;
    setState(() {
      _materials = [
        for (final m in _materials)
          if (m.nrMaterial == nrMaterial) m.copyWith(qtUsed: qty) else m,
      ];
    });
  }

  void _removeMaterial(int nrMaterial) {
    setState(() {
      _materials = _materials.where((m) => m.nrMaterial != nrMaterial).toList();
      _qty.remove(nrMaterial)?.dispose();
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_materials.any((m) => m.qtUsed <= 0)) {
      AppSnack.error(context, Strings.mustBePositive);
      return;
    }
    setState(() => _saving = true);
    try {
      final draft = ProcedureDraft(
        vcCode: _code.text.trim().isEmpty ? null : _code.text.trim(),
        vcName: _name.text.trim(),
        vcCategory: _category.text.trim().isEmpty
            ? null
            : _category.text.trim(),
        qtMinutes: _num(_minutes),
        vlLabCost: _num(_lab),
        vlMaterialOther: _num(_other),
        vlCurrentPrice: _numOrNull(_current),
        pcCommission: _numOrNull(_commission),
        pcProfit: _numOrNull(_profit),
        itStatus: _isEdit ? (_active ? 1 : 90) : null,
        materials: _materials,
      );
      final controller = ref.read(proceduresProvider.notifier);
      if (_isEdit) {
        await controller.updateProcedure(_p!.nrProcedure, draft);
      } else {
        await controller.create(draft);
      }
      if (mounted) Navigator.of(context).pop(true);
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
    final catalog = ref.watch(materialCatalogProvider).valueOrNull ?? const [];
    final available = [
      for (final m in catalog)
        if (!_materials.any((x) => x.nrMaterial == m.nrMaterial)) m,
    ];

    final title = widget.readOnly
        ? Strings.viewProcedure
        : (_isEdit ? Strings.editProcedure : Strings.newProcedure);

    /// Dois campos lado a lado no desktop, empilhados no mobile.
    Widget pair(Widget a, Widget b) => isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [a, const SizedBox(height: AppSpacing.md), b],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: b),
            ],
          );

    final form = Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: isMobile ? 96 : 120,
                child: AppTextField(
                  label: Strings.procedureCode,
                  controller: _code,
                  maxLength: 10,
                  enabled: _canEdit,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  label: Strings.procedureName,
                  controller: _name,
                  maxLength: 80,
                  autofocus: !_isEdit,
                  enabled: _canEdit,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.required(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: Strings.category,
            hint: Strings.categoryHint,
            controller: _category,
            maxLength: 40,
            enabled: _canEdit,
            prefixIcon: Icons.category_outlined,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: AppSpacing.md),
          pair(
            AppNumberField(
              label: Strings.minutes,
              controller: _minutes,
              decimals: 0,
              suffixText: 'min',
              helper: Strings.minutesHelp,
              enabled: _canEdit,
              required: true,
              onChanged: (_) => setState(() {}),
            ),
            AppNumberField(
              label: Strings.labCost,
              controller: _lab,
              prefixText: 'R\$ ',
              enabled: _canEdit,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          pair(
            AppNumberField(
              label: Strings.materialOther,
              controller: _other,
              prefixText: 'R\$ ',
              helper: Strings.materialOtherHelp,
              enabled: _canEdit,
              onChanged: (_) => setState(() {}),
            ),
            AppNumberField(
              label: Strings.currentPrice,
              controller: _current,
              prefixText: 'R\$ ',
              helper: Strings.currentPriceHelp,
              enabled: _canEdit,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          pair(
            AppNumberField(
              label: Strings.commissionOverride,
              controller: _commission,
              suffixText: '%',
              helper: Strings.defaultValue(
                Numbers.percent(widget.params.pcCommission, decimals: 2),
              ),
              enabled: _canEdit,
              onChanged: (_) => setState(() {}),
            ),
            AppNumberField(
              label: Strings.profitOverride,
              controller: _profit,
              suffixText: '%',
              helper: Strings.defaultValue(
                Numbers.percent(widget.params.pcProfit, decimals: 2),
              ),
              enabled: _canEdit,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            Strings.materialsUsed,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_materials.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                Strings.noMaterialsInProcedure,
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _materials.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _MaterialRow(
                      material: _materials[i],
                      controller: _qty[_materials[i].nrMaterial]!,
                      enabled: _canEdit,
                      compact: isMobile,
                      onChanged: (v) => _setQty(_materials[i].nrMaterial, v),
                      onRemove: () => _removeMaterial(_materials[i].nrMaterial),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          SearchableDropdown<MaterialItem>(
            label: Strings.addMaterial,
            items: available,
            itemLabel: (m) => m.vcName,
            itemSubtitle: (m) =>
                '${m.vcPackage ?? ''} · ${Numbers.money(m.vlUnitCost, unit: true)}/${m.vcUnit ?? Strings.unit.toLowerCase()}',
            prefixIcon: Icons.add_rounded,
            enabled: _canEdit,
            onChanged: _addMaterial,
          ),
          if (_isEdit) ...[
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(Strings.procedureActive),
              value: _active,
              onChanged: _canEdit ? (v) => setState(() => _active = v) : null,
            ),
          ],
        ],
      ),
    );

    final result = _ResultPanel(
      result: _result,
      regime: _regime,
      currentPrice: _numOrNull(_current),
      params: widget.params,
      summary: widget.summary,
      pcCommission: _numOrNull(_commission) ?? widget.params.pcCommission,
      pcProfit: _numOrNull(_profit) ?? widget.params.pcProfit,
      onRegime: (r) => setState(() => _regime = r),
    );

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isMobile) ...[
                form,
                const SizedBox(height: AppSpacing.lg),
                result,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: form),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 2, child: result),
                  ],
                ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: widget.readOnly ? Strings.close : Strings.cancel,
                      variant: AppButtonVariant.secondary,
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                  ),
                  if (!widget.readOnly) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: Strings.save,
                        loading: _saving,
                        onPressed: _save,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Linha de material: nome + custo unitario, quantidade e custo da linha.
/// No mobile (compact) fica em duas linhas.
class _MaterialRow extends StatelessWidget {
  const _MaterialRow({
    required this.material,
    required this.controller,
    required this.enabled,
    required this.compact,
    required this.onChanged,
    required this.onRemove,
  });

  final ProcedureMaterial material;
  final TextEditingController controller;
  final bool enabled;
  final bool compact;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final m = material;
    final name = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          m.vcName,
          style: const TextStyle(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${Numbers.money(m.vlUnitCost, unit: true)} / ${m.vcUnit ?? Strings.unit.toLowerCase()}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    final qty = AppNumberField(
      label: Strings.quantityUsed,
      controller: controller,
      decimals: 3,
      dense: true,
      enabled: enabled,
      onChanged: onChanged,
    );
    final cost = Text(
      Numbers.money(PricingCalculator.round2(m.qtUsed * m.vlUnitCost)),
      textAlign: TextAlign.right,
      style: const TextStyle(fontWeight: FontWeight.w700),
    );
    final remove = IconButton(
      tooltip: Strings.remove,
      icon: const Icon(Icons.close_rounded, size: 20),
      onPressed: enabled ? onRemove : null,
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        child: Column(
          children: [
            Row(children: [Expanded(child: name), remove]),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                SizedBox(width: 140, child: qty),
                const Spacer(),
                cost,
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(child: name),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(width: 104, child: qty),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(width: 92, child: cost),
          remove,
        ],
      ),
    );
  }
}

/// Simulacao ao vivo com a escolha do regime.
class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.result,
    required this.regime,
    required this.currentPrice,
    required this.params,
    required this.summary,
    required this.pcCommission,
    required this.pcProfit,
    required this.onRegime,
  });

  final PricingResult result;
  final int regime;
  final double? currentPrice;
  final PricingParams params;
  final PricingSummary summary;
  final double pcCommission;
  final double pcProfit;
  final ValueChanged<int> onRegime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  Strings.simulation,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SegmentedButton<int>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
                segments: const [
                  ButtonSegment(
                    value: TaxRegime.pf,
                    label: Text(Strings.taxRegimePfShort),
                  ),
                  ButtonSegment(
                    value: TaxRegime.pj,
                    label: Text(Strings.taxRegimePjShort),
                  ),
                ],
                selected: {regime},
                onSelectionChanged: (s) => onRegime(s.first),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            regime == TaxRegime.pj
                ? Strings.taxRegimePjHelp
                : Strings.taxRegimePfHelp,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const Divider(height: AppSpacing.lg),
          PricingBreakdown(
            result: result,
            currentPrice: currentPrice,
            pcCard: params.pcCard,
            pcCommission: pcCommission,
            pcFees: summary.pcFees,
            pcTax: params.pcTaxFor(regime),
            pcProfit: pcProfit,
          ),
        ],
      ),
    );
  }
}
