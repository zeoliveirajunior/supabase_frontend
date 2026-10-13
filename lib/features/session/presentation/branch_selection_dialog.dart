import 'package:flutter/material.dart';

import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../../../shared/formatters/masks.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/searchable_dropdown.dart';
import '../domain/session_context.dart';

/// Pop-up "Onde voce vai trabalhar hoje?": empresa e filial com pesquisa.
///
/// Devolve o [BranchRef] escolhido, ou null quando o usuario sai
/// ([allowCancel] = false) ou cancela ([allowCancel] = true).
class BranchSelectionDialog extends StatefulWidget {
  const BranchSelectionDialog({
    super.key,
    required this.session,
    this.current,
    this.allowCancel = false,
  });

  final SessionContext session;
  final BranchRef? current;
  final bool allowCancel;

  static Future<BranchRef?> show(
    BuildContext context, {
    required SessionContext session,
    BranchRef? current,
    bool allowCancel = false,
  }) {
    return showDialog<BranchRef>(
      context: context,
      barrierDismissible: allowCancel,
      builder: (_) => BranchSelectionDialog(
        session: session,
        current: current,
        allowCancel: allowCancel,
      ),
    );
  }

  @override
  State<BranchSelectionDialog> createState() => _BranchSelectionDialogState();
}

class _BranchSelectionDialogState extends State<BranchSelectionDialog> {
  CompanyAccess? _company;
  BranchAccess? _branch;

  @override
  void initState() {
    super.initState();
    final companies = widget.session.companies;
    _company =
        widget.current?.company ??
        (companies.length == 1 ? companies.single : null);
    _branch = widget.current?.branch ?? _onlyBranchOf(_company);
  }

  BranchAccess? _onlyBranchOf(CompanyAccess? company) =>
      company != null && company.branches.length == 1
      ? company.branches.single
      : null;

  void _pickCompany(CompanyAccess company) {
    setState(() {
      _company = company;
      _branch = _onlyBranchOf(company);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = context.isMobile;
    final canContinue = _company != null && _branch != null;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xxl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const AppLogo(size: 30),
                  const Spacer(),
                  if (widget.allowCancel)
                    IconButton(
                      tooltip: Strings.cancel,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                Strings.selectBranchTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                Strings.selectBranchSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SearchableDropdown<CompanyAccess>(
                label: Strings.company,
                items: widget.session.companies,
                value: _company,
                prefixIcon: Icons.business_rounded,
                itemLabel: (c) => c.vcName,
                itemSubtitle: (c) => c.vcCnpj == null
                    ? null
                    : Masks.format(MaskType.cnpj, c.vcCnpj!),
                itemLeading: (c) => _Avatar(text: c.vcName),
                onChanged: _pickCompany,
              ),
              const SizedBox(height: AppSpacing.md),
              SearchableDropdown<BranchAccess>(
                label: Strings.branch,
                items: _company?.branches ?? const [],
                value: _branch,
                enabled: _company != null,
                prefixIcon: Icons.store_mall_directory_rounded,
                itemLabel: (b) => b.vcName,
                itemSubtitle: (b) => <String>{
                  if (b.idMain) Strings.mainBranch,
                  if (b.isAdmin) Strings.admin,
                  for (final p in b.profiles) p.vcName,
                }.join(' · '),
                onChanged: (b) => setState(() => _branch = b),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: Strings.continueLabel,
                onPressed: canContinue
                    ? () => Navigator.of(
                        context,
                      ).pop(BranchRef(company: _company!, branch: _branch!))
                    : null,
              ),
              if (!widget.allowCancel) ...[
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: Strings.signOut,
                  variant: AppButtonVariant.text,
                  icon: Icons.logout_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final initial = text.trim().isEmpty ? '?' : text.trim()[0].toUpperCase();
    return CircleAvatar(
      backgroundColor: AppColors.mint,
      foregroundColor: AppColors.primaryDark,
      child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
