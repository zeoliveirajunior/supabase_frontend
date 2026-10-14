import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profiles/application/profiles_controller.dart';
import '../data/event_repository.dart';
import '../domain/event_log_entry.dart';

/// Filtros da aba Atividades. Default: ultimos 30 dias.
final eventFiltersProvider = StateProvider.autoDispose<EventFilters>(
  (ref) => EventFilters.lastDays(30),
);

/// Pagina de atividades da empresa atual conforme os filtros.
class EventsController extends AutoDisposeAsyncNotifier<EventLogPage> {
  @override
  Future<EventLogPage> build() async {
    final nrCompany = ref.watch(currentCompanyProvider);
    final filters = ref.watch(eventFiltersProvider);
    if (nrCompany == null) {
      return const EventLogPage(total: 0, page: 1, pageSize: 50, events: []);
    }
    return ref
        .read(eventRepositoryProvider)
        .list(nrCompany: nrCompany, filters: filters);
  }
}

final eventsProvider =
    AsyncNotifierProvider.autoDispose<EventsController, EventLogPage>(
      EventsController.new,
    );
