import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../../../shared/formatters/numbers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_snack.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/app_table.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/choice.dart';
import '../../../shared/widgets/searchable_dropdown.dart';
import '../../session/application/permissions.dart';
import '../../session/domain/screen_codes.dart';
import '../application/pricing_controllers.dart';
import '../domain/pricing_models.dart';
import 'pricing_breakdown.dart';
import 'procedure_form_dialog.dart';

/// Aba Procedimentos: lista com o preco calculado no banco, filtros por
/// texto/categoria, simulacao do regime (PF x PJ) e cadastro.
class ProceduresTab extends ConsumerStatefulWidget {
  const ProceduresTab({super.key});

  @override
  ConsumerState<ProceduresTab> createState() => _ProceduresTabState();
}

class _ProceduresTabState extends ConsumerState<ProceduresTab>
    with AutomaticKeepAliveClientMixin {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _setFilters(ProcedureFilters f) =>
      ref.read(procedureFiltersProvider.notifier).state = f;

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _setFilters(ref.read(procedureFiltersProvider).copyWith(search: value));
    });
  }

  Future<void> _openForm(ProcedureListData data, [Procedure? p]) async {
    final canUpdate = ref.read(canUpdateProvider(ScreenCodes.pricing));
    final saved = await ProcedureFormDialog.show(
      context,
      procedure: p,
      params: data.params,
      summary: data.summary,
      readOnly: p != null && !canUpdate,
    );
    if (saved && mounted) AppSnack.success(context, Strings.savedSuccess);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filters = ref.watch(procedureFiltersProvider);
    final async = ref.watch(proceduresProvider);
    final canCreate = ref.watch(canCreateProvider(ScreenCodes.pricing));
    final data = async.valueOrNull;
    final isMobile = context.isMobile;

    final categoryChoices = [
      const Choice<String>(value: null, label: Strings.allCategories),
      for (final c in data?.categories ?? const <String>[])
        Choice<String>(value: c, label: c),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: isMobile ? double.infinity : 260,
              child: AppTextField(
                label: Strings.search,
                hint: Strings.searchProceduresHint,
                controller: _search,
                prefixIcon: Icons.search_rounded,
                onChanged: _onSearch,
                textInputAction: TextInputAction.search,
              ),
            ),
            SizedBox(
              width: isMobile ? double.infinity : 220,
              child: SearchableDropdown<Choice<String>>(
                label: Strings.category,
                items: categoryChoices,
                value: categoryChoices.firstWhere(
                  (c) => c.value == filters.category,
                  orElse: () => categoryChoices.first,
                ),
                itemLabel: (c) => c.label,
                onChanged: (c) => _setFilters(
                  c.value == null
                      ? filters.copyWith(clearCategory: true)
                      : filters.copyWith(category: c.value),
                ),
              ),
            ),
            _RegimeChips(
              value: filters.itTaxRegime,
              onChanged: (v) => _setFilters(
                v == null
                    ? filters.copyWith(clearRegime: true)
                    : filters.copyWith(itTaxRegime: v),
              ),
            ),
            FilterChip(
              label: const Text(Strings.showInactive),
              selected: filters.includeInactive,
              onSelected: (v) =>
                  _setFilters(filters.copyWith(includeInactive: v)),
            ),
            if (canCreate && data != null)
              AppButton(
                label: Strings.newProcedure,
                icon: Icons.add_rounded,
                expanded: false,
                onPressed: () => _openForm(data),
              ),
          ],
        ),
        if (data != null) ...[
          const SizedBox(height: AppSpacing.md),
          _SummaryStrip(params: data.params, summary: data.summary),
        ],
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AppEmptyState.error(
              message: describeError(e),
              onRetry: () => ref.invalidate(proceduresProvider),
            ),
            data: (d) {
              if (d == null || d.procedures.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.medical_services_outlined,
                  title: Strings.noProcedures,
                );
              }
              return ResponsiveBuilder(
                mobile: (_) => _ProcedureCards(
                  items: d.procedures,
                  onTap: (p) => _openForm(d, p),
                ),
                desktop: (_) => _ProcedureTable(
                  items: d.procedures,
                  onTap: (p) => _openForm(d, p),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Regime da filial · PF · PJ (simulacao sem alterar os parametros).
class _RegimeChips extends StatelessWidget {
  const _RegimeChips({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(int? v, String label) => ChoiceChip(
      label: Text(label),
      selected: value == v,
      onSelected: (_) => onChanged(v),
    );
    return Wrap(
      spacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          '${Strings.simulateRegime}:',
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
        ),
        chip(null, Strings.regimeFromParams),
        chip(TaxRegime.pf, Strings.taxRegimePfShort),
        chip(TaxRegime.pj, Strings.taxRegimePjShort),
      ],
    );
  }
}

/// Resumo dos parametros em vigor na lista.
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.params, required this.summary});

  final PricingParams params;
  final PricingSummary summary;

  @override
  Widget build(BuildContext context) {
    final regime = summary.itTaxRegime ?? params.itTaxRegime;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        AppTagChip(
          icon: Icons.apartment_rounded,
          label:
              '${Strings.structureHour}: ${Numbers.money(summary.vlStructureHour)}${Strings.perHour}',
        ),
        AppTagChip(
          icon: Icons.person_outline_rounded,
          label:
              '${Strings.professionalCost}: ${Numbers.money(params.vlProfessionalHour)}${Strings.perHour}',
        ),
        AppTagChip(
          icon: Icons.account_balance_outlined,
          label:
              '${TaxRegime.label(regime)} · ${Numbers.percent(summary.pcTax, decimals: 2)}',
          highlighted: true,
        ),
        AppTagChip(
          icon: Icons.credit_card_rounded,
          label:
              '${Strings.cardFee} ${Numbers.percent(params.pcCard, decimals: 2)}',
        ),
        AppTagChip(
          icon: Icons.handshake_outlined,
          label:
              '${Strings.commission} ${Numbers.percent(params.pcCommission, decimals: 2)}',
        ),
        AppTagChip(
          icon: Icons.percent_rounded,
          label:
              '${Strings.extraFees} ${Numbers.percent(summary.pcFees, decimals: 2)}',
        ),
        AppTagChip(
          icon: Icons.trending_up_rounded,
          label:
              '${Strings.profit} ${Numbers.percent(params.pcProfit, decimals: 2)}',
        ),
      ],
    );
  }
}

