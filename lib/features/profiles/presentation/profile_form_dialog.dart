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
import '../../session/domain/screen_codes.dart';
import '../application/profiles_controller.dart';
import '../domain/access_profile.dart';

/// Novo perfil (profile = null) ou edicao: nome, nivel, ativo e a matriz
/// telas x (ler / criar / alterar). Devolve true quando salvou.
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

/// Estado editavel de uma tela na matriz.
class _Perm {
  _Perm({this.read = false, this.create = false, this.update = false});

  bool read;
  bool create;
  bool update;

  bool get any => read || create || update;
}

class _ProfileFormDialogState extends ConsumerState<ProfileFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.profile?.vcName ?? '',
  );
  late double _level = (widget.profile?.itLevel ?? 0).toDouble();
  late bool _active = widget.profile?.isActive ?? true;

  /// uu_screen -> permissoes marcadas.
  late final Map<String, _Perm> _perms = {
    for (final s in widget.profile?.screens ?? const <ProfileScreen>[])
      s.uuScreen: _Perm(read: s.idRead, create: s.idCreate, update: s.idUpdate),
  };
  bool _saving = false;

  bool get _isEdit => widget.profile != null;
  bool get _isAdminLevel => _level.round() >= 100;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  List<ProfileScreen> _selectedScreens(List<ScreenInfo> catalog) => [
    for (final s in catalog)
      if (_perms[s.uuScreen]?.any ?? false)
        ProfileScreen(
          uuScreen: s.uuScreen,
          vcCode: s.vcCode,
          vcName: s.vcName,
          idRead: true,
          idCreate: _perms[s.uuScreen]!.create,
          idUpdate: _perms[s.uuScreen]!.update,
        ),
  ];

  Future<void> _save(List<ScreenInfo> catalog) async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final controller = ref.read(profilesProvider.notifier);
      final name = _name.text.trim();
      final level = _level.round();
      final screens = _isAdminLevel
          ? <ProfileScreen>[]
          : _selectedScreens(catalog);
      if (_isEdit) {
        final p = widget.profile!;
        await controller.updateProfile(
          nrProfile: p.nrProfile,
          vcName: name != p.vcName ? name : null,
          itLevel: level != p.itLevel ? level : null,
          itStatus: _active != p.isActive
              ? (_active ? SimpleStatus.active : SimpleStatus.inactive)
              : null,
          screens: screens,
        );
      } else {
        await controller.create(vcName: name, itLevel: level, screens: screens);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnack.error(context, describeError(e));
      }
    }
  }

  void _toggle(String uuScreen, {bool? read, bool? create, bool? update}) {
    setState(() {
      final p = _perms.putIfAbsent(uuScreen, _Perm.new);
      if (read != null) {
        p.read = read;
        if (!read) {
          p.create = false;
          p.update = false;
        }
      }
      if (create != null) {
        p.create = create;
        if (create) p.read = true;
      }
      if (update != null) {
        p.update = update;
        if (update) p.read = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = context.isMobile;
    final screens = ref.watch(screensProvider);

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
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
                const SizedBox(height: AppSpacing.lg),
                Text(
                  Strings.screensTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_isAdminLevel)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.primaryDark,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(Strings.adminAllScreens)),
                      ],
                    ),
                  )
                else
                  screens.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text(
                      describeError(e),
                      style: const TextStyle(color: AppColors.danger),
                    ),
                    data: (catalog) => _PermissionMatrix(
                      screens: [
                        for (final s in catalog)
                          if (s.vcCode != ScreenCodes.dashboard) s,
                      ],
                      perms: _perms,
                      enabled: !_saving,
                      onToggle: _toggle,
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
                        onPressed: () => _save(screens.valueOrNull ?? const []),
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

/// Tabela telas x (Ler, Criar, Alterar).
class _PermissionMatrix extends StatelessWidget {
  const _PermissionMatrix({
    required this.screens,
    required this.perms,
    required this.enabled,
    required this.onToggle,
  });

  final List<ScreenInfo> screens;
  final Map<String, _Perm> perms;
  final bool enabled;
  final void Function(String uuScreen, {bool? read, bool? create, bool? update})
  onToggle;

  @override
  Widget build(BuildContext context) {
    final head = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.muted,
      fontWeight: FontWeight.w800,
    );
    Widget cell(bool value, ValueChanged<bool?>? onChanged) => SizedBox(
      width: 64,
      child: Checkbox(value: value, onChanged: onChanged),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.md),
              ),
            ),
            child: Row(
              children: [
                Expanded(child: Text(Strings.screen, style: head)),
                SizedBox(
                  width: 64,
                  child: Text(
                    Strings.permRead,
                    style: head,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    Strings.permCreate,
                    style: head,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    Strings.permUpdate,
                    style: head,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          for (final s in screens)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.vcName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (s.vcGroup != null)
                          Text(
                            s.vcGroup!,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  cell(
                    perms[s.uuScreen]?.read ?? false,
                    enabled ? (v) => onToggle(s.uuScreen, read: v) : null,
                  ),
                  cell(
                    perms[s.uuScreen]?.create ?? false,
                    enabled ? (v) => onToggle(s.uuScreen, create: v) : null,
                  ),
                  cell(
                    perms[s.uuScreen]?.update ?? false,
                    enabled ? (v) => onToggle(s.uuScreen, update: v) : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
