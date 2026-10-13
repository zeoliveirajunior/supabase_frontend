import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/strings.dart';
import '../../../../shared/widgets/app_logo.dart';

/// Painel da marca usado no login web: gradiente, ilustracao e promessa.
class BrandPanel extends StatelessWidget {
  const BrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final illustration = (constraints.maxHeight * 0.42).clamp(
            220.0,
            440.0,
          );
          return Stack(
            children: [
              Positioned(
                right: -120,
                top: -120,
                child: _Ring(size: 420, opacity: 0.08),
              ),
              Positioned(
                left: -160,
                bottom: -200,
                child: _Ring(size: 520, opacity: 0.06),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogo(size: 44, color: Colors.white),
                    const Spacer(),
                    Center(
                      child: SvgPicture.asset(
                        'assets/images/login_illustration.svg',
                        height: illustration,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Sua clínica, organizada.',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      Strings.tagline,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _Feature(
                          icon: Icons.event_available_rounded,
                          label: 'Agenda',
                        ),
                        _Feature(
                          icon: Icons.folder_shared_rounded,
                          label: 'Prontuário',
                        ),
                        _Feature(
                          icon: Icons.request_quote_rounded,
                          label: 'Orçamentos',
                        ),
                        _Feature(
                          icon: Icons.payments_rounded,
                          label: 'Financeiro',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
