import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/application/session_controller.dart';
import '../data/profile_repository.dart';
import '../domain/access_profile.dart';

/// Empresa atual (filial escolhida). Null fora de uma sessao pronta.
final currentCompanyProvider = Provider<int?>(
  (ref) =>
      ref.watch(sessionControllerProvider.select((s) => s.selected?.nrCompany)),
);

/// Filial atual (contexto do log de atividades).
final currentBranchNumberProvider = Provider<int?>(
  (ref) =>
      ref.watch(sessionControllerProvider.select((s) => s.selected?.nrBranch)),
);

/// Administrador da empresa atual?
final isCompanyAdminProvider = Provider<bool>(
  (ref) => ref.watch(
    sessionControllerProvider.select(
      (s) => s.selected?.company.idAdmin ?? false,
    ),
  ),
);

/// Catalogo de telas (global). Fica em cache enquanto o app viver.
final screensProvider = FutureProvider<List<ScreenInfo>>(
  (ref) => ref.read(profileRepositoryProvider).screens(),
);

/// Perfis da empresa atual (ativos e inativos). Recarrega ao trocar de empresa.
class ProfilesController extends AutoDisposeAsyncNotifier<List<AccessProfile>> {
  @override
  Future<List<AccessProfile>> build() async {
    final nrCompany = ref.watch(currentCompanyProvider);
    if (nrCompany == null) return const [];
    return ref.read(profileRepositoryProvider).list(nrCompany: nrCompany);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> create({
    required String vcName,
    required int itLevel,
    List<ProfileScreen>? screens,
  }) async {
    final nrCompany = ref.read(currentCompanyProvider);
    if (nrCompany == null) return;
    await ref
        .read(profileRepositoryProvider)
        .create(
          nrCompany: nrCompany,
          nrBranch: ref.read(currentBranchNumberProvider),
          vcName: vcName,
          itLevel: itLevel,
          screens: screens,
        );
    await refresh();
  }

  Future<void> updateProfile({
    required int nrProfile,
    String? vcName,
    int? itLevel,
    int? itStatus,
    List<ProfileScreen>? screens,
  }) async {
    final nrCompany = ref.read(currentCompanyProvider);
    if (nrCompany == null) return;
    await ref
        .read(profileRepositoryProvider)
        .update(
          nrCompany: nrCompany,
          nrBranch: ref.read(currentBranchNumberProvider),
          nrProfile: nrProfile,
          vcName: vcName,
          itLevel: itLevel,
          itStatus: itStatus,
          screens: screens,
        );
    await refresh();
  }
}

final profilesProvider =
    AsyncNotifierProvider.autoDispose<ProfilesController, List<AccessProfile>>(
      ProfilesController.new,
    );
