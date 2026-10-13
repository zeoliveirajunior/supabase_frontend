import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
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
import '../domain/company_user.dart';

/// Vincular usuario (user = null: e-mail de conta ja existente + acesso por
/// filial) ou editar (situacao, motivo e acesso por filial). true = salvou.
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
  final _email = TextEditingController();
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
    _email.dispose();
    _reason.dispose();
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
        await controller.link(email: _email.text.trim(), branches: _selected);
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
        constraints: const BoxConstraints(maxWidth: 560),
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
                  _isEdit ? Strings.editUser : Strings.linkUser,
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
                ] else ...[
                  AppTextField(
                    label: Strings.email,
                    hint: Strings.emailHint,
                    controller: _email,
                    autofocus: true,
                    enabled: !_saving,
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.compose([
                      Validators.required(),
                      Validators.email(),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    Strings.userEmailHelp,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
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
