import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_logo.dart';
import '../application/session_controller.dart';
import 'branch_selection_dialog.dart';

/// Rota `/selecionar-filial`: fundo da marca com o pop-up de selecao por cima.
/// Sair no pop-up encerra a sessao; escolher libera o app.
class BranchSelectionPage extends ConsumerStatefulWidget {
  const BranchSelectionPage({super.key});

  @override
  ConsumerState<BranchSelectionPage> createState() =>
      _BranchSelectionPageState();
}

class _BranchSelectionPageState extends ConsumerState<BranchSelectionPage> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    if (_opened || !mounted) return;
    final session = ref.read(sessionControllerProvider).context;
    if (session == null) return;
    _opened = true;

    final result = await BranchSelectionDialog.show(context, session: session);
    if (!mounted) return;

    final controller = ref.read(sessionControllerProvider.notifier);
    if (result == null) {
      await controller.signOut();
    } else {
      await controller.select(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.brandGradient),
        child: Center(child: AppLogo(size: 56, color: Colors.white)),
      ),
    );
  }
}
