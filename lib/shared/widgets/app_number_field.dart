import 'package:flutter/material.dart';

import '../formatters/numbers.dart';

/// Campo numerico (dinheiro, percentual, quantidade) com virgula decimal.
/// O valor digitado e lido com [Numbers.parse].
///
/// ```dart
/// AppNumberField(label: 'Preço (R$)', controller: c, prefixText: 'R\$ ')
/// AppNumberField(label: 'Lucro', controller: c, suffixText: '%', decimals: 2)
/// ```
class AppNumberField extends StatelessWidget {
  const AppNumberField({
    super.key,
    required this.label,
    this.controller,
    this.prefixText,
    this.suffixText,
    this.helper,
    this.decimals = 2,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction,
    this.required = false,
    this.positive = false,
    this.dense = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? prefixText;
  final String? suffixText;
  final String? helper;
  final int decimals;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool autofocus;
  final TextInputAction? textInputAction;

  /// Reprova vazio.
  final bool required;

  /// Reprova zero ou negativo.
  final bool positive;

  /// Menos altura (linhas de tabela editavel).
  final bool dense;

  String? _validate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return required ? _Messages.required : null;
    }
    final n = Numbers.parse(text);
    if (n == null) return _Messages.invalid;
    if (positive && n <= 0) return _Messages.positive;
    return validator?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: TextInputType.numberWithOptions(decimal: decimals > 0),
      inputFormatters: [DecimalInputFormatter(decimals: decimals)],
      validator: _validate,
      onChanged: onChanged,
      textInputAction: textInputAction,
      textAlign: dense ? TextAlign.right : TextAlign.start,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        suffixText: suffixText,
        helperText: helper,
        helperMaxLines: 3,
        isDense: dense,
        contentPadding: dense
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
            : null,
      ),
    );
  }
}

abstract final class _Messages {
  static const required = 'Campo obrigatório.';
  static const invalid = 'Número inválido.';
  static const positive = 'Informe um valor maior que zero.';
}
