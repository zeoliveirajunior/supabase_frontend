import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_gateway.dart';
import '../domain/access_profile.dart';

/// `ad.access_profile_list` (qualquer usuario da empresa),
/// `ad.access_profile_save` (somente administrador) e `ad.screen_list`.
class ProfileRepository {
  ProfileRepository(this._gateway);

  final SupabaseGateway _gateway;

  Future<List<AccessProfile>> list({
    required int nrCompany,
    bool includeInactive = true,
  }) async {
    final json = await _gateway.rpc('access_profile_list', {
      'nr_company': nrCompany,
      'id_include_inactive': includeInactive,
    });
    final items = json['profiles'];
    if (items is! List) return const [];
    return [
      for (final p in items)
        AccessProfile.fromJson((p as Map).cast<String, dynamic>()),
    ];
  }

  /// Catalogo de telas do app (global).
  Future<List<ScreenInfo>> screens() async {
    final json = await _gateway.rpc('screen_list');
    final items = json['screens'];
    if (items is! List) return const [];
    return [
      for (final s in items)
        ScreenInfo.fromJson((s as Map).cast<String, dynamic>()),
    ];
  }

  Future<int> create({
    required int nrCompany,
    int? nrBranch,
    required String vcName,
    required int itLevel,
    List<ProfileScreen>? screens,
  }) async {
    final json = await _gateway.rpc('access_profile_save', {
      'vc_action': 'I',
      'nr_company': nrCompany,
      if (nrBranch != null) 'nr_branch': nrBranch,
      'vc_name': vcName,
      'it_level': itLevel,
      if (screens != null) 'screens': [for (final s in screens) s.toJson()],
    });
    return (json['nr_profile'] as num).toInt();
  }

  /// Atualizacao parcial: so as chaves informadas mudam. `screens` presente
  /// substitui todas as permissoes por tela.
  Future<void> update({
    required int nrCompany,
    int? nrBranch,
    required int nrProfile,
    String? vcName,
    int? itLevel,
    int? itStatus,
    List<ProfileScreen>? screens,
  }) async {
    await _gateway.rpc('access_profile_save', {
      'vc_action': 'U',
      'nr_company': nrCompany,
      if (nrBranch != null) 'nr_branch': nrBranch,
      'nr_profile': nrProfile,
      if (vcName != null) 'vc_name': vcName,
      if (itLevel != null) 'it_level': itLevel,
      if (itStatus != null) 'it_status': itStatus,
      if (screens != null) 'screens': [for (final s in screens) s.toJson()],
    });
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseGatewayProvider)),
);
