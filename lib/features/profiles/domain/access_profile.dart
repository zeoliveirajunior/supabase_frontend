/// Perfil de acesso da empresa (`ad.access_profile`), como devolvido por
/// `ad.access_profile_list`.
class AccessProfile {
  const AccessProfile({
    required this.nrProfile,
    required this.vcName,
    required this.itLevel,
    required this.itStatus,
    required this.qtUsers,
    this.dhUpdated,
  });

  factory AccessProfile.fromJson(Map<String, dynamic> json) => AccessProfile(
    nrProfile: (json['nr_profile'] as num).toInt(),
    vcName: json['vc_name']?.toString() ?? '',
    itLevel: (json['it_level'] as num? ?? 0).toInt(),
    itStatus: (json['it_status'] as num? ?? 1).toInt(),
    qtUsers: (json['qt_users'] as num? ?? 0).toInt(),
    dhUpdated: DateTime.tryParse(json['dh_updated']?.toString() ?? ''),
  );

  final int nrProfile;
  final String vcName;

  /// 0..100; 100 = administrador da empresa.
  final int itLevel;

  /// 1 ativo · 90 inativo.
  final int itStatus;
  final int qtUsers;
  final DateTime? dhUpdated;

  bool get isAdmin => itLevel >= 100;
  bool get isActive => itStatus == 1;

  AccessProfile copyWith({String? vcName, int? itLevel, int? itStatus}) =>
      AccessProfile(
        nrProfile: nrProfile,
        vcName: vcName ?? this.vcName,
        itLevel: itLevel ?? this.itLevel,
        itStatus: itStatus ?? this.itStatus,
        qtUsers: qtUsers,
        dhUpdated: dhUpdated,
      );
}

/// Situacao de perfil, filial e empresa: 1 ativo · 90 inativo.
abstract final class SimpleStatus {
  static const int active = 1;
  static const int inactive = 90;
}

/// Situacao de usuario (plataforma e empresa): 1 ativo · 80 bloqueado · 90 inativo.
abstract final class UserStatus {
  static const int active = 1;
  static const int blocked = 80;
  static const int inactive = 90;
}
