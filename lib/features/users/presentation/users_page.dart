import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_pagination.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_snack.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/app_table.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/choice.dart';
import '../../../shared/widgets/searchable_dropdown.dart';
import '../../profiles/domain/access_profile.dart';
import '../../session/application/permissions.dart';
import '../../session/domain/screen_codes.dart';
import '../application/users_controller.dart';
import '../data/user_repository.dart';
import '../domain/company_user.dart';
import 'user_form_dialog.dart';

final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

/// Usuarios da empresa atual: cadastrar, editar acesso por filial, bloquear,
/// remover. A lista exige ler USERS (o backend exige administrador para
/// listar); cadastrar exige criar; editar/remover exigem alterar.
class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _setFilters(UserFilters f) =>
      ref.read(userFiltersProvider.notifier).state = f;

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _setFilters(
        ref.read(userFiltersProvider).copyWith(search: value, page: 1),
      );
    });
  }

  Future<void> _openForm([CompanyUser? user]) async {
    final saved = await UserFormDialog.show(context, user: user);
    if (saved && mounted) {
      AppSnack.success(
        context,
        user == null ? Strings.userCreated : Strings.savedSuccess,
      );
    }
  }

  Future<void> _unlink(CompanyUser user) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: Strings.unlinkUser,
      message: Strings.unlinkConfirm(user.vcName),
      confirmLabel: Strings.remove,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(usersProvider.notifier).unlink(nrUser: user.nrUser);
      if (mounted) AppSnack.success(context, Strings.removedSuccess);
    } catch (e) {
      if (mounted) AppSnack.error(context, describeError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canRead = ref.watch(canReadProvider(ScreenCodes.users));
    if (!canRead) {
      return const AppShell(
        section: AppSection.users,
        child: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: Strings.noPermissionTitle,
          subtitle: Strings.noPermissionSubtitle,
        ),
      );
    }
    final canCreate = ref.watch(canCreateProvider(ScreenCodes.users));
    final canUpdate = ref.watch(canUpdateProvider(ScreenCodes.users));

    final filters = ref.watch(userFiltersProvider);
    final async = ref.watch(usersProvider);
    final branches = ref.watch(branchesProvider).valueOrNull ?? const [];

    final statusChoices = const [
      Choice<int>(value: null, label: Strings.allStatuses),
      Choice<int>(value: UserStatus.active, label: Strings.statusActive),
      Choice<int>(value: UserStatus.blocked, label: Strings.statusBlocked),
      Choice<int>(value: UserStatus.inactive, label: Strings.statusInactive),
    ];
    final branchChoices = [
      const Choice<int>(value: null, label: Strings.allBranches),
      for (final b in branches)
        Choice<int>(
          value: b.nrBranch,
          label: b.vcName,
          subtitle: b.idMain ? Strings.mainBranch : null,
        ),
    ];
    final isMobile = context.isMobile;

    return AppShell(
      section: AppSection.users,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: Strings.usersTitle,
              subtitle: Strings.usersSubtitle,
              actions: [
                if (canCreate)
                  AppButton(
                    label: Strings.newUser,
                    icon: Icons.person_add_alt_1_rounded,
                    expanded: false,
                    onPressed: () => _openForm(),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SizedBox(
                  width: isMobile ? double.infinity : 320,
                  child: AppTextField(
                    label: Strings.search,
                    hint: Strings.searchUsersHint,
                    controller: _search,
                    prefixIcon: Icons.search_rounded,
                    onChanged: _onSearch,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                SizedBox(
                  width: isMobile ? double.infinity : 200,
                  child: SearchableDropdown<Choice<int>>(
                    label: Strings.status,
                    items: statusChoices,
                    value: statusChoices.firstWhere(
                      (c) => c.value == filters.itStatus,
                      orElse: () => statusChoices.first,
                    ),
                    itemLabel: (c) => c.label,
                    onChanged: (c) => _setFilters(
                      c.value == null
                          ? filters.copyWith(clearStatus: true, page: 1)
                          : filters.copyWith(itStatus: c.value, page: 1),
                    ),
                  ),
                ),
                if (branches.length > 1)
                  SizedBox(
                    width: isMobile ? double.infinity : 240,
                    child: SearchableDropdown<Choice<int>>(
                      label: Strings.branch,
                      items: branchChoices,
                      value: branchChoices.firstWhere(
                        (c) => c.value == filters.nrBranch,
                        orElse: () => branchChoices.first,
                      ),
                      itemLabel: (c) => c.label,
                      itemSubtitle: (c) => c.subtitle,
                      onChanged: (c) => _setFilters(
                        c.value == null
                            ? filters.copyWith(clearBranch: true, page: 1)
                            : filters.copyWith(nrBranch: c.value, page: 1),
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
                  onRetry: () => ref.invalidate(usersProvider),
                ),
                data: (page) {
                  if (page.users.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.people_outline_rounded,
                      title: Strings.noUsers,
                    );
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ResponsiveBuilder(
                          mobile: (_) => _UserCards(
                            users: page.users,
                            onEdit: canUpdate ? _openForm : null,
                            onUnlink: canUpdate ? _unlink : null,
                          ),
                          desktop: (_) => _UserTable(
                            users: page.users,
                            onEdit: canUpdate ? _openForm : null,
                            onUnlink: canUpdate ? _unlink : null,
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final CompanyUser user;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: user.idAdmin ? AppColors.mint : AppColors.surface,
      foregroundColor: user.idAdmin ? AppColors.primaryDark : AppColors.muted,
      child: Text(
        user.initials,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );
  }
}

Widget _accessChips(CompanyUser user) => Wrap(
  spacing: AppSpacing.xs,
  runSpacing: AppSpacing.xs,
  children: [
    for (final b in user.branches)
      AppTagChip(
        label: '${b.vcBranch} · ${b.vcProfile}',
        icon: b.isAdmin ? Icons.admin_panel_settings_rounded : null,
        highlighted: b.isAdmin,
      ),
  ],
);

Widget _actions(
  CompanyUser u,
  ValueChanged<CompanyUser>? onEdit,
  ValueChanged<CompanyUser>? onUnlink,
) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      tooltip: Strings.edit,
      icon: const Icon(Icons.edit_outlined),
      onPressed: onEdit == null ? null : () => onEdit(u),
    ),
    IconButton(
      tooltip: Strings.unlinkUser,
      icon: Icon(
        Icons.person_remove_outlined,
        color: onUnlink == null ? AppColors.muted : AppColors.danger,
      ),
      onPressed: onUnlink == null ? null : () => onUnlink(u),
    ),
  ],
);

class _UserTable extends StatelessWidget {
  const _UserTable({
    required this.users,
    required this.onEdit,
    required this.onUnlink,
  });

  final List<CompanyUser> users;
  final ValueChanged<CompanyUser>? onEdit;
  final ValueChanged<CompanyUser>? onUnlink;

  @override
  Widget build(BuildContext context) {
    return AppTable(
      minWidth: 960,
      columns: const [
        DataColumn(label: Text(Strings.user)),
        DataColumn(label: Text(Strings.status)),
        DataColumn(label: Text(Strings.userAccessTitle)),
        DataColumn(label: Text(Strings.lastLogin)),
        DataColumn(label: Text(Strings.actions)),
      ],
      rows: [
        for (final u in users)
          DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    _Avatar(user: u),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.vcName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (u.vcEmail != null)
                          Text(
                            u.vcEmail!,
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
              DataCell(
                Tooltip(
                  message: u.vcBlockReason ?? '',
                  child: AppStatusChip(status: u.itStatus),
                ),
              ),
              DataCell(_accessChips(u)),
              DataCell(
                Text(
                  u.dhLastLogin == null
                      ? Strings.never
                      : _dateTime.format(u.dhLastLogin!.toLocal()),
                ),
              ),
              DataCell(_actions(u, onEdit, onUnlink)),
            ],
          ),
      ],
    );
  }
}

class _UserCards extends StatelessWidget {
  const _UserCards({
    required this.users,
    required this.onEdit,
    required this.onUnlink,
  });

  final List<CompanyUser> users;
  final ValueChanged<CompanyUser>? onEdit;
  final ValueChanged<CompanyUser>? onUnlink;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final u = users[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Avatar(user: u),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.vcName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (u.vcEmail != null)
                            Text(
                              u.vcEmail!,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    AppStatusChip(status: u.itStatus, compact: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _accessChips(u),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${Strings.lastLogin}: ${u.dhLastLogin == null ? Strings.never : _dateTime.format(u.dhLastLogin!.toLocal())}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    _actions(u, onEdit, onUnlink),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
