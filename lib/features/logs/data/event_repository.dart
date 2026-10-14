import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_gateway.dart';
import '../domain/event_log_entry.dart';

/// Filtros de `event_log_list` (periodo em horario local, enviado em UTC).
class EventFilters {
  const EventFilters({
    required this.from,
    required this.to,
    this.uuScreen,
    this.vcAction,
    this.nrUser,
    this.search,
    this.page = 1,
    this.pageSize = 50,
  });

  factory EventFilters.lastDays(int days) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    return EventFilters(from: start, to: end);
  }

  final DateTime from;
  final DateTime to;
  final String? uuScreen;
  final String? vcAction;
  final int? nrUser;
  final String? search;
  final int page;
  final int pageSize;

  EventFilters copyWith({
    DateTime? from,
    DateTime? to,
    String? uuScreen,
    String? vcAction,
    int? nrUser,
    String? search,
    int? page,
    bool clearScreen = false,
    bool clearAction = false,
    bool clearUser = false,
  }) => EventFilters(
    from: from ?? this.from,
    to: to ?? this.to,
    uuScreen: clearScreen ? null : (uuScreen ?? this.uuScreen),
    vcAction: clearAction ? null : (vcAction ?? this.vcAction),
    nrUser: clearUser ? null : (nrUser ?? this.nrUser),
    search: search ?? this.search,
    page: page ?? this.page,
    pageSize: pageSize,
  );
}

/// `ad.event_log_list`: administrador ve a empresa, usuario comum ve o proprio.
class EventRepository {
  EventRepository(this._gateway);

  final SupabaseGateway _gateway;

  Future<EventLogPage> list({
    required int nrCompany,
    required EventFilters filters,
  }) async {
    final json = await _gateway.rpc('event_log_list', {
      'nr_company': nrCompany,
      'dh_from': filters.from.toUtc().toIso8601String(),
      'dh_to': filters.to.toUtc().toIso8601String(),
      if (filters.uuScreen != null) 'uu_screen': filters.uuScreen,
      if (filters.vcAction != null) 'vc_action': filters.vcAction,
      if (filters.nrUser != null) 'nr_user': filters.nrUser,
      if (filters.search != null && filters.search!.trim().isNotEmpty)
        'vc_search': filters.search!.trim(),
      'nr_page': filters.page,
      'qt_page_size': filters.pageSize,
    });
    return EventLogPage.fromJson(json);
  }
}

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepository(ref.watch(supabaseGatewayProvider)),
);
