import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/strings.dart';
import '../../../../shared/validators/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_snack.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Formulario de e-mail e senha. Nao conhece Supabase nem estado global:
/// valida, chama [onSubmit] e deixa o pai cuidar do resto (testavel isolado).
class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.onSubmit, this.loading = false});

  final Future<void> Function(String email, String password) onSubmit;
  final bool loading;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await widget.onSubmit(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AutofillGroup(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: Strings.email,
              hint: Strings.emailHint,
              controller: _email,
              enabled: !widget.loading,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              validator: Validators.compose([
                Validators.required(),
                Validators.email(),
              ]),
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.md),
            AppPasswordField(
              label: Strings.password,
              hint: Strings.passwordHint,
              controller: _password,
              focusNode: _passwordFocus,
              enabled: !widget.loading,
              textInputAction: TextInputAction.done,
              validator: Validators.compose([
                Validators.required(),
                Validators.minLength(6),
              ]),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.loading
                    ? null
                    : () => AppSnack.info(context, Strings.comingSoon),
                child: const Text(Strings.forgotPassword),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: Strings.signIn,
              loading: widget.loading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Strings.noAccount,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                TextButton(
                  onPressed: widget.loading
                      ? null
                      : () => AppSnack.info(context, Strings.comingSoon),
                  child: const Text(Strings.createAccount),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
