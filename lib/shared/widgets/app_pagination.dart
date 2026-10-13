import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/strings.dart';

/// Barra "x de y · pagina n de m" com anterior/proxima.
class AppPagination extends StatelessWidget {
  const AppPagination({
    super.key,
    required this.page,
    required this.pageCount,
    required this.total,
    required this.onPage,
  });

  final int page;
  final int pageCount;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.muted);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(child: Text(Strings.totalRecords(total), style: style)),
          Text(Strings.pageOf(page, pageCount), style: style),
          IconButton(
            tooltip: Strings.previousPage,
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: page > 1 ? () => onPage(page - 1) : null,
          ),
          IconButton(
            tooltip: Strings.nextPage,
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: page < pageCount ? () => onPage(page + 1) : null,
          ),
        ],
      ),
    );
  }
}
