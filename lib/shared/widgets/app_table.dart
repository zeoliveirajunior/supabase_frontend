import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Tabela para o layout desktop: rola na vertical e, se a janela for estreita,
/// tambem na horizontal (largura minima [minWidth]).
class AppTable extends StatelessWidget {
  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    this.minWidth = 720,
    this.showCheckboxColumn = false,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double minWidth;

  /// Linhas com onSelectChanged ganham checkbox so quando pedido.
  final bool showCheckboxColumn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: math.max(constraints.maxWidth, minWidth),
              ),
              child: SingleChildScrollView(
                child: DataTable(
                  columns: columns,
                  rows: rows,
                  showCheckboxColumn: showCheckboxColumn,
                  headingRowColor: const WidgetStatePropertyAll(
                    AppColors.surface,
                  ),
                  headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                  ),
                  dividerThickness: 0.6,
                  columnSpacing: AppSpacing.lg,
                  horizontalMargin: AppSpacing.lg,
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 76,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
