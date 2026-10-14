import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/strings.dart';

/// Situacao (1 ativo · 80 bloqueado · 90 inativo) como chip colorido.
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.status, this.compact = false});

  final int status;
  final bool compact;

  static String label(int status) => switch (status) {
    1 => Strings.statusActive,
    80 => Strings.statusBlocked,
    90 => Strings.statusInactive,
    _ => '-',
  };

  static Color color(int status) => switch (status) {
    1 => AppColors.success,
    80 => AppColors.warning,
    90 => AppColors.muted,
    _ => AppColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    final c = color(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label(status),
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip neutro (nivel, perfil, filial).
class AppTagChip extends StatelessWidget {
  const AppTagChip({
    super.key,
    required this.label,
    this.icon,
    this.highlighted = false,
  });

  final String label;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.primaryDark : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.mint : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: highlighted ? AppColors.mint : AppColors.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
