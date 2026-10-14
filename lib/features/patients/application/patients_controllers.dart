import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profiles/application/profiles_controller.dart';
import '../data/patient_repository.dart';
import '../domain/patient_models.dart';

final patientFiltersProvider = StateProvider.autoDispose<PatientFilters>(
  (_) => const PatientFilters(),
);

/// Lista paginada da filial atual, conforme os filtros.
class PatientsController extends AutoDisposeAsyncNotifier<PatientPage?> {
  @override
  Future<PatientPage?> build() async {
    final nrCompany = ref.watch(currentCompanyProvider);
    final nrBranch = ref.watch(currentBranchNumberProvider);
    final filters = ref.watch(patientFiltersProvider);
    if (nrCompany == null || nrBranch == null) return null;
    return ref
        .read(patientRepositoryProvider)
        .list(nrCompany: nrCompany, nrBranch: nrBranch, filters: filters);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Cadastra e devolve o nr_patient (null sem filial).
  Future<int?> create(Map<String, dynamic> fields) async {
    final nrCompany = ref.read(currentCompanyProvider);
    final nrBranch = ref.read(currentBranchNumberProvider);
    if (nrCompany == null || nrBranch == null) return null;
    final nr = await ref
        .read(patientRepositoryProvider)
        .create(nrCompany: nrCompany, nrBranch: nrBranch, fields: fields);
    ref.invalidateSelf();
    return nr;
  }
}

final patientsProvider =
    AsyncNotifierProvider.autoDispose<PatientsController, PatientPage?>(
      PatientsController.new,
    );

/// Ficha de um paciente (patient_get) com as acoes da tela.
class PatientRecordController
    extends AutoDisposeFamilyAsyncNotifier<PatientRecord?, int> {
  @override
  Future<PatientRecord?> build(int arg) async {
    final nrCompany = ref.watch(currentCompanyProvider);
    final nrBranch = ref.watch(currentBranchNumberProvider);
    if (nrCompany == null || nrBranch == null) return null;
    return ref
        .read(patientRepositoryProvider)
        .get(nrCompany: nrCompany, nrBranch: nrBranch, nrPatient: arg);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  (int, int)? get _branch {
    final nrCompany = ref.read(currentCompanyProvider);
    final nrBranch = ref.read(currentBranchNumberProvider);
    if (nrCompany == null || nrBranch == null) return null;
    return (nrCompany, nrBranch);
  }

  /// Update parcial da ficha (so as chaves de [fields]).
  Future<void> save(Map<String, dynamic> fields) async {
    final b = _branch;
    if (b == null) return;
    await ref
        .read(patientRepositoryProvider)
        .update(
          nrCompany: b.$1,
          nrBranch: b.$2,
          nrPatient: arg,
          fields: fields,
        );
    ref.invalidate(patientsProvider);
    await refresh();
  }

  Future<void> setActive(bool active) => save({'it_status': active ? 1 : 90});

  Future<void> addNote(String text) async {
    final b = _branch;
    if (b == null) return;
    await ref
        .read(patientRepositoryProvider)
        .addNote(nrCompany: b.$1, nrBranch: b.$2, nrPatient: arg, text: text);
    await refresh();
  }

  Future<void> deleteNote(int nrNote) async {
    final b = _branch;
    if (b == null) return;
    await ref
        .read(patientRepositoryProvider)
        .deleteNote(
          nrCompany: b.$1,
          nrBranch: b.$2,
          nrPatient: arg,
          nrNote: nrNote,
        );
    await refresh();
  }
}

final patientRecordProvider = AsyncNotifierProvider.autoDispose
    .family<PatientRecordController, PatientRecord?, int>(
      PatientRecordController.new,
    );
