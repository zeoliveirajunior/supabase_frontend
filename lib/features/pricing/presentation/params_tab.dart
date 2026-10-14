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

/// Aba Parametros: estrutura da clinica, hora do profissional, percentuais
/// (cartao, comissao, lucro, regime PF/PJ), custos da clinica (despesas) e
/// taxas adicionais. Tudo editado localmente e salvo de uma vez; o resumo
/// (custo mensal, horas produtivas, estrutura/hora, total %) e recalculado
/// ao vivo com o PricingCalculator.
class ParamsTab extends ConsumerStatefulWidget {
  const ParamsTab({super.key});

  @override
  ConsumerState<ParamsTab> createState() => _ParamsTabState();
}

class _ExpenseRow {
  _ExpenseRow(this.id, this.itType, String name, double amount)
    : name = TextEditingController(text: name),
      amount = TextEditingController(
        text: amount == 0 ? '' : Numbers.toField(amount),
      );

  final int id;
  final int itType;
  final TextEditingController name;
  final TextEditingController amount;

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

class _FeeRow {
  _FeeRow(this.id, String name, this.hint, double rate, this.active)
    : name = TextEditingController(text: name),
      rate = TextEditingController(
        text: rate == 0 ? '' : Numbers.toField(rate),
      );

  final int id;
  final TextEditingController name;
  final TextEditingController rate;
  final String? hint;
  bool active;

  void dispose() {
    name.dispose();
    rate.dispose();
  }
}

class _ParamsTabState extends ConsumerState<ParamsTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  PricingParamsData? _source;
  late PricingParams _params;
  final Map<String, TextEditingController> _c = {};
  List<_ExpenseRow> _expenses = [];
  List<_FeeRow> _fees = [];
  int _regime = TaxRegime.pf;
  int _nextId = 0;
  bool _saving = false;

  static const _fields = [
    'qtRooms',
    'qtHoursWeek',
    'qtWeeksMonth',
    'pcOccupancy',
    'vlProfessionalHour',
    'pcCard',
    'pcCommission',
    'pcTaxPf',
    'pcTaxPj',
    'pcProfit',
    'vlStructureHourManual',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _disposeAll();
    super.dispose();
  }

  void _disposeAll() {
    for (final c in _c.values) {
      c.dispose();
    }
    _c.clear();
    for (final e in _expenses) {
      e.dispose();
    }
    for (final f in _fees) {
      f.dispose();
    }
  }

  void _load(PricingParamsData data) {
    _disposeAll();
    _source = data;
    final p = data.params;
    _params = p;
    _regime = p.itTaxRegime;
    final values = <String, String>{
      'qtRooms': Numbers.toField(p.qtRooms, decimals: 0),
      'qtHoursWeek': Numbers.toField(p.qtHoursWeek),
      'qtWeeksMonth': Numbers.toField(p.qtWeeksMonth),
      'pcOccupancy': Numbers.toField(p.pcOccupancy),
      'vlProfessionalHour': Numbers.toField(p.vlProfessionalHour),
      'pcCard': Numbers.toField(p.pcCard),
      'pcCommission': Numbers.toField(p.pcCommission),
      'pcTaxPf': Numbers.toField(p.pcTaxPf),
      'pcTaxPj': Numbers.toField(p.pcTaxPj),
      'pcProfit': Numbers.toField(p.pcProfit),
      'vlStructureHourManual': Numbers.toField(p.vlStructureHourManual),
    };
    for (final f in _fields) {
      _c[f] = TextEditingController(text: values[f]);
    }
    _expenses = [
      for (final e in data.expenses)
        _ExpenseRow(_nextId++, e.itType, e.vcName, e.vlAmount),
    ];
    _fees = [
      for (final f in data.fees)
        _FeeRow(_nextId++, f.vcName, f.vcHint, f.pcRate, f.idActive),
    ];
  }

  double _num(String field) => Numbers.parse(_c[field]!.text) ?? 0;

  double? _numOrNull(String field) =>
      _c[field]!.text.trim().isEmpty ? null : Numbers.parse(_c[field]!.text);

