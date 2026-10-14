import 'dart:async';
import 'dart:convert';

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
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/choice.dart';
import '../../../shared/widgets/searchable_dropdown.dart';
import '../../profiles/application/profiles_controller.dart';
import '../../users/application/users_controller.dart';
import '../application/events_controller.dart';
import '../data/event_repository.dart';
import '../domain/event_log_entry.dart';
import 'period_chips.dart';

final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

/// Aba Atividades: o que aconteceu no sistema (ad.event_log), pesquisavel
/// por tela, tipo de acao, usuario, texto e periodo.
class EventLogTab extends ConsumerStatefulWidget {
  const EventLogTab({super.key});

  @override
  ConsumerState<EventLogTab> createState() => _EventLogTabState();
}

class _EventLogTabState extends ConsumerState<EventLogTab> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _setFilters(EventFilters f) =>
      ref.read(eventFiltersProvider.notifier).state = f;

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _setFilters(
        ref.read(eventFiltersProvider).copyWith(search: value, page: 1),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(eventFiltersProvider);
    final async = ref.watch(eventsProvider);
    final isAdmin = ref.watch(isCompanyAdminProvider);
    final screens = ref.watch(screensProvider).valueOrNull ?? const [];
    final userOptions = ref.watch(userOptionsProvider).valueOrNull ?? const [];
    final isMobile = context.isMobile;

    final screenChoices = [
      const Choice<String>(value: null, label: Strings.allScreensFilter),
      for (final s in screens)
        Choice<String>(value: s.uuScreen, label: s.vcName, subtitle: s.vcGroup),
    ];
    final actionChoices = [
      const Choice<String>(value: null, label: Strings.allActions),
      for (final a in EventAction.all)
        Choice<String>(value: a, label: EventAction.label(a)),
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
              onDays: (d) => _setFilters(EventFilters.lastDays(d)),
              onRange: (from, to) =>
                  _setFilters(filters.copyWith(from: from, to: to, page: 1)),
            ),
            SizedBox(
              width: isMobile ? double.infinity : 260,
              child: AppTextField(
                label: Strings.search,
                hint: Strings.searchEventsHint,
                controller: _search,
                prefixIcon: Icons.search_rounded,
                onChanged: _onSearch,
                textInputAction: TextInputAction.search,
              ),
            ),
            SizedBox(
              width: isMobile ? double.infinity : 220,
              child: SearchableDropdown<Choice<String>>(
                label: Strings.screen,
                items: screenChoices,
                value: screenChoices.firstWhere(
                  (c) => c.value == filters.uuScreen,
                  orElse: () => screenChoices.first,
                ),
                itemLabel: (c) => c.label,
                itemSubtitle: (c) => c.subtitle,
                onChanged: (c) => _setFilters(
                  c.value == null
                      ? filters.copyWith(clearScreen: true, page: 1)
                      : filters.copyWith(uuScreen: c.value, page: 1),
                ),
              ),
            ),
            SizedBox(
              width: isMobile ? double.infinity : 200,
              child: SearchableDropdown<Choice<String>>(
                label: Strings.action,
                items: actionChoices,
                value: actionChoices.firstWhere(
                  (c) => c.value == filters.vcAction,
                  orElse: () => actionChoices.first,
                ),
                itemLabel: (c) => c.label,
                onChanged: (c) => _setFilters(
                  c.value == null
                      ? filters.copyWith(clearAction: true, page: 1)
                      : filters.copyWith(vcAction: c.value, page: 1),
                ),
              ),
            ),
            if (isAdmin)
              SizedBox(
                width: isMobile ? double.infinity : 260,
                child: SearchableDropdown<Choice<int>>(
                  label: Strings.user,
                  items: userChoices,
                  value: userChoices.firstWhere(
                    (c) => c.value == filters.nrUser,
                    orElse: () => userChoices.first,
                  ),
                  itemLabel: (c) => c.label,
                  itemSubtitle: (c) => c.subtitle,
                  onChanged: (c) => _setFilters(
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
              onRetry: () => ref.invalidate(eventsProvider),
            ),
            data: (page) {
              if (page.events.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.history_rounded,
                  title: Strings.noEvents,
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: ResponsiveBuilder(
                      mobile: (_) => _EventCards(events: page.events),
                      desktop: (_) => _EventTable(events: page.events),
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
    );
  }
}

Color _actionColor(String action) => switch (action) {
  EventAction.create => AppColors.success,
  EventAction.update => AppColors.primaryDark,
  EventAction.delete => AppColors.danger,
  _ => AppColors.muted,
};

IconData _actionIcon(String action) => switch (action) {
  EventAction.create => Icons.add_circle_outline_rounded,
  EventAction.update => Icons.edit_outlined,
  EventAction.delete => Icons.delete_outline_rounded,
  _ => Icons.info_outline_rounded,
};

Widget _actionChip(String action) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: _actionColor(action).withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(AppRadius.xl),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(_actionIcon(action), size: 14, color: _actionColor(action)),
      const SizedBox(width: 4),
      Text(
        EventAction.label(action),
        style: TextStyle(
          color: _actionColor(action),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    ],
  ),
);

Future<void> _showDetail(BuildContext context, EventLogEntry e) {
  final pretty = e.jsDetail == null
      ? '-'
      : const JsonEncoder.withIndent('  ').convert(e.jsDetail);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(e.vcSummary),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _actionChip(e.vcAction),
                  if (e.vcScreen != null)
                    AppTagChip(
                      label: e.vcScreen!,
                      icon: Icons.grid_view_rounded,
                    ),
                  AppTagChip(
                    label: [
                      e.vcEntity,
                      if (e.vcKey != null) e.vcKey!,
                    ].join(' '),
                    icon: Icons.tag_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${e.vcUser} · ${_dateTime.format(e.dhEvent)}'
                '${e.vcBranch != null ? ' · ${e.vcBranch}' : ''}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: SelectableText(
                  pretty,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Strings.close),
        ),
      ],
    ),
  );
}

