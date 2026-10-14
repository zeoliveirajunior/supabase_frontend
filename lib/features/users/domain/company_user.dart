/// Filial da empresa (`ad.branch_list`).
class Branch {
  const Branch({
    required this.nrBranch,
    required this.vcName,
    required this.idMain,
    required this.itStatus,
    required this.idBlocked,
    this.vcLegalName,
    this.vcCnpj,
    this.vcCity,
    this.vcState,
    this.vcTimezone,
    this.vcBlockReason,
  });

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
    nrBranch: (json['nr_branch'] as num).toInt(),
    vcName: json['vc_name']?.toString() ?? '',
    vcLegalName: json['vc_legal_name']?.toString(),
    vcCnpj: json['vc_cnpj']?.toString(),
    vcCity: json['vc_city']?.toString(),
    vcState: json['vc_state']?.toString(),
    vcTimezone: json['vc_timezone']?.toString(),
    idMain: json['id_main'] == true,
    itStatus: (json['it_status'] as num? ?? 1).toInt(),
    idBlocked: json['id_blocked'] == true,
    vcBlockReason: json['vc_block_reason']?.toString(),
  );

  final int nrBranch;
  final String vcName;
  final String? vcLegalName;
  final String? vcCnpj;
  final String? vcCity;
  final String? vcState;
  final String? vcTimezone;
  final bool idMain;
  final int itStatus;
  final bool idBlocked;
  final String? vcBlockReason;

  bool get isActive => itStatus == 1 && !idBlocked;
}

/// Vinculo filial x perfil de um usuario (`company_user_list.users[].branches[]`).
class UserBranchProfile {
  const UserBranchProfile({
    required this.nrBranch,
    required this.vcBranch,
    required this.idMain,
    required this.nrProfile,
    required this.vcProfile,
    required this.itLevel,
  });

  factory UserBranchProfile.fromJson(Map<String, dynamic> json) =>
      UserBranchProfile(
        nrBranch: (json['nr_branch'] as num).toInt(),
        vcBranch: json['vc_branch']?.toString() ?? '',
        idMain: json['id_main'] == true,
        nrProfile: (json['nr_profile'] as num).toInt(),
        vcProfile: json['vc_profile']?.toString() ?? '',
        itLevel: (json['it_level'] as num? ?? 0).toInt(),
      );

  final int nrBranch;
  final String vcBranch;
  final bool idMain;
  final int nrProfile;
  final String vcProfile;
  final int itLevel;

  bool get isAdmin => itLevel >= 100;
}

/// Usuario vinculado a empresa (`ad.company_user_list`).
class CompanyUser {
  const CompanyUser({
    required this.nrUser,
    required this.nrCompanyUser,
    required this.vcName,
    required this.itStatus,
    required this.idAdmin,
    required this.branches,
    this.vcEmail,
    this.vcCpf,
    this.vcPhone,
    this.vcMobile,
    this.vcAvatarUrl,
    this.vcBlockReason,
    this.dhLastLogin,
    this.dhUpdated,
  });

  factory CompanyUser.fromJson(Map<String, dynamic> json) => CompanyUser(
    nrUser: (json['nr_user'] as num).toInt(),
    nrCompanyUser: (json['nr_company_user'] as num).toInt(),
    vcName: json['vc_name']?.toString() ?? '',
    vcEmail: json['vc_email']?.toString(),
    vcCpf: json['vc_cpf']?.toString(),
    vcPhone: json['vc_phone']?.toString(),
    vcMobile: json['vc_mobile']?.toString(),
    vcAvatarUrl: json['vc_avatar_url']?.toString(),
    itStatus: (json['it_status'] as num? ?? 1).toInt(),
    vcBlockReason: json['vc_block_reason']?.toString(),
    dhLastLogin: DateTime.tryParse(json['dh_last_login']?.toString() ?? ''),
    dhUpdated: DateTime.tryParse(json['dh_updated']?.toString() ?? ''),
    idAdmin: json['id_admin'] == true,
    branches: [
      for (final b in (json['branches'] as List? ?? const []))
        UserBranchProfile.fromJson((b as Map).cast<String, dynamic>()),
    ],
  );

  final int nrUser;
  final int nrCompanyUser;
  final String vcName;
  final String? vcEmail;
  final String? vcCpf;
  final String? vcPhone;
  final String? vcMobile;
  final String? vcAvatarUrl;

  /// 1 ativo · 80 bloqueado · 90 inativo (na empresa).
  final int itStatus;
  final String? vcBlockReason;
  final DateTime? dhLastLogin;
  final DateTime? dhUpdated;
  final bool idAdmin;
  final List<UserBranchProfile> branches;

  bool get isActive => itStatus == 1;
  bool get isBlocked => itStatus == 80;

  String get initials {
    final parts = vcName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

/// Pagina de `company_user_list`.
class CompanyUserPage {
  const CompanyUserPage({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.users,
  });

  factory CompanyUserPage.fromJson(Map<String, dynamic> json) =>
      CompanyUserPage(
        total: (json['qt_total'] as num? ?? 0).toInt(),
        page: (json['nr_page'] as num? ?? 1).toInt(),
        pageSize: (json['qt_page_size'] as num? ?? 50).toInt(),
        users: [
          for (final u in (json['users'] as List? ?? const []))
            CompanyUser.fromJson((u as Map).cast<String, dynamic>()),
        ],
      );

  final int total;
  final int page;
  final int pageSize;
  final List<CompanyUser> users;

  int get pageCount => total == 0 ? 1 : ((total - 1) ~/ pageSize) + 1;
  bool get hasPrevious => page > 1;
  bool get hasNext => page < pageCount;
}

/// Atribuicao filial -> perfil usada no formulario e no `company_user_save`.
class BranchAssignment {
  const BranchAssignment({required this.nrBranch, required this.nrProfile});

  final int nrBranch;
  final int nrProfile;

  Map<String, dynamic> toJson() => {
    'nr_branch': nrBranch,
    'nr_profile': nrProfile,
  };
}