  PricingParams get _edited => _params.copyWith(
    qtRooms: _num('qtRooms').round(),
    qtHoursWeek: _num('qtHoursWeek'),
    qtWeeksMonth: _num('qtWeeksMonth'),
    pcOccupancy: _num('pcOccupancy'),
    vlProfessionalHour: _num('vlProfessionalHour'),
    pcCard: _num('pcCard'),
    pcCommission: _num('pcCommission'),
    itTaxRegime: _regime,
    pcTaxPf: _num('pcTaxPf'),
    pcTaxPj: _num('pcTaxPj'),
    pcProfit: _num('pcProfit'),
    vlStructureHourManual: _numOrNull('vlStructureHourManual'),
    clearStructureManual: _numOrNull('vlStructureHourManual') == null,
  );

  List<ClinicExpense> get _editedExpenses => [
    for (final e in _expenses)
      ClinicExpense(
        vcName: e.name.text.trim(),
        itType: e.itType,
        vlAmount: Numbers.parse(e.amount.text) ?? 0,
      ),
  ];

  List<PricingFee> get _editedFees => [
    for (final f in _fees)
      PricingFee(
        vcName: f.name.text.trim(),
        vcHint: f.hint,
        pcRate: Numbers.parse(f.rate.text) ?? 0,
        idActive: f.active,
      ),
  ];

  void _addExpense(int type) => setState(
    () => _expenses = [..._expenses, _ExpenseRow(_nextId++, type, '', 0)],
  );

  void _removeExpense(_ExpenseRow row) => setState(() {
    _expenses = _expenses.where((e) => e != row).toList();
    row.dispose();
  });

  void _addFee() =>
      setState(() => _fees = [..._fees, _FeeRow(_nextId++, '', null, 0, true)]);

