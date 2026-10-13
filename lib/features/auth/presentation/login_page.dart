import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_snack.dart';
import '../../session/application/session_controller.dart';
import '../application/auth_controller.dart';
import 'widgets/brand_panel.dart';
import 'widgets/login_form.dart';

/// Tela de login. Tres layouts:
///   * desktop (>= 1024): painel da marca a esquerda, formulario a direita;
///   * tablet: cartao centralizado sobre o gradiente;
///   * mobile: cabecalho compacto da marca e formulario em tela cheia.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(loginControllerProvider).isLoading;

    ref.listen(loginControllerProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        final error = next.error;
        AppSnack.error(
          context,
          error is AppError
              ? error.message
              : AppError.unexpected(error!).message,
        );
      }
    });

    ref.listen(sessionControllerProvider, (previous, next) {
      final error = next.error;
      if (next.status == SessionStatus.signedOut &&
          error != null &&
          !identical(previous?.error, error)) {
        AppSnack.error(context, error.message);
      }
    });

    Future<void> submit(String email, String password) => ref
        .read(loginControllerProvider.notifier)
        .signIn(email: email, password: password);

    return Scaffold(
      body: ResponsiveBuilder(
        mobile: (_) => _MobileLayout(loading: loading, onSubmit: submit),
        tablet: (_) => _TabletLayout(loading: loading, onSubmit: submit),
        desktop: (_) => _DesktopLayout(loading: loading, onSubmit: submit),
      ),
    );
  }
}

typedef _Submit = Future<void> Function(String email, String password);

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({required this.loading, required this.onSubmit});

  final bool loading;
  final _Submit onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(flex: 11, child: BrandPanel()),
        Expanded(
          flex: 9,
          child: ColoredBox(
            color: AppColors.white,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _FormHeader(
                    loading: loading,
                    onSubmit: onSubmit,
                    showLogo: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabletLayout extends StatelessWidget {
  const _TabletLayout({required this.loading, required this.onSubmit});

  final bool loading;
  final _Submit onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: _FormHeader(loading: loading, onSubmit: onSubmit),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.loading, required this.onSubmit});

  final bool loading;
  final _Submit onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 232 + topPadding,
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.xl + 4),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  bottom: -8,
                  child: Opacity(
                    opacity: 0.9,
                    child: SvgPicture.asset(
                      'assets/images/login_illustration.svg',
                      height: 190,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    topPadding + AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppLogo(size: 32, color: Colors.white),
                      const Spacer(),
                      Text(
                        Strings.loginTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        Strings.loginSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: LoginForm(loading: loading, onSubmit: onSubmit),
          ),
        ],
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({
    required this.loading,
    required this.onSubmit,
    this.showLogo = true,
  });

  final bool loading;
  final _Submit onSubmit;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo) ...[
          const AppLogo(size: 36),
          const SizedBox(height: AppSpacing.xl),
        ],
        Text(
          Strings.loginTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          Strings.loginSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.xl),
        LoginForm(loading: loading, onSubmit: onSubmit),
      ],
    );
  }
}
