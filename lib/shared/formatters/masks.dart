import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Mascaras de entrada. Use `AppTextField(mask: MaskType.cpf)`.
/// O valor enviado ao backend e sempre o SEM mascara: [Masks.unmask].
enum MaskType { cpf, cnpj, cpfCnpj, phone, cep, date }

abstract final class Masks {
  static final Map<String, RegExp> _digitsOnly = {'#': RegExp(r'[0-9]')};

  static const String cpfMask = '###.###.###-##';
  static const String cnpjMask = '##.###.###/####-##';
  static const String phoneMobileMask = '(##) #####-####';
  static const String phoneLandlineMask = '(##) ####-####';
  static const String cepMask = '#####-###';
  static const String dateMask = '##/##/####';

  /// Remove tudo que nao e digito.
  static String unmask(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  static TextInputFormatter formatter(MaskType type) {
    return switch (type) {
      MaskType.cpf => _fixed(cpfMask),
      MaskType.cnpj => _fixed(cnpjMask),
      MaskType.cep => _fixed(cepMask),
      MaskType.date => _fixed(dateMask),
      MaskType.cpfCnpj => DynamicMaskFormatter(_cpfCnpjMaskFor, maxDigits: 14),
      MaskType.phone => DynamicMaskFormatter(_phoneMaskFor, maxDigits: 11),
    };
  }

  /// Formata um valor (com ou sem mascara) para exibicao.
  static String format(MaskType type, String value) {
    final digits = unmask(value);
    final mask = switch (type) {
      MaskType.cpf => cpfMask,
      MaskType.cnpj => cnpjMask,
      MaskType.cep => cepMask,
      MaskType.date => dateMask,
      MaskType.cpfCnpj => _cpfCnpjMaskFor(digits),
      MaskType.phone => _phoneMaskFor(digits),
    };
    return apply(mask, digits);
  }

  /// Aplica [mask] (`#` = digito) sobre [digits], parando quando acabam os digitos.
  static String apply(String mask, String digits) {
    final out = StringBuffer();
    var i = 0;
    for (final ch in mask.split('')) {
      if (i >= digits.length) break;
      if (ch == '#') {
        out.write(digits[i++]);
      } else {
        out.write(ch);
      }
    }
    return out.toString();
  }

  static String _cpfCnpjMaskFor(String digits) =>
      digits.length <= 11 ? cpfMask : cnpjMask;

  static String _phoneMaskFor(String digits) =>
      digits.length <= 10 ? phoneLandlineMask : phoneMobileMask;

  static TextInputFormatter _fixed(String mask) => MaskTextInputFormatter(
    mask: mask,
    filter: _digitsOnly,
    type: MaskAutoCompletionType.lazy,
  );
}

/// Mascara que muda conforme a quantidade de digitos (CPF/CNPJ, telefone).
class DynamicMaskFormatter extends TextInputFormatter {
  DynamicMaskFormatter(this.maskFor, {required this.maxDigits});

  final String Function(String digits) maskFor;
  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = Masks.unmask(newValue.text);
    if (digits.length > maxDigits) digits = digits.substring(0, maxDigits);
    final text = Masks.apply(maskFor(digits), digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
