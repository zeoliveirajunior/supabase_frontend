import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profiles/application/profiles_controller.dart';
import '../data/log_repository.dart';
import '../domain/access_log_entry.dart';

/// Filtros da tela de logs. Default: ultimos 30 dias.
final logFiltersProvider = StateProvider.autoDispose<LogFilters>(
  (ref) => LogFilters.lastDays(30),
);

/// Pagina de logs da empresa atual conforme os filtros.
class LogsController extends AutoDisposeAsyncNotifier<AccessLogPage> {
  @override
  Future<AccessLogPage> build() async {
    final nrCompany = ref.watch(currentCompanyProvider);
    final filters = ref.watch(logFiltersProvider);
    if (nrCompany == null) {
      return const AccessLogPage(total: 0, page: 1, pageSize: 50, logs: []);
    }
    return ref
        .read(logRepositoryProvider)
        .list(nrCompany: nrCompany, filters: filters);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final logsProvider =
    AsyncNotifierProvider.autoDispose<LogsController, AccessLogPage>(
      LogsController.new,
    );
