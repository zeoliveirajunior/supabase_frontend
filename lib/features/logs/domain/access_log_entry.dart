/// Linha de `ad.access_log_list`.
class AccessLogEntry {
  const AccessLogEntry({
    required this.nrAccess,
    required this.nrUser,
    required this.vcUser,
    required this.dhAccess,
    this.vcEmail,
    this.nrCompany,
    this.nrBranch,
    this.vcBranch,
    this.itApp,
    this.vcIp,
    this.vcDevice,
    this.vcUserAgent,
    this.vcAppVersion,
  });

  factory AccessLogEntry.fromJson(Map<String, dynamic> json) => AccessLogEntry(
    nrAccess: (json['nr_access'] as num).toInt(),
    nrUser: (json['nr_user'] as num).toInt(),
    vcUser: json['vc_user']?.toString() ?? '',
    vcEmail: json['vc_email']?.toString(),
    nrCompany: (json['nr_company'] as num?)?.toInt(),
    nrBranch: (json['nr_branch'] as num?)?.toInt(),
    vcBranch: json['vc_branch']?.toString(),
    itApp: (json['it_app'] as num?)?.toInt(),
    vcIp: json['vc_ip']?.toString(),
    vcDevice: json['vc_device']?.toString(),
    vcUserAgent: json['vc_user_agent']?.toString(),
    vcAppVersion: json['vc_app_version']?.toString(),
    dhAccess:
        DateTime.tryParse(json['dh_access']?.toString() ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  final int nrAccess;
  final int nrUser;
  final String vcUser;
  final String? vcEmail;
  final int? nrCompany;
  final int? nrBranch;
  final String? vcBranch;

  /// 1 web · 2 android · 3 ios · 9 outro.
  final int? itApp;
  final String? vcIp;
  final String? vcDevice;
  final String? vcUserAgent;
  final String? vcAppVersion;
  final DateTime dhAccess;
}

/// Pagina de `access_log_list`.
class AccessLogPage {
  const AccessLogPage({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.logs,
  });

  factory AccessLogPage.fromJson(Map<String, dynamic> json) => AccessLogPage(
    total: (json['qt_total'] as num? ?? 0).toInt(),
    page: (json['nr_page'] as num? ?? 1).toInt(),
    pageSize: (json['qt_page_size'] as num? ?? 50).toInt(),
    logs: [
      for (final l in (json['logs'] as List? ?? const []))
        AccessLogEntry.fromJson((l as Map).cast<String, dynamic>()),
    ],
  );

  final int total;
  final int page;
  final int pageSize;
  final List<AccessLogEntry> logs;

  int get pageCount => total == 0 ? 1 : ((total - 1) ~/ pageSize) + 1;
  bool get hasPrevious => page > 1;
  bool get hasNext => page < pageCount;
}

/// Tipo de app do log, com rotulo.
abstract final class AppKind {
  static const int web = 1;
  static const int android = 2;
  static const int ios = 3;
  static const int other = 9;

  static String label(int? value) => switch (value) {
    web => 'Web',
    android => 'Android',
    ios => 'iOS',
    other => 'Outro',
    _ => '-',
  };
}
