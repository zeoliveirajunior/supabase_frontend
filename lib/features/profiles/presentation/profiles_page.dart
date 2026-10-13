import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../../shared/widgets/app_snack.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/app_table.dart';
import '../application/profiles_controller.dart';
import '../domain/access_profile.dart';
import 'profile_form_dialog.dart';

/// Cadastro de perfis de acesso da empresa atual.
/// Qualquer usuario ve a lista; so administrador cria/edita.
class ProfilesPage extends ConsumerStatefulWidget {
  const ProfilesPage({super.key});

  @override
  ConsumerState<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends ConsumerState<ProfilesPage> {
  bool _showInactive = false;

  Future<void> _openForm([AccessProfile? profile]) async {
    final saved = await ProfileFormDialog.show(context, profile: profile);
    if (saved && mounted) AppSnack.success(context, Strings.savedSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(profilesProvider);
    final isAdmin = ref.watch(isCompanyAdminProvider);

    return AppShell(
      section: AppSection.profiles,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: Strings.profilesTitle,
              subtitle: Strings.profilesSubtitle,
              actions: [
                FilterChip(
                  label: const Text(Strings.showInactive),
                  selected: _showInactive,
                  onSelected: (v) => setState(() => _showInactive = v),
                ),
                if (isAdmin)
                  AppButton(
                    label: Strings.newProfile,
                    icon: Icons.add_rounded,
                    expanded: false,
                    onPressed: () => _openForm(),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => AppEmptyState.error(
                  message: describeError(e),
                  onRetry: () => ref.invalidate(profilesProvider),
                ),
                data: (all) {
                  final items = all
                      .where((p) => _showInactive || p.isActive)
                      .toList();
                  if (items.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.badge_outlined,
                      title: Strings.noProfiles,
                    );
                  }
                  final onTap = isAdmin ? _openForm : null;
                  return ResponsiveBuilder(
                    mobile: (_) => _ProfileCards(items: items, onTap: onTap),
                    desktop: (_) => _ProfileTable(items: items, onTap: onTap),
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

class _ProfileTable extends StatelessWidget {
  const _ProfileTable({required this.items, this.onTap});

  final List<AccessProfile> items;
  final ValueChanged<AccessProfile>? onTap;

  @override
  Widget build(BuildContext context) {
    return AppTable(
      minWidth: 640,
      columns: const [
        DataColumn(label: Text(Strings.name)),
        DataColumn(label: Text(Strings.level), numeric: true),
        DataColumn(label: Text(Strings.users), numeric: true),
        DataColumn(label: Text(Strings.status)),
        DataColumn(label: Text(Strings.actions)),
      ],
      rows: [
        for (final p in items)
          DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    Icon(
                      p.isAdmin
                          ? Icons.admin_panel_settings_rounded
                          : Icons.badge_outlined,
                      size: 20,
                      color: p.isAdmin
                          ? AppColors.primaryDark
                          : AppColors.muted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      p.vcName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              DataCell(
                AppTagChip(label: '${p.itLevel}', highlighted: p.isAdmin),
              ),
              DataCell(Text('${p.qtUsers}')),
              DataCell(AppStatusChip(status: p.itStatus)),
              DataCell(
                IconButton(
                  tooltip: Strings.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onTap == null ? null : () => onTap!(p),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _ProfileCards extends StatelessWidget {
  const _ProfileCards({required this.items, this.onTap});

  final List<AccessProfile> items;
  final ValueChanged<AccessProfile>? onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final p = items[index];
        return Card(
          child: ListTile(
            onTap: onTap == null ? null : () => onTap!(p),
            leading: CircleAvatar(
              backgroundColor: p.isAdmin ? AppColors.mint : AppColors.surface,
              foregroundColor: p.isAdmin
                  ? AppColors.primaryDark
                  : AppColors.muted,
              child: Icon(
                p.isAdmin
                    ? Icons.admin_panel_settings_rounded
                    : Icons.badge_outlined,
              ),
            ),
            title: Text(
              p.vcName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  AppTagChip(
                    label: '${Strings.level} ${p.itLevel}',
                    highlighted: p.isAdmin,
                  ),
                  AppTagChip(
                    label: Strings.profileUsers(p.qtUsers),
                    icon: Icons.people_outline_rounded,
                  ),
                  AppStatusChip(status: p.itStatus, compact: true),
                ],
              ),
            ),
            trailing: onTap == null
                ? null
                : const Icon(Icons.chevron_right_rounded),
          ),
        );
      },
    );
  }
}
