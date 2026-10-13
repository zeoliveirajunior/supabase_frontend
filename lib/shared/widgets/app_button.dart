import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, text }

/// Botao padrao com estado de carregamento (desabilita e mostra progresso).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final onTap = loading ? null : onPressed;
    final progressColor = variant == AppButtonVariant.primary
        ? Colors.white
        : Theme.of(context).colorScheme.primary;

    final Widget child = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: progressColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        onPressed: onTap,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: onTap,
        child: child,
      ),
      AppButtonVariant.text => TextButton(onPressed: onTap, child: child),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
