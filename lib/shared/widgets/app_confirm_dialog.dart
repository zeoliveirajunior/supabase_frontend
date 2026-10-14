import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/strings.dart';

/// Confirmacao de acao destrutiva. Devolve true quando confirmada.
abstract final class AppConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    bool destructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(Strings.cancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel ?? Strings.confirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
