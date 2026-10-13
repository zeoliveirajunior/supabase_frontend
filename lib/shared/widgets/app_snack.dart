import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Mensagens rapidas no rodape (erro, sucesso, aviso).
abstract final class AppSnack {
  static void error(BuildContext context, String message) =>
      _show(context, message, AppColors.danger, Icons.error_outline_rounded);

  static void success(BuildContext context, String message) => _show(
    context,
    message,
    AppColors.success,
    Icons.check_circle_outline_rounded,
  );

  static void info(BuildContext context, String message) =>
      _show(context, message, AppColors.ink, Icons.info_outline_rounded);

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
