import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/session_context.dart';
import 'session_controller.dart';

/// Filial aberta (null fora de uma sessao pronta).
final currentBranchProvider = Provider<BranchRef?>(
  (ref) => ref.watch(sessionControllerProvider.select((s) => s.selected)),
);

/// Pode ver a tela [code] na filial atual?
final canReadProvider = Provider.family<bool, String>(
  (ref, code) => ref.watch(currentBranchProvider)?.canRead(code) ?? false,
);

/// Pode criar registros na tela [code]?
final canCreateProvider = Provider.family<bool, String>(
  (ref, code) => ref.watch(currentBranchProvider)?.canCreate(code) ?? false,
);

/// Pode alterar registros na tela [code]?
final canUpdateProvider = Provider.family<bool, String>(
  (ref, code) => ref.watch(currentBranchProvider)?.canUpdate(code) ?? false,
);
