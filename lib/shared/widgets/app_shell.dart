import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../features/session/application/session_controller.dart';
import '../../features/session/presentation/branch_selection_dialog.dart';
import '../../l10n/strings.dart';
import 'app_logo.dart';
import 'app_snack.dart';

enum AppSection { dashboard, users, profiles, logs }

/// Moldura das telas internas: menu lateral no desktop, barra inferior no
/// mobile, cabecalho com a filial atual (clicavel para trocar) e o usuario.
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.section,
    required this.child,
    this.title,
  });

  final AppSection section;
  final Widget child;
  final String? title;

  static const _destinations = [
    (
      AppSection.dashboard,
      Icons.space_dashboard_outlined,
      Icons.space_dashboard_rounded,
      Strings.dashboard,
      '/dashboard',
    ),
    (
      AppSection.users,
      Icons.people_outline_rounded,
      Icons.people_rounded,
      Strings.users,
      null,
    ),
    (
      AppSection.profiles,
      Icons.badge_outlined,
      Icons.badge_rounded,
      Strings.profiles,
      null,
    ),
    (
      AppSection.logs,
      Icons.receipt_long_outlined,
      Icons.receipt_long_rounded,
      Strings.logs,
      null,
    ),
  ];

  int get _selectedIndex => _destinations
      .indexWhere((d) => d.$1 == section)
      .clamp(0, _destinations.length - 1);

  void _onSelect(BuildContext context, int index) {
    final route = _destinations[index].$5;
    if (route == null) {
      AppSnack.info(context, Strings.comingSoon);
      return;
    }
    if (index != _selectedIndex) context.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageTitle = title ?? _destinations[_selectedIndex].$4;

    return ResponsiveBuilder(
      mobile: (_) => Scaffold(
        appBar: AppBar(
          title: Text(pageTitle),
          actions: const [
            _BranchChip(compact: true),
            SizedBox(width: AppSpacing.xs),
            _UserMenu(compact: true),
            SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => _onSelect(context, i),
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.$2),
                selectedIcon: Icon(d.$3),
                label: d.$4,
              ),
          ],
        ),
      ),
      desktop: (_) => Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: context.isWide,
              minExtendedWidth: 224,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => _onSelect(context, i),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: AppLogo(size: 32, showWordmark: context.isWide),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.$2),
                    selectedIcon: Icon(d.$3),
                    label: Text(d.$4),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  _TopBar(title: pageTitle),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          const _BranchChip(),
          const SizedBox(width: AppSpacing.md),
          const _UserMenu(),
        ],
      ),
    );
  }
}

/// Empresa · filial atual. Clique abre o pop-up para trocar.
class _BranchChip extends ConsumerWidget {
  const _BranchChip({this.compact = false});

  final bool compact;

  Future<void> _switch(BuildContext context, WidgetRef ref) async {
    final state = ref.read(sessionControllerProvider);
    final session = state.context;
    if (session == null) return;
    final result = await BranchSelectionDialog.show(
      context,
      session: session,
      current: state.selected,
      allowCancel: true,
    );
    if (result != null) {
      await ref.read(sessionControllerProvider.notifier).select(result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    final selected = state.selected;
    if (selected == null) return const SizedBox.shrink();
    final canSwitch = (state.context?.branches.length ?? 0) > 1;
    final label = compact ? selected.branch.vcName : selected.label;

    return Tooltip(
      message: canSwitch ? Strings.switchBranch : selected.label,
      child: ActionChip(
        avatar: const Icon(
          Icons.store_mall_directory_rounded,
          size: 18,
          color: AppColors.primaryDark,
        ),
        label: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 120 : 320),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        onPressed: canSwitch ? () => _switch(context, ref) : null,
      ),
    );
  }
}

class _UserMenu extends ConsumerWidget {
  const _UserMenu({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    final user = state.context?.user;
    if (user == null) return const SizedBox.shrink();
    final canSwitch = (state.context?.branches.length ?? 0) > 1;

    final avatar = CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.mint,
      foregroundColor: AppColors.primaryDark,
      child: Text(
        user.initials,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );

    return PopupMenuButton<String>(
      tooltip: user.vcName,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      onSelected: (value) async {
        final controller = ref.read(sessionControllerProvider.notifier);
        if (value == 'switch') {
          final session = state.context;
          if (session == null) return;
          final result = await BranchSelectionDialog.show(
            context,
            session: session,
            current: state.selected,
            allowCancel: true,
          );
          if (result != null) await controller.select(result);
        } else if (value == 'signout') {
          await controller.signOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.vcName,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (user.vcEmail != null)
                Text(
                  user.vcEmail!,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        if (canSwitch)
          const PopupMenuItem<String>(
            value: 'switch',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.swap_horiz_rounded),
              title: Text(Strings.switchBranch),
            ),
          ),
        const PopupMenuItem<String>(
          value: 'signout',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_rounded),
            title: Text(Strings.signOut),
          ),
        ),
      ],
      child: compact
          ? avatar
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                avatar,
                const SizedBox(width: AppSpacing.sm),
                Text(
                  user.vcName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Icon(Icons.expand_more_rounded, color: AppColors.muted),
              ],
            ),
    );
  }
}
