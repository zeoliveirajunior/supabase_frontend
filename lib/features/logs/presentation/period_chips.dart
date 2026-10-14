import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/strings.dart';

final _date = DateFormat('dd/MM/yyyy');

/// Chips "Ultimos 7/30/90 dias" + periodo personalizado (calendario).
class PeriodChips extends StatelessWidget {
  const PeriodChips({
    super.key,
    required this.from,
    required this.to,
    required this.onDays,
    required this.onRange,
  });

  static const presets = [7, 30, 90];

  final DateTime from;
  final DateTime to;
  final ValueChanged<int> onDays;
  final void Function(DateTime from, DateTime to) onRange;

  int? get _preset {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (to.year != today.year ||
        to.month != today.month ||
        to.day != today.day) {
      return null;
    }
    for (final days in presets) {
      final start = today.subtract(Duration(days: days - 1));
      if (from.year == start.year &&
          from.month == start.month &&
          from.day == start.day) {
        return days;
      }
    }
    return null;
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(start: from, end: to),
      locale: const Locale('pt', 'BR'),
    );
    if (range == null) return;
    onRange(
      DateTime(range.start.year, range.start.month, range.start.day),
      DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preset = _preset;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final days in presets)
          ChoiceChip(
            label: Text(Strings.lastDays(days)),
            selected: preset == days,
            onSelected: (_) => onDays(days),
          ),
        ChoiceChip(
          label: Text(
            preset == null
                ? '${_date.format(from)} – ${_date.format(to)}'
                : Strings.customPeriod,
          ),
          avatar: const Icon(Icons.date_range_rounded, size: 18),
          selected: preset == null,
          onSelected: (_) => _pick(context),
        ),
      ],
    );
  }
}
