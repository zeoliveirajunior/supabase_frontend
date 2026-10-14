/// Permissao de um perfil numa tela (`access_profile_list.profiles[].screens[]`).
class ProfileScreen {
  const ProfileScreen({
    required this.uuScreen,
    required this.vcCode,
    required this.vcName,
    required this.idRead,
    required this.idCreate,
    required this.idUpdate,
  });

  factory ProfileScreen.fromJson(Map<String, dynamic> json) => ProfileScreen(
    uuScreen: json['uu_screen']?.toString() ?? '',
    vcCode: json['vc_code']?.toString() ?? '',
    vcName: json['vc_name']?.toString() ?? '',
    idRead: json['id_read'] != false,
    idCreate: json['id_create'] == true,
    idUpdate: json['id_update'] == true,
  );

  final String uuScreen;
  final String vcCode;
  final String vcName;
  final bool idRead;
  final bool idCreate;
  final bool idUpdate;

  /// Formato enviado em `access_profile_save.screens[]`.
  Map<String, dynamic> toJson() => {
    'uu_screen': uuScreen,
    'id_read': idRead,
    'id_create': idCreate,
    'id_update': idUpdate,
  };
}

/// Perfil de acesso da empresa (`ad.access_profile`), como devolvido por
/// `ad.access_profile_list`.
class AccessProfile {
  const AccessProfile({
    required this.nrProfile,
    required this.vcName,
    required this.itLevel,
    required this.itStatus,
    required this.qtUsers,
    this.screens = const [],
    this.dhUpdated,
  });

  factory AccessProfile.fromJson(Map<String, dynamic> json) => AccessProfile(
    nrProfile: (json['nr_profile'] as num).toInt(),
    vcName: json['vc_name']?.toString() ?? '',
    itLevel: (json['it_level'] as num? ?? 0).toInt(),
    itStatus: (json['it_status'] as num? ?? 1).toInt(),
    qtUsers: (json['qt_users'] as num? ?? 0).toInt(),
    screens: [
      for (final s in (json['screens'] as List? ?? const []))
        ProfileScreen.fromJson((s as Map).cast<String, dynamic>()),
    ],
    dhUpdated: DateTime.tryParse(json['dh_updated']?.toString() ?? ''),
  );

  final int nrProfile;
  final String vcName;

  /// 0..100; 100 = administrador da empresa (todas as telas).
  final int itLevel;

  /// 1 ativo · 90 inativo.
  final int itStatus;
  final int qtUsers;

  /// Telas liberadas (vazio para administrador: tem tudo).
  final List<ProfileScreen> screens;
  final DateTime? dhUpdated;

  bool get isAdmin => itLevel >= 100;
  bool get isActive => itStatus == 1;

  ProfileScreen? screen(String uuScreen) {
    for (final s in screens) {
      if (s.uuScreen == uuScreen) return s;
    }
    return null;
  }

  AccessProfile copyWith({String? vcName, int? itLevel, int? itStatus}) =>
      AccessProfile(
        nrProfile: nrProfile,
        vcName: vcName ?? this.vcName,
        itLevel: itLevel ?? this.itLevel,
        itStatus: itStatus ?? this.itStatus,
        qtUsers: qtUsers,
        screens: screens,
        dhUpdated: dhUpdated,
      );
}

/// Tela do catalogo (`ad.screen_list`).
class ScreenInfo {
  const ScreenInfo({
    required this.uuScreen,
    required this.vcCode,
    required this.vcName,
    required this.nrOrder,
    this.vcGroup,
  });

  factory ScreenInfo.fromJson(Map<String, dynamic> json) => ScreenInfo(
    uuScreen: json['uu_screen']?.toString() ?? '',
    vcCode: json['vc_code']?.toString() ?? '',
    vcName: json['vc_name']?.toString() ?? '',
    vcGroup: json['vc_group']?.toString(),
    nrOrder: (json['nr_order'] as num? ?? 0).toInt(),
  );

  final String uuScreen;
  final String vcCode;
  final String vcName;
  final String? vcGroup;
  final int nrOrder;
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
