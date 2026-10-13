import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_snack.dart';
import '../application/session_controller.dart';

/// Logado, mas sem filial acessivel: primeiro acesso (criar empresa) ou
/// vinculos bloqueados/inativos com o motivo de cada um.
class NoCompanyPage extends ConsumerWidget {
  const NoCompanyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(sessionControllerProvider).context;
    final blocked = session?.blocked ?? const [];
    final firstAccess = session?.isFirstAccess ?? true;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AppLogo(size: 32),
                      const SizedBox(height: AppSpacing.lg),
                      Icon(
                        firstAccess
                            ? Icons.add_business_rounded
                            : Icons.lock_person_outlined,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        firstAccess
                            ? Strings.noCompanyTitle
                            : Strings.blockedTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        firstAccess
                            ? Strings.noCompanySubtitle
                            : Strings.blockedSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      if (blocked.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        for (final b in blocked)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: ListTile(
                              tileColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              leading: const Icon(
                                Icons.block_rounded,
                                color: AppColors.warning,
                              ),
                              title: Text(
                                b.vcName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(b.message),
                            ),
                          ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      if (firstAccess)
                        AppButton(
                          label: Strings.createCompany,
                          icon: Icons.add_rounded,
                          onPressed: () =>
                              AppSnack.info(context, Strings.comingSoon),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: Strings.signOut,
                        variant: AppButtonVariant.secondary,
                        icon: Icons.logout_rounded,
                        onPressed: () => ref
                            .read(sessionControllerProvider.notifier)
                            .signOut(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
