import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatacao e leitura de numeros em pt-BR (R$ 1.234,56 · 12,5% · 2,500).
abstract final class Numbers {
  static final NumberFormat _money = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  static final NumberFormat _money4 = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 4,
  );
  static final NumberFormat _decimal = NumberFormat.decimalPattern('pt_BR');

  /// `R$ 1.234,56`. Null vira `-`.
  static String money(num? value, {bool unit = false}) {
    if (value == null) return '-';
    // intl usa espaco nao separavel (U+00A0) entre o simbolo e o numero
    return (unit ? _money4 : _money).format(value).replaceAll(' ', ' ');
  }

  /// `12,5%` (entrada em pontos percentuais: 12.5).
  static String percent(num? value, {int decimals = 1}) {
    if (value == null) return '-';
    final text = value.toStringAsFixed(decimals).replaceAll('.', ',');
    return '${_trimZeros(text)}%';
  }

  /// `2,5` / `1.250` (ate [decimals] casas, sem zeros a direita).
  static String qty(num? value, {int decimals = 3}) {
    if (value == null) return '-';
    final text = value.toStringAsFixed(decimals).replaceAll('.', ',');
    return _trimZeros(text);
  }

  /// `1.234` (inteiro com separador de milhar).
  static String integer(num value) => _decimal.format(value.round());

  /// Minutos como `1h 30min` / `45min`.
  static String minutes(num value) {
    final total = value.round();
    final h = total ~/ 60;
    final m = total % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  /// Texto digitado -> numero. Aceita `1.234,56`, `1234.56`, `12,5`, `R$ 10`.
  /// Vazio ou invalido -> null.
  static double? parse(String? text) {
    if (text == null) return null;
    var t = text.replaceAll(RegExp(r'[^\d,.\-]'), '');
    if (t.isEmpty || t == '-' || t == ',' || t == '.') return null;
    if (t.contains(',')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if (RegExp(r'^\-?\d{1,3}(\.\d{3})+$').hasMatch(t)) {
      t = t.replaceAll('.', '');
    }
    return double.tryParse(t);
  }

  /// Numero -> texto para preencher um campo (`1234,5`; inteiro sem virgula).
  static String toField(num? value, {int decimals = 2}) {
    if (value == null) return '';
    if (value == value.roundToDouble()) return value.round().toString();
    return _trimZeros(value.toStringAsFixed(decimals).replaceAll('.', ','));
  }

  static String _trimZeros(String text) {
    if (!text.contains(',')) return text;
    var t = text.replaceAll(RegExp(r'0+$'), '');
    if (t.endsWith(',')) t = t.substring(0, t.length - 1);
    return t;
  }
}

/// Permite apenas digitos, uma virgula ou ponto e (opcional) sinal.
class DecimalInputFormatter extends TextInputFormatter {
  const DecimalInputFormatter({this.decimals = 2, this.signed = false});

  final int decimals;
  final bool signed;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final pattern = decimals == 0
        ? (signed ? r'^-?\d*$' : r'^\d*$')
        : (signed
              ? '^-?\\d*([,.]\\d{0,$decimals})?\$'
              : '^\\d*([,.]\\d{0,$decimals})?\$');
    return RegExp(pattern).hasMatch(text) ? newValue : oldValue;
  }
}
