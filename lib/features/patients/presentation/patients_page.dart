import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../../../shared/formatters/dates.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_pagination.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_snack.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/app_table.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../session/application/permissions.dart';
import '../../session/domain/screen_codes.dart';
import '../application/patients_controllers.dart';
import '../data/patient_repository.dart';
import '../domain/patient_models.dart';
import 'patient_form_dialog.dart';
import 'patient_widgets.dart';

/// Pacientes: busca + grid (nome, celular, nascimento, e-mail, como conheceu,
/// situacao) e cadastro rapido. Clicar na linha abre a ficha.
class PatientsPage extends ConsumerStatefulWidget {
  const PatientsPage({super.key});

  @override
  ConsumerState<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends ConsumerState<PatientsPage> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _setFilters(PatientFilters f) =>
      ref.read(patientFiltersProvider.notifier).state = f;

  void _applySearch(String value) => _setFilters(
    ref.read(patientFiltersProvider).copyWith(search: value, page: 1),
  );

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _applySearch(value),
    );
  }

  void _open(Patient p) => context.go(AppRoutes.patient(p.nrPatient));

  Future<void> _openNew() async {
    final nr = await PatientFormDialog.show(context);
    if (nr == null || !mounted) return;
    AppSnack.success(context, Strings.patientCreated);
    context.go(AppRoutes.patient(nr));
  }

  @override
  Widget build(BuildContext context) {
    final canRead = ref.watch(canReadProvider(ScreenCodes.patients));
    if (!canRead) {
      return const AppShell(
        section: AppSection.patients,
        child: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: Strings.noPermissionTitle,
          subtitle: Strings.noPermissionSubtitle,
        ),
      );
    }
    final canCreate = ref.watch(canCreateProvider(ScreenCodes.patients));
    final filters = ref.watch(patientFiltersProvider);
    final async = ref.watch(patientsProvider);
    final isMobile = context.isMobile;

    return AppShell(
      section: AppSection.patients,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: Strings.patients,
              subtitle: Strings.patientsSubtitle,
              actions: [
                if (canCreate)
                  AppButton(
                    label: Strings.newPatient,
                    icon: Icons.person_add_alt_1_rounded,
                    expanded: false,
                    onPressed: _openNew,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                SizedBox(
                  width: isMobile ? double.infinity : 420,
                  child: AppTextField(
                    label: Strings.search,
                    hint: Strings.searchPatientsHint,
                    helperText: Strings.searchPatientsHelp,
                    controller: _search,
                    prefixIcon: Icons.search_rounded,
                    onChanged: _onSearch,
                    onFieldSubmitted: _applySearch,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: FilterChip(
                    label: const Text(Strings.showInactive),
                    selected: filters.includeInactive,
                    onSelected: (v) => _setFilters(
                      filters.copyWith(includeInactive: v, page: 1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => AppEmptyState.error(
                  message: describeError(e),
                  onRetry: () => ref.invalidate(patientsProvider),
                ),
                data: (page) {
                  if (page == null || page.patients.isEmpty) {
                    final searching = filters.search.trim().isNotEmpty;
                    return AppEmptyState(
                      icon: searching
                          ? Icons.person_search_rounded
                          : Icons.contact_page_outlined,
                      title: searching
                          ? Strings.noPatientsFound
                          : Strings.noPatients,
                      subtitle: searching
                          ? Strings.noPatientsFoundSubtitle
                          : Strings.noPatientsSubtitle,
                      actionLabel: !searching && canCreate
                          ? Strings.newPatient
                          : null,
                      onAction: !searching && canCreate ? _openNew : null,
                    );
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ResponsiveBuilder(
                          mobile: (_) => _PatientCards(
                            items: page.patients,
                            onOpen: _open,
                          ),
                          desktop: (_) => _PatientTable(
                            items: page.patients,
                            onOpen: _open,
                          ),
                        ),
                      ),
                      AppPagination(
                        page: page.page,
                        pageCount: page.pageCount,
                        total: page.total,
                        onPage: (p) => _setFilters(filters.copyWith(page: p)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _birthText(Patient p) {
  if (p.dtBirth == null) return '-';
  final age = p.age;
  return age == null
      ? Dates.format(p.dtBirth)
      : '${Dates.format(p.dtBirth)} · ${Strings.yearsOld(age)}';
}

class _PatientTable extends StatelessWidget {
  const _PatientTable({required this.items, required this.onOpen});

  final List<Patient> items;
  final ValueChanged<Patient> onOpen;

  @override
  Widget build(BuildContext context) {
    return AppTable(
      minWidth: 980,
      columns: const [
        DataColumn(label: Text(Strings.name)),
        DataColumn(label: Text(Strings.mobileWhatsapp)),
        DataColumn(label: Text(Strings.birth)),
        DataColumn(label: Text(Strings.email)),
        DataColumn(label: Text(Strings.howFound)),
        DataColumn(label: Text(Strings.status)),
        DataColumn(label: Text(Strings.actions)),
      ],
      rows: [
        for (final p in items)
          DataRow(
            onSelectChanged: (_) => onOpen(p),
            cells: [
              DataCell(
                Row(
                  children: [
                    PatientAvatar(patient: p, size: 36),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.vcName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          p.vcNickname ??
                              (p.vcCpf == null
                                  ? Strings.cpfNotInformed
                                  : p.cpfFormatted),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              DataCell(Text(p.mobileFormatted)),
              DataCell(Text(_birthText(p))),
              DataCell(
                Text(p.idNoEmail ? Strings.noEmail : (p.vcEmail ?? '-')),
              ),
              DataCell(Text(p.sourceLabel)),
              DataCell(AppStatusChip(status: p.itStatus, compact: true)),
              DataCell(
                IconButton(
                  tooltip: Strings.openRecord,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: () => onOpen(p),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _PatientCards extends StatelessWidget {
  const _PatientCards({required this.items, required this.onOpen});

  final List<Patient> items;
  final ValueChanged<Patient> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final p = items[index];
        return Card(
          child: ListTile(
            onTap: () => onOpen(p),
            leading: PatientAvatar(patient: p, size: 44),
            title: Text(
              p.vcName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      if (p.vcMobile != null) p.mobileFormatted,
                      _birthText(p),
                    ].join(' · '),
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (p.itSource != null || !p.isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (p.itSource != null)
                            AppTagChip(
                              icon: Icons.campaign_outlined,
                              label: p.sourceLabel,
                            ),
                          if (!p.isActive)
                            AppStatusChip(status: p.itStatus, compact: true),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        );
      },
    );
  }
}
