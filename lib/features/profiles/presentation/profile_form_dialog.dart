import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../../../shared/validators/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snack.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../application/profiles_controller.dart';
import '../domain/access_profile.dart';

/// Novo perfil (profile = null) ou edicao. Devolve true quando salvou.
class ProfileFormDialog extends ConsumerStatefulWidget {
  const ProfileFormDialog({super.key, this.profile});

  final AccessProfile? profile;

  static Future<bool> show(
    BuildContext context, {
    AccessProfile? profile,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ProfileFormDialog(profile: profile),
    );
    return saved ?? false;
  }

  @override
  ConsumerState<ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends ConsumerState<ProfileFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.profile?.vcName ?? '',
  );
  late double _level = (widget.profile?.itLevel ?? 0).toDouble();
  late bool _active = widget.profile?.isActive ?? true;
  bool _saving = false;

  bool get _isEdit => widget.profile != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final controller = ref.read(profilesProvider.notifier);
      final name = _name.text.trim();
      final level = _level.round();
      if (_isEdit) {
        final p = widget.profile!;
        await controller.updateProfile(
          nrProfile: p.nrProfile,
          vcName: name != p.vcName ? name : null,
          itLevel: level != p.itLevel ? level : null,
          itStatus: _active != p.isActive
              ? (_active ? SimpleStatus.active : SimpleStatus.inactive)
              : null,
        );
      } else {
        await controller.create(vcName: name, itLevel: level);
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
    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
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
                  _isEdit ? Strings.editProfile : Strings.newProfile,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: Strings.profileName,
                  controller: _name,
                  maxLength: 30,
                  autofocus: !_isEdit,
                  enabled: !_saving,
                  prefixIcon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.required(),
                  onFieldSubmitted: (_) => _save(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Strings.profileLevel,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${_level.round()}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _level,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${_level.round()}',
                  onChanged: _saving ? null : (v) => setState(() => _level = v),
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: const Text('${Strings.levelUser} · 0'),
                      selected: _level.round() == 0,
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _level = 0),
                    ),
                    ChoiceChip(
                      label: const Text('${Strings.levelAdmin} · 100'),
                      selected: _level.round() == 100,
                      onSelected: _saving
                          ? null
                          : (_) => setState(() => _level = 100),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  Strings.profileLevelHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                if (_isEdit) ...[
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(Strings.profileActive),
                    value: _active,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _active = v),
                  ),
                ],
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
