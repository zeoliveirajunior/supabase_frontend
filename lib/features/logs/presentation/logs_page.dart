import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_shell.dart';
import '../../profiles/application/profiles_controller.dart';
import '../../session/application/permissions.dart';
import '../../session/domain/screen_codes.dart';
import 'access_log_tab.dart';
import 'event_log_tab.dart';

/// Logs: aba Atividades (o que aconteceu no sistema, por tela e por tipo) e
/// aba Acessos (logins). Administrador ve a empresa; usuario comum, o proprio.
class LogsPage extends ConsumerWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canRead = ref.watch(canReadProvider(ScreenCodes.logs));
    if (!canRead) {
      return const AppShell(
        section: AppSection.logs,
        child: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: Strings.noPermissionTitle,
          subtitle: Strings.noPermissionSubtitle,
        ),
      );
    }
    final isAdmin = ref.watch(isCompanyAdminProvider);

    return AppShell(
      section: AppSection.logs,
      child: DefaultTabController(
        length: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: Strings.logsTitle,
                subtitle: isAdmin ? Strings.logsSubtitle : Strings.logsOwnOnly,
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.line),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppColors.primaryDark,
                    unselectedLabelColor: AppColors.muted,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.history_rounded, size: 18),
                        text: Strings.activitiesTab,
                        iconMargin: EdgeInsets.only(bottom: 2),
                      ),
                      Tab(
                        icon: Icon(Icons.login_rounded, size: 18),
                        text: Strings.accessTab,
                        iconMargin: EdgeInsets.only(bottom: 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Expanded(
                child: TabBarView(children: [EventLogTab(), AccessLogTab()]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