  void _removeFee(_FeeRow row) => setState(() {
    _fees = _fees.where((f) => f != row).toList();
    row.dispose();
  });

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_expenses.any((e) => e.name.text.trim().isEmpty)) {
      AppSnack.error(
        context,
        Strings.errorMessage('PRICING_EXPENSE_NAME_REQUIRED', const {}),
      );
      return;
    }
    if (_fees.any((f) => f.name.text.trim().isEmpty)) {
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
          .save(params: _edited, expenses: _editedExpenses, fees: _editedFees);
      if (mounted) AppSnack.success(context, Strings.paramsSaved);
    } catch (e) {
      if (mounted) AppSnack.error(context, describeError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen(pricingParamsProvider, (_, next) {
      final d = next.valueOrNull;
      if (d != null && !identical(d, _source)) setState(() => _load(d));
    });
    final async = ref.watch(pricingParamsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppEmptyState.error(
        message: describeError(e),
        onRetry: () => ref.invalidate(pricingParamsProvider),
      ),
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        if (!identical(data, _source)) _load(data);
        return _content(context, data);
      },
    );
  }

  Widget _content(BuildContext context, PricingParamsData data) {
    final theme = Theme.of(context);
    final isMobile = context.isMobile;
    final canEdit =
        (data.params.idSaved
            ? data.permission.idUpdate
            : data.permission.idCreate) &&
        !_saving;
    final edited = _edited;
    final monthly = PricingCalculator.monthlyCost(_editedExpenses);
    final structureCalc = PricingCalculator.structureHour(
      monthlyCost: monthly,
      rooms: edited.qtRooms,
      hoursWeek: edited.qtHoursWeek,
      weeksMonth: edited.qtWeeksMonth,
      pcOccupancy: edited.pcOccupancy,
    );
    final structureHour = edited.vlStructureHourManual ?? structureCalc;
    final pcFees = PricingCalculator.activeFees(_editedFees);
    final total =
        edited.pcCard +
        edited.pcCommission +
        pcFees +
        edited.pcTax +
        edited.pcProfit;
    final valid = PricingCalculator.calculate(
      PricingInput(
        vlMaterial: 100,
        pcCard: edited.pcCard,
        pcCommission: edited.pcCommission,
        pcFees: pcFees,
        itTaxRegime: _regime,
        pcTax: edited.pcTax,
        pcProfit: edited.pcProfit,
      ),
    ).idValid;

    double fieldWidth() => isMobile ? double.infinity : 220;
    void refresh(String _) => setState(() {});

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!data.params.idSaved)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      color: AppColors.primaryDark,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(Strings.paramsNotSaved)),
                  ],
                ),
              ),
            _SummaryCard(
              monthly: monthly,
              productiveHours: edited.qtProductiveHours,
              structureHour: structureHour,
              total: total,
              valid: valid,
              regime: _regime,
            ),
            const SizedBox(height: AppSpacing.md),
            _Section(
              title: Strings.paramsStructureTitle,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: fieldWidth(),
                    child: AppNumberField(
                      label: Strings.rooms,
                      controller: _c['qtRooms'],
                      decimals: 0,
                      required: true,
                      positive: true,
                      enabled: canEdit,
                      onChanged: refresh,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth(),
                    child: AppNumberField(
                      label: Strings.hoursWeek,
                      controller: _c['qtHoursWeek'],
                      suffixText: 'h',
                      required: true,
                      positive: true,
                      enabled: canEdit,
                      onChanged: refresh,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth(),
                    child: AppNumberField(
                      label: Strings.weeksMonth,
                      controller: _c['qtWeeksMonth'],
                      required: true,
                      positive: true,
                      enabled: canEdit,
                      onChanged: refresh,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth(),
                    child: AppNumberField(
                      label: Strings.occupancy,
                      controller: _c['pcOccupancy'],
                      suffixText: '%',
                      helper: Strings.occupancyHelp,
                      required: true,
                      positive: true,
                      enabled: canEdit,
                      onChanged: refresh,
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? double.infinity : 300,
                    child: AppNumberField(
                      label: Strings.structureManual,
                      controller: _c['vlStructureHourManual'],
                      prefixText: 'R\$ ',
                      helper:
                          '${Strings.structureCalc}: ${Numbers.money(structureCalc)}${Strings.perHour}. ${Strings.structureManualHelp}',
                      enabled: canEdit,
                      onChanged: refresh,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Section(
              title: Strings.paramsProfessionalTitle,
              child: SizedBox(
                width: isMobile ? double.infinity : 300,
                child: AppNumberField(
                  label: Strings.professionalHour,
                  controller: _c['vlProfessionalHour'],
                  prefixText: 'R\$ ',
                  helper: Strings.professionalHourHelp,
                  required: true,
                  enabled: canEdit,
                  onChanged: refresh,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Section(
              title: Strings.paramsPercentTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      SizedBox(
                        width: fieldWidth(),
                        child: AppNumberField(
                          label: Strings.cardRate,
                          controller: _c['pcCard'],
                          suffixText: '%',
                          helper: Strings.cardRateHelp,
                          required: true,
                          enabled: canEdit,
                          onChanged: refresh,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth(),
                        child: AppNumberField(
                          label: Strings.commissionRate,
                          controller: _c['pcCommission'],
                          suffixText: '%',
                          helper: Strings.commissionRateHelp,
                          required: true,
                          enabled: canEdit,
                          onChanged: refresh,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth(),
                        child: AppNumberField(
                          label: Strings.profitRate,
                          controller: _c['pcProfit'],
                          suffixText: '%',
                          required: true,
                          enabled: canEdit,
                          onChanged: refresh,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    Strings.taxRegime,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      SizedBox(
                        width: fieldWidth(),
                        child: AppNumberField(
                          label: Strings.taxPf,
                          controller: _c['pcTaxPf'],
                          suffixText: '%',
                          helper: Strings.taxPfHelp,
                          required: true,
                          enabled: canEdit,
                          onChanged: refresh,
                        ),
                      ),
                      SizedBox(
                        width: fieldWidth(),
                        child: AppNumberField(
                          label: Strings.taxPj,
                          controller: _c['pcTaxPj'],
                          suffixText: '%',
                          helper: Strings.taxPjHelp,
                          required: true,
                          enabled: canEdit,
                          onChanged: refresh,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Section(
              title: Strings.paramsExpensesTitle,
              help: Strings.expensesHelp,
              trailing: Text(
                '${Numbers.money(monthly)}${Strings.perMonth}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final type in ExpenseType.all) ...[
                    _ExpenseGroup(
                      type: type,
                      rows: _expenses.where((e) => e.itType == type).toList(),
                      enabled: canEdit,
                      onChanged: refresh,
                      onAdd: () => _addExpense(type),
                      onRemove: _removeExpense,
                    ),
                    if (type != ExpenseType.all.last)
                      const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _Section(
              title: Strings.paramsFeesTitle,
              help: Strings.feesHelp,
              trailing: Text(
                Numbers.percent(pcFees, decimals: 2),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final f in _fees)
                    _FeeTile(
                      key: ValueKey(f.id),
                      row: f,
                      enabled: canEdit,
                      onChanged: refresh,
                      onToggle: (v) => setState(() => f.active = v),
                      onRemove: () => _removeFee(f),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: canEdit ? _addFee : null,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text(Strings.addFee),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: Strings.save,
                icon: Icons.save_outlined,
                expanded: isMobile,
                loading: _saving,
                onPressed: canEdit ? _save : null,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.monthly,
    required this.productiveHours,
    required this.structureHour,
    required this.total,
    required this.valid,
    required this.regime,
  });

  final double monthly;
  final double productiveHours;
  final double structureHour;
  final double total;
  final bool valid;
  final int regime;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label, String value, {Color? color}) =>
        SizedBox(
          width: 230,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: color ?? AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          children: [
            item(
              Icons.account_balance_wallet_outlined,
              Strings.monthlyCost,
              '${Numbers.money(monthly)}${Strings.perMonth}',
            ),
            item(
              Icons.schedule_rounded,
              Strings.productiveHours,
              '${Numbers.qty(productiveHours, decimals: 1)} h',
            ),
            item(
              Icons.apartment_rounded,
              Strings.structureHour,
              '${Numbers.money(structureHour)}${Strings.perHour}',
              color: AppColors.primaryDark,
            ),
            item(
              Icons.percent_rounded,
              '${Strings.totalPercent} (${regime == TaxRegime.pj ? Strings.taxRegimePjShort : Strings.taxRegimePfShort})',
              Numbers.percent(total, decimals: 2),
              color: valid ? AppColors.success : AppColors.danger,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.help,
    this.trailing,
  });

  final String title;
  final Widget child;
  final String? help;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (help != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                help!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _ExpenseGroup extends StatelessWidget {
  const _ExpenseGroup({
    required this.type,
    required this.rows,
    required this.enabled,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
  });

  final int type;
  final List<_ExpenseRow> rows;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onAdd;
  final ValueChanged<_ExpenseRow> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = rows.fold<double>(
      0,
      (s, e) => s + (Numbers.parse(e.amount.text) ?? 0),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ExpenseType.label(type),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            Text(
              '${Strings.subtotal}: ${Numbers.money(subtotal)}'
              '${type == ExpenseType.annual ? '/ano' : Strings.perMonth}',
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final e in rows)
          Padding(
            key: ValueKey(e.id),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: e.name,
                    enabled: enabled,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: Strings.expenseName,
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
                  width: 150,
                  child: AppNumberField(
                    label: Strings.expenseAmount,
                    controller: e.amount,
                    prefixText: 'R\$ ',
                    dense: true,
                    enabled: enabled,
                    onChanged: onChanged,
                  ),
                ),
                IconButton(
                  tooltip: Strings.remove,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: enabled ? () => onRemove(e) : null,
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: enabled ? onAdd : null,
            icon: const Icon(Icons.add_rounded),
            label: const Text(Strings.addExpense),
          ),
        ),
      ],
    );
  }
}

class _FeeTile extends StatelessWidget {
  const _FeeTile({
    super.key,
    required this.row,
    required this.enabled,
    required this.onChanged,
    required this.onToggle,
    required this.onRemove,
  });

  final _FeeRow row;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Switch(value: row.active, onChanged: enabled ? onToggle : null),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: TextFormField(
                  controller: row.name,
                  enabled: enabled,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.sentences,
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
                width: 110,
                child: AppNumberField(
                  label: Strings.feeRate,
                  controller: row.rate,
                  suffixText: '%',
                  dense: true,
                  enabled: enabled,
                  onChanged: onChanged,
                ),
              ),
              IconButton(
                tooltip: Strings.remove,
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: enabled ? onRemove : null,
              ),
            ],
          ),
          if (row.hint != null && row.hint!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 60, right: 48),
              child: Text(
                row.hint!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
