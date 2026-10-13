import '../../l10n/strings.dart';
import '../formatters/masks.dart';

typedef Validator = String? Function(String? value);

/// Validadores para `TextFormField.validator`. Combine com [Validators.compose].
/// Campos vazios passam (so [required] reprova vazio), para que opcional + mascara funcione.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static Validator required([String? message]) =>
      (value) => (value == null || value.trim().isEmpty)
      ? (message ?? Strings.required)
      : null;

  static Validator email([String? message]) => (value) {
    if (value == null || value.trim().isEmpty) return null;
    return _email.hasMatch(value.trim())
        ? null
        : (message ?? Strings.invalidEmail);
  };

  static Validator minLength(int length, [String? message]) => (value) {
    if (value == null || value.isEmpty) return null;
    return value.length >= length
        ? null
        : (message ?? Strings.minLength(length));
  };

  static Validator cpf() => (value) {
    if (value == null || value.isEmpty) return null;
    return isValidCpf(value) ? null : Strings.invalidCpf;
  };

  static Validator cnpj() => (value) {
    if (value == null || value.isEmpty) return null;
    return isValidCnpj(value) ? null : Strings.invalidCnpj;
  };

  static Validator cpfCnpj() => (value) {
    if (value == null || value.isEmpty) return null;
    final digits = Masks.unmask(value);
    final ok = digits.length <= 11 ? isValidCpf(digits) : isValidCnpj(digits);
    return ok ? null : Strings.invalidCpfCnpj;
  };

  static Validator phone() => (value) {
    if (value == null || value.isEmpty) return null;
    return isValidPhone(value) ? null : Strings.invalidPhone;
  };

  static Validator date() => (value) {
    if (value == null || value.isEmpty) return null;
    return isValidDate(value) ? null : Strings.invalidDate;
  };

  static Validator compose(List<Validator> validators) => (value) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  };

  // --- algoritmos -----------------------------------------------------------

  static bool isValidCpf(String value) {
    final d = Masks.unmask(value);
    if (d.length != 11 || _allSame(d)) return false;
    final n = d.split('').map(int.parse).toList();
    int digit(int count) {
      var sum = 0;
      for (var i = 0; i < count; i++) {
        sum += n[i] * (count + 1 - i);
      }
      final r = (sum * 10) % 11;
      return r == 10 ? 0 : r;
    }

    return digit(9) == n[9] && digit(10) == n[10];
  }

  static bool isValidCnpj(String value) {
    final d = Masks.unmask(value);
    if (d.length != 14 || _allSame(d)) return false;
    final n = d.split('').map(int.parse).toList();
    int digit(List<int> weights) {
      var sum = 0;
      for (var i = 0; i < weights.length; i++) {
        sum += n[i] * weights[i];
      }
      final r = sum % 11;
      return r < 2 ? 0 : 11 - r;
    }

    const w1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const w2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    return digit(w1) == n[12] && digit(w2) == n[13];
  }

  /// 10 digitos (fixo) ou 11 digitos com o 9 na frente (celular).
  static bool isValidPhone(String value) {
    final d = Masks.unmask(value);
    if (d.length == 10) return d[0] != '0';
    if (d.length == 11) return d[0] != '0' && d[2] == '9';
    return false;
  }

  /// dd/MM/yyyy real (31/02 reprova).
  static bool isValidDate(String value) {
    final d = Masks.unmask(value);
    if (d.length != 8) return false;
    final day = int.parse(d.substring(0, 2));
    final month = int.parse(d.substring(2, 4));
    final year = int.parse(d.substring(4, 8));
    if (year < 1900 || month < 1 || month > 12 || day < 1) return false;
    final parsed = DateTime(year, month, day);
    return parsed.year == year && parsed.month == month && parsed.day == day;
  }

  static bool _allSame(String digits) => digits.split('').toSet().length == 1;
}