Color _diffColor(double? diff) => diff == null
    ? AppColors.muted
    : (diff >= 0 ? AppColors.success : AppColors.danger);

String _diffText(double? diff) =>
    diff == null ? '-' : '${diff >= 0 ? '+' : ''}${Numbers.money(diff)}';

class _ProcedureTable extends StatelessWidget {
  const _ProcedureTable({required this.items, required this.onTap});

  final List<Procedure> items;
  final ValueChanged<Procedure> onTap;

  @override
  Widget build(BuildContext context) {
    return AppTable(
      minWidth: 1000,
      columns: const [
        DataColumn(label: Text(Strings.procedureName)),
        DataColumn(label: Text(Strings.time)),
        DataColumn(label: Text(Strings.directCost), numeric: true),
        DataColumn(label: Text(Strings.minPrice), numeric: true),
        DataColumn(label: Text(Strings.suggestedPrice), numeric: true),
        DataColumn(label: Text(Strings.current), numeric: true),
        DataColumn(label: Text(Strings.difference), numeric: true),
        DataColumn(label: Text(Strings.status)),
        DataColumn(label: Text(Strings.actions)),
      ],
      rows: [
        for (final p in items)
          DataRow(
            cells: [
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (p.vcCategory != null || p.alerts.isNotEmpty)
                      Row(
                        children: [
                          if (p.vcCategory != null)
                            Text(
                              p.vcCategory!,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          if (p.vcCategory != null && p.alerts.isNotEmpty)
                            const SizedBox(width: AppSpacing.sm),
                          ProcedureAlertChips(alerts: p.alerts),
                        ],
                      ),
                  ],
                ),
              ),
              DataCell(Text(Numbers.minutes(p.qtMinutes))),
              DataCell(Text(Numbers.money(p.pricing?.vlDirectCost))),
              DataCell(Text(Numbers.money(p.pricing?.vlPriceMin))),
              DataCell(
                Text(
                  Numbers.money(p.pricing?.vlPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              DataCell(Text(Numbers.money(p.vlCurrentPrice))),
              DataCell(
                Text(
                  _diffText(p.priceDiff),
                  style: TextStyle(
                    color: _diffColor(p.priceDiff),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              DataCell(AppStatusChip(status: p.itStatus, compact: true)),
              DataCell(
                IconButton(
                  tooltip: Strings.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => onTap(p),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ProcedureCards extends StatelessWidget {
  const _ProcedureCards({required this.items, required this.onTap});

  final List<Procedure> items;
  final ValueChanged<Procedure> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final p = items[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () => onTap(p),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        Numbers.money(p.pricing?.vlPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    [
                      if (p.vcCategory != null) p.vcCategory!,
                      Numbers.minutes(p.qtMinutes),
                      '${Strings.directCost} ${Numbers.money(p.pricing?.vlDirectCost)}',
                      '${Strings.minPrice} ${Numbers.money(p.pricing?.vlPriceMin)}',
                    ].join(' · '),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  if (p.vlCurrentPrice != null)
                    Text(
                      '${Strings.current} ${Numbers.money(p.vlCurrentPrice)} · ${_diffText(p.priceDiff)}',
                      style: TextStyle(
                        color: _diffColor(p.priceDiff),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (p.alerts.isNotEmpty || !p.isActive) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        if (!p.isActive)
                          AppStatusChip(status: p.itStatus, compact: true),
                        ProcedureAlertChips(alerts: p.alerts),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
