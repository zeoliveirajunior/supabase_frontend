import 'package:intl/intl.dart';

import 'masks.dart';

/// Datas em pt-BR (dd/MM/yyyy) <-> ISO (yyyy-MM-dd, o que o backend usa).
abstract final class Dates {
  static final DateFormat _br = DateFormat('dd/MM/yyyy');
  static final DateFormat _brTime = DateFormat('dd/MM/yyyy HH:mm');

  /// `20/05/1990`. Null vira `-`.
  static String format(DateTime? date) => date == null ? '-' : _br.format(date);

  /// `20/05/1990 14:30` (hora local).
  static String formatTime(DateTime? date) =>
      date == null ? '-' : _brTime.format(date.toLocal());

  /// `1990-05-20` (so a data, para o backend).
  static String toIso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// `yyyy-MM-dd` (ou ISO completo) -> data local. Invalido -> null.
  static DateTime? fromIso(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Texto digitado com mascara (`20/05/1990`) -> data. Invalido -> null.
  static DateTime? parseField(String? text) {
    if (text == null) return null;
    final d = Masks.unmask(text);
    if (d.length != 8) return null;
    final day = int.parse(d.substring(0, 2));
    final month = int.parse(d.substring(2, 4));
    final year = int.parse(d.substring(4, 8));
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  /// Data -> texto do campo (`20/05/1990`); null -> vazio.
  static String toField(DateTime? date) => date == null ? '' : _br.format(date);

  /// Idade completa em anos na data [at] (hoje por padrao).
  static int age(DateTime birth, {DateTime? at}) {
    final now = at ?? DateTime.now();
    var years = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      years--;
    }
    return years < 0 ? 0 : years;
  }
}
