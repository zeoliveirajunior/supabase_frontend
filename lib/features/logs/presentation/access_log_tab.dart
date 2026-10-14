import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_pagination.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/app_table.dart';
import '../../../shared/widgets/choice.dart';
import '../../../shared/widgets/searchable_dropdown.dart';
import '../../profiles/application/profiles_controller.dart';
import '../../users/application/users_controller.dart';
import '../application/logs_controller.dart';
import '../data/log_repository.dart';
import '../domain/access_log_entry.dart';
import 'period_chips.dart';

final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

/// Aba Acessos: logins (ad.access_log) por periodo, app e usuario.
class AccessLogTab extends ConsumerWidget {
  const AccessLogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(logFiltersProvider);
    final async = ref.watch(logsProvider);
    final isAdmin = ref.watch(isCompanyAdminProvider);
    final userOptions = ref.watch(userOptionsProvider).valueOrNull ?? const [];

    void setFilters(LogFilters f) =>
        ref.read(logFiltersProvider.notifier).state = f;

    final appChoices = [
      const Choice<int>(value: null, label: Strings.allApps),
      Choice<int>(value: AppKind.web, label: AppKind.label(AppKind.web)),
      Choice<int>(
        value: AppKind.android,
        label: AppKind.label(AppKind.android),
      ),
      Choice<int>(value: AppKind.ios, label: AppKind.label(AppKind.ios)),
    ];
    final userChoices = [
      const Choice<int>(value: null, label: Strings.allUsers),
      for (final u in userOptions)
        Choice<int>(value: u.nrUser, label: u.vcName, subtitle: u.vcEmail),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PeriodChips(
              from: filters.from,
              to: filters.to,
              onDays: (d) => setFilters(LogFilters.lastDays(d)),
              onRange: (from, to) =>
                  setFilters(filters.copyWith(from: from, to: to, page: 1)),
            ),
            SizedBox(
              width: context.isMobile ? double.infinity : 200,
              child: SearchableDropdown<Choice<int>>(
                label: Strings.app,
                items: appChoices,
                value: appChoices.firstWhere(
                  (c) => c.value == filters.itApp,
                  orElse: () => appChoices.first,
                ),
                itemLabel: (c) => c.label,
                onChanged: (c) => setFilters(
                  c.value == null
                      ? filters.copyWith(clearApp: true, page: 1)
                      : filters.copyWith(itApp: c.value, page: 1),
                ),
              ),
            ),
            if (isAdmin)
              SizedBox(
                width: context.isMobile ? double.infinity : 280,
                child: SearchableDropdown<Choice<int>>(
                  label: Strings.user,
                  items: userChoices,
                  value: userChoices.firstWhere(
                    (c) => c.value == filters.nrUser,
                    orElse: () => userChoices.first,
                  ),
                  itemLabel: (c) => c.label,
                  itemSubtitle: (c) => c.subtitle,
                  onChanged: (c) => setFilters(
                    c.value == null
                        ? filters.copyWith(clearUser: true, page: 1)
                        : filters.copyWith(nrUser: c.value, page: 1),
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
              onRetry: () => ref.invalidate(logsProvider),
            ),
            data: (page) {
              if (page.logs.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.login_rounded,
                  title: Strings.noLogs,
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: ResponsiveBuilder(
                      mobile: (_) => _LogCards(logs: page.logs),
                      desktop: (_) => _LogTable(logs: page.logs),
                    ),
                  ),
                  AppPagination(
                    page: page.page,
                    pageCount: page.pageCount,
                    total: page.total,
                    onPage: (p) => setFilters(filters.copyWith(page: p)),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

IconData _appIcon(int? itApp) => switch (itApp) {
  AppKind.web => Icons.language_rounded,
  AppKind.android => Icons.android_rounded,
  AppKind.ios => Icons.phone_iphone_rounded,
  _ => Icons.devices_other_rounded,
};

class _LogTable extends StatelessWidget {
  const _LogTable({required this.logs});

  final List<AccessLogEntry> logs;

  @override
  Widget build(BuildContext context) {
    return AppTable(
      minWidth: 900,
      columns: const [
        DataColumn(label: Text(Strings.dateTime)),
        DataColumn(label: Text(Strings.user)),
        DataColumn(label: Text(Strings.app)),
        DataColumn(label: Text(Strings.branch)),
        DataColumn(label: Text(Strings.device)),
        DataColumn(label: Text(Strings.ip)),
      ],
      rows: [
        for (final l in logs)
          DataRow(
            cells: [
              DataCell(
                Text(
                  _dateTime.format(l.dhAccess),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.vcUser,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (l.vcEmail != null)
                      Text(
                        l.vcEmail!,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              DataCell(
                AppTagChip(
                  label: AppKind.label(l.itApp),
                  icon: _appIcon(l.itApp),
                ),
              ),
              DataCell(Text(l.vcBranch ?? Strings.noBranch)),
              DataCell(
                Text(
                  [
                    if (l.vcDevice != null && l.vcDevice!.isNotEmpty)
                      l.vcDevice,
                    if (l.vcAppVersion != null && l.vcAppVersion!.isNotEmpty)
                      'v${l.vcAppVersion}',
                  ].join(' · '),
                ),
              ),
              DataCell(Text(l.vcIp ?? '-')),
            ],
          ),
      ],
    );
  }
}

class _LogCards extends StatelessWidget {
  const _LogCards({required this.logs});

  final List<AccessLogEntry> logs;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final l = logs[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.mint,
              foregroundColor: AppColors.primaryDark,
              child: Icon(_appIcon(l.itApp)),
            ),
            title: Text(
              l.vcUser,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              [
                _dateTime.format(l.dhAccess),
                l.vcBranch ?? Strings.noBranch,
                AppKind.label(l.itApp),
                if (l.vcAppVersion != null && l.vcAppVersion!.isNotEmpty)
                  'v${l.vcAppVersion}',
              ].join(' · '),
            ),
          ),
        );
      },
    );
  }
}
