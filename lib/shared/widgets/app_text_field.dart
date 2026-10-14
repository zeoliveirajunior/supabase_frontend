import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../formatters/masks.dart';

/// Campo de texto padrao do app: rotulo, icone, mascara e validacao.
///
/// ```dart
/// AppTextField(label: 'CPF', mask: MaskType.cpf, validator: Validators.cpf())
/// ```
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.mask,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.autofillHints,
    this.onFieldSubmitted,
    this.onChanged,
    this.enabled = true,
    this.maxLength,
    this.focusNode,
    this.autovalidateMode,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.initialValue,
    this.maxLines = 1,
    this.minLines,
    this.helperText,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final MaskType? mask;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final int? maxLength;
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final String? initialValue;

  /// Mais de uma linha = area de texto (observacoes, notas).
  final int? maxLines;
  final int? minLines;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      initialValue: controller == null ? initialValue : null,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscureText,
      autofocus: autofocus,
      keyboardType:
          keyboardType ?? (mask != null ? TextInputType.number : null),
      inputFormatters: mask == null ? null : [Masks.formatter(mask!)],
      validator: validator,
      autovalidateMode: autovalidateMode,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon,
        helperText: helperText,
        counterText: '',
      ),
    );
  }
}

/// Campo de senha com botao de mostrar/ocultar.
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints = const [AutofillHints.password],
    this.enabled = true,
    this.focusNode,
    this.autovalidateMode,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      controller: widget.controller,
      hint: widget.hint,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      autovalidateMode: widget.autovalidateMode,
      obscureText: _obscure,
      prefixIcon: Icons.lock_outline_rounded,
      keyboardType: TextInputType.visiblePassword,
      suffixIcon: IconButton(
        tooltip: _obscure ? Strings.showPassword : Strings.hidePassword,
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
