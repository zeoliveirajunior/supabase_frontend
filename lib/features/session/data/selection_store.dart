import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ids da ultima filial aberta, lembrados por usuario no dispositivo.
class SelectedBranchIds {
  const SelectedBranchIds({required this.nrCompany, required this.nrBranch});

  final int nrCompany;
  final int nrBranch;
}

/// Guarda a ultima empresa/filial por usuario (`last_branch_<uuid do Auth>`).
/// Na proxima abertura o app ja entra nela, sem perguntar de novo.
class SelectionStore {
  static const _prefix = 'last_branch_';

  Future<SelectedBranchIds?> read(String authUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$authUserId');
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final company = int.tryParse(parts[0]);
    final branch = int.tryParse(parts[1]);
    if (company == null || branch == null) return null;
    return SelectedBranchIds(nrCompany: company, nrBranch: branch);
  }

  Future<void> save(String authUserId, SelectedBranchIds ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefix$authUserId',
      '${ids.nrCompany}:${ids.nrBranch}',
    );
  }

  Future<void> clear(String authUserId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$authUserId');
  }
}

final selectionStoreProvider = Provider<SelectionStore>(
  (ref) => SelectionStore(),
);
