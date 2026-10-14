import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_gateway.dart';
import '../domain/access_log_entry.dart';

/// Filtros de `access_log_list`. Periodo em horario local; o backend compara
/// em timestamptz, por isso enviamos em UTC (ISO 8601).
class LogFilters {
  const LogFilters({
    required this.from,
    required this.to,
    this.nrUser,
    this.itApp,
    this.page = 1,
    this.pageSize = 50,
  });

  factory LogFilters.lastDays(int days) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    return LogFilters(from: start, to: end);
  }

  final DateTime from;
  final DateTime to;
  final int? nrUser;
  final int? itApp;
  final int page;
  final int pageSize;

  LogFilters copyWith({
    DateTime? from,
    DateTime? to,
    int? nrUser,
    int? itApp,
    int? page,
    bool clearUser = false,
    bool clearApp = false,
  }) => LogFilters(
    from: from ?? this.from,
    to: to ?? this.to,
    nrUser: clearUser ? null : (nrUser ?? this.nrUser),
    itApp: clearApp ? null : (itApp ?? this.itApp),
    page: page ?? this.page,
    pageSize: pageSize,
  );
}

/// `ad.access_log_list`: administrador ve a empresa, usuario comum ve o proprio.
class LogRepository {
  LogRepository(this._gateway);

  final SupabaseGateway _gateway;

  Future<AccessLogPage> list({
    required int nrCompany,
    required LogFilters filters,
  }) async {
    final json = await _gateway.rpc('access_log_list', {
      'nr_company': nrCompany,
      'dh_from': filters.from.toUtc().toIso8601String(),
      'dh_to': filters.to.toUtc().toIso8601String(),
      if (filters.nrUser != null) 'nr_user': filters.nrUser,
      if (filters.itApp != null) 'it_app': filters.itApp,
      'nr_page': filters.page,
      'qt_page_size': filters.pageSize,
    });
    return AccessLogPage.fromJson(json);
  }
}

final logRepositoryProvider = Provider<LogRepository>(
  (ref) => LogRepository(ref.watch(supabaseGatewayProvider)),
);
