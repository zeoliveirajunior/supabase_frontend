import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../../../shared/formatters/masks.dart';
import '../../../shared/validators/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snack.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/choice.dart';
import '../../../shared/widgets/searchable_dropdown.dart';
import '../../profiles/application/profiles_controller.dart';
import '../../profiles/domain/access_profile.dart';
import '../application/users_controller.dart';
import '../data/user_repository.dart';
import '../domain/company_user.dart';

/// Novo usuario (user = null): cadastro completo com senha inicial, criado
/// pela Edge Function user-create (se o e-mail ja tiver conta, so vincula).
/// Edicao: situacao, motivo e acesso por filial. Devolve true quando salvou.
class UserFormDialog extends ConsumerStatefulWidget {
  const UserFormDialog({super.key, this.user});

  final CompanyUser? user;

  static Future<bool> show(BuildContext context, {CompanyUser? user}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => UserFormDialog(user: user),
    );
    return saved ?? false;
  }

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _cpf = TextEditingController();
  final _phone = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final TextEditingController _reason = TextEditingController(
    text: widget.user?.vcBlockReason ?? '',
  );
  late int _status = widget.user?.itStatus ?? UserStatus.active;

  /// nr_branch -> nr_profile escolhido (ausente = sem acesso).
  late final Map<int, int> _assignments = {
    for (final b in widget.user?.branches ?? const <UserBranchProfile>[])
      b.nrBranch: b.nrProfile,
  };
  bool _saving = false;

  bool get _isEdit => widget.user != null;

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _cpf,
      _phone,
      _mobile,
      _password,
      _confirm,
      _reason,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<BranchAssignment> get _selected => [
    for (final e in _assignments.entries)
      BranchAssignment(nrBranch: e.key, nrProfile: e.value),
  ];

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selected.isEmpty) {
      AppSnack.error(context, Strings.userBranchesRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      final controller = ref.read(usersProvider.notifier);
      if (_isEdit) {
        final u = widget.user!;
        await controller.updateUser(
          nrUser: u.nrUser,
          itStatus:
              _status != u.itStatus ||
                  _reason.text.trim() != (u.vcBlockReason ?? '')
              ? _status
              : null,
          blockReason: _status == UserStatus.blocked
              ? _reason.text.trim()
              : null,
          branches: _selected,
        );
      } else {
        await controller.create(
          NewUser(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            cpf: _cpf.text.isEmpty ? null : Masks.unmask(_cpf.text),
            phone: _phone.text.isEmpty ? null : _phone.text,
            mobile: _mobile.text.isEmpty ? null : _mobile.text,
            branches: _selected,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnack.error(context, describeError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = context.isMobile;
    final branches = ref.watch(branchesProvider);
    final profiles = ref.watch(profilesProvider);

    final statusChoices = const [
      Choice<int>(value: UserStatus.active, label: Strings.statusActive),
      Choice<int>(value: UserStatus.blocked, label: Strings.statusBlocked),
      Choice<int>(value: UserStatus.inactive, label: Strings.statusInactive),
    ];

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEdit ? Strings.editUser : Strings.newUser,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_isEdit) ...[
                  _UserSummary(user: widget.user!),
                  const SizedBox(height: AppSpacing.lg),
                  SearchableDropdown<Choice<int>>(
                    label: Strings.status,
                    items: statusChoices,
                    value: statusChoices.firstWhere((c) => c.value == _status),
                    itemLabel: (c) => c.label,
                    enabled: !_saving,
                    onChanged: (c) => setState(() => _status = c.value!),
                  ),
                  if (_status == UserStatus.blocked) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: Strings.blockReason,
                      controller: _reason,
                      maxLength: 200,
                      enabled: !_saving,
                      prefixIcon: Icons.block_rounded,
                    ),
                  ],
                ] else
                  _NewUserFields(
                    name: _name,
                    email: _email,
                    cpf: _cpf,
                    phone: _phone,
                    mobile: _mobile,
                    password: _password,
                    confirm: _confirm,
                    enabled: !_saving,
                    isMobile: isMobile,
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  Strings.userAccessTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                branches.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(
                    describeError(e),
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  data: (list) {
                    final active = (profiles.valueOrNull ?? const [])
                        .where((p) => p.isActive)
                        .toList();
                    final choices = [
                      const Choice<int>(
                        value: null,
                        label: Strings.userNoAccess,
                      ),
                      for (final p in active)
                        Choice<int>(
                          value: p.nrProfile,
                          label: p.vcName,
                          subtitle: '${Strings.level} ${p.itLevel}',
                        ),
                    ];
                    return Column(
                      children: [
                        for (final b in list)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _BranchRow(
                              branch: b,
                              choices: choices,
                              value: choices.firstWhere(
                                (c) => c.value == _assignments[b.nrBranch],
                                orElse: () => choices.first,
                              ),
                              enabled: !_saving,
                              onChanged: (c) => setState(() {
                                if (c.value == null) {
                                  _assignments.remove(b.nrBranch);
                                } else {
                                  _assignments[b.nrBranch] = c.value!;
                                }
                              }),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: Strings.cancel,
                        variant: AppButtonVariant.secondary,
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: Strings.save,
                        loading: _saving,
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Campos do cadastro completo (nome, e-mail, CPF, telefones, senha inicial).
class _NewUserFields extends StatelessWidget {
  const _NewUserFields({
    required this.name,
    required this.email,
    required this.cpf,
    required this.phone,
    required this.mobile,
    required this.password,
    required this.confirm,
    required this.enabled,
    required this.isMobile,
  });

  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController cpf;
  final TextEditingController phone;
  final TextEditingController mobile;
  final TextEditingController password;
  final TextEditingController confirm;
  final bool enabled;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget pair(Widget a, Widget b) => isMobile
        ? Column(
            children: [
              a,
              const SizedBox(height: AppSpacing.md),
              b,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: a),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: b),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: Strings.fullName,
          controller: name,
          autofocus: true,
          enabled: enabled,
          maxLength: 60,
          prefixIcon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          validator: Validators.required(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: Strings.email,
          hint: Strings.emailHint,
          controller: email,
          enabled: enabled,
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.compose([
            Validators.required(),
            Validators.email(),
          ]),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          Strings.newUserHelp,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.md),
        pair(
          AppTextField(
            label: Strings.cpf,
            controller: cpf,
            enabled: enabled,
            mask: MaskType.cpf,
            prefixIcon: Icons.badge_outlined,
            validator: Validators.cpf(),
          ),
          AppTextField(
            label: Strings.mobile,
            controller: mobile,
            enabled: enabled,
            mask: MaskType.phone,
            prefixIcon: Icons.smartphone_rounded,
            validator: Validators.phone(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: Strings.phone,
          controller: phone,
          enabled: enabled,
          mask: MaskType.phone,
          prefixIcon: Icons.phone_outlined,
          validator: Validators.phone(),
        ),
        const SizedBox(height: AppSpacing.md),
        pair(
          AppPasswordField(
            label: Strings.initialPassword,
            controller: password,
            enabled: enabled,
            autofillHints: const [AutofillHints.newPassword],
            validator: Validators.compose([
              Validators.required(),
              Validators.minLength(8),
            ]),
          ),
          AppPasswordField(
            label: Strings.confirmPassword,
            controller: confirm,
            enabled: enabled,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) {
              if (v == null || v.isEmpty) return Strings.required;
              return v == password.text ? null : Strings.passwordsDiffer;
            },
          ),
        ),
      ],
    );
  }
}

class _UserSummary extends StatelessWidget {
  const _UserSummary({required this.user});

  final CompanyUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.mint,
            foregroundColor: AppColors.primaryDark,
            child: Text(
              user.initials,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.vcName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  [
                    if (user.vcEmail != null) user.vcEmail!,
                    '${Strings.userCode} ${user.nrCompanyUser}',
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          AppStatusChip(status: user.itStatus, compact: true),
        ],
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  const _BranchRow({
    required this.branch,
    required this.choices,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final Branch branch;
  final List<Choice<int>> choices;
  final Choice<int> value;
  final bool enabled;
  final ValueChanged<Choice<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasAccess = value.value != null;
    return Row(
      children: [
        Icon(
          branch.idMain
              ? Icons.store_mall_directory_rounded
              : Icons.storefront_outlined,
          color: hasAccess ? AppColors.primaryDark : AppColors.muted,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 5,
          child: Text(
            branch.vcName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: hasAccess ? AppColors.ink : AppColors.muted,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 6,
          child: SearchableDropdown<Choice<int>>(
            label: Strings.profile,
            items: choices,
            value: value,
            enabled: enabled,
            itemLabel: (c) => c.label,
            itemSubtitle: (c) => c.subtitle,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