class _EventTable extends StatelessWidget {
  const _EventTable({required this.events});

  final List<EventLogEntry> events;

  @override
  Widget build(BuildContext context) {
    return AppTable(
      minWidth: 960,
      columns: const [
        DataColumn(label: Text(Strings.dateTime)),
        DataColumn(label: Text(Strings.user)),
        DataColumn(label: Text(Strings.screen)),
        DataColumn(label: Text(Strings.action)),
        DataColumn(label: Text(Strings.summary)),
        DataColumn(label: Text(Strings.details)),
      ],
      rows: [
        for (final e in events)
          DataRow(
            cells: [
              DataCell(
                Text(
                  _dateTime.format(e.dhEvent),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataCell(Text(e.vcUser)),
              DataCell(Text(e.vcScreen ?? '-')),
              DataCell(_actionChip(e.vcAction)),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Text(
                    e.vcSummary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                IconButton(
                  tooltip: Strings.details,
                  icon: const Icon(Icons.open_in_new_rounded),
                  onPressed: () => _showDetail(context, e),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _EventCards extends StatelessWidget {
  const _EventCards({required this.events});

  final List<EventLogEntry> events;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final e = events[index];
        return Card(
          child: ListTile(
            onTap: () => _showDetail(context, e),
            leading: CircleAvatar(
              backgroundColor: _actionColor(e.vcAction).withValues(alpha: 0.12),
              foregroundColor: _actionColor(e.vcAction),
              child: Icon(_actionIcon(e.vcAction)),
            ),
            title: Text(
              e.vcSummary,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              [
                _dateTime.format(e.dhEvent),
                e.vcUser,
                if (e.vcScreen != null) e.vcScreen!,
              ].join(' · '),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        );
      },
    );
  }
}
