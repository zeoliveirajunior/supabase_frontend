/// Linha de `ad.event_log_list`: o que aconteceu no sistema.
class EventLogEntry {
  const EventLogEntry({
    required this.nrEvent,
    required this.nrUser,
    required this.vcUser,
    required this.vcAction,
    required this.vcEntity,
    required this.vcSummary,
    required this.dhEvent,
    this.uuScreen,
    this.vcScreenCode,
    this.vcScreen,
    this.vcKey,
    this.jsDetail,
    this.nrBranch,
    this.vcBranch,
  });

  factory EventLogEntry.fromJson(Map<String, dynamic> json) => EventLogEntry(
    nrEvent: (json['nr_event'] as num).toInt(),
    nrUser: (json['nr_user'] as num).toInt(),
    vcUser: json['vc_user']?.toString() ?? '',
    uuScreen: json['uu_screen']?.toString(),
    vcScreenCode: json['vc_screen_code']?.toString(),
    vcScreen: json['vc_screen']?.toString(),
    vcAction: json['vc_action']?.toString() ?? 'OTHER',
    vcEntity: json['vc_entity']?.toString() ?? '',
    vcKey: json['vc_key']?.toString(),
    vcSummary: json['vc_summary']?.toString() ?? '',
    jsDetail: json['js_detail'] is Map
        ? (json['js_detail'] as Map).cast<String, dynamic>()
        : null,
    nrBranch: (json['nr_branch'] as num?)?.toInt(),
    vcBranch: json['vc_branch']?.toString(),
    dhEvent:
        DateTime.tryParse(json['dh_event']?.toString() ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  final int nrEvent;
  final int nrUser;
  final String vcUser;
  final String? uuScreen;
  final String? vcScreenCode;
  final String? vcScreen;

  /// CREATE · UPDATE · DELETE · OTHER
  final String vcAction;
  final String vcEntity;
  final String? vcKey;
  final String vcSummary;
  final Map<String, dynamic>? jsDetail;
  final int? nrBranch;
  final String? vcBranch;
  final DateTime dhEvent;
}

/// Pagina de `event_log_list`.
class EventLogPage {
  const EventLogPage({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.events,
  });

  factory EventLogPage.fromJson(Map<String, dynamic> json) => EventLogPage(
    total: (json['qt_total'] as num? ?? 0).toInt(),
    page: (json['nr_page'] as num? ?? 1).toInt(),
    pageSize: (json['qt_page_size'] as num? ?? 50).toInt(),
    events: [
      for (final e in (json['events'] as List? ?? const []))
        EventLogEntry.fromJson((e as Map).cast<String, dynamic>()),
    ],
  );

  final int total;
  final int page;
  final int pageSize;
  final List<EventLogEntry> events;

  int get pageCount => total == 0 ? 1 : ((total - 1) ~/ pageSize) + 1;
}

/// Tipos de acao do log de atividades, com rotulo.
abstract final class EventAction {
  static const create = 'CREATE';
  static const update = 'UPDATE';
  static const delete = 'DELETE';
  static const other = 'OTHER';

  static const all = [create, update, delete, other];

  static String label(String? value) => switch (value) {
    create => 'Criação',
    update => 'Alteração',
    delete => 'Exclusão',
    other => 'Outra',
    _ => '-',
  };
}
