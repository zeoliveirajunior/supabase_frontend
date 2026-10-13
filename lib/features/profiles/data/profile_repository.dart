import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_gateway.dart';
import '../domain/access_profile.dart';

/// `ad.access_profile_list` (qualquer usuario da empresa) e
/// `ad.access_profile_save` (somente administrador).
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

  Future<int> create({
    required int nrCompany,
    required String vcName,
    required int itLevel,
  }) async {
    final json = await _gateway.rpc('access_profile_save', {
      'vc_action': 'I',
      'nr_company': nrCompany,
      'vc_name': vcName,
      'it_level': itLevel,
    });
    return (json['nr_profile'] as num).toInt();
  }

  /// Atualizacao parcial: so as chaves informadas mudam.
  Future<void> update({
    required int nrCompany,
    required int nrProfile,
    String? vcName,
    int? itLevel,
    int? itStatus,
  }) async {
    await _gateway.rpc('access_profile_save', {
      'vc_action': 'U',
      'nr_company': nrCompany,
      'nr_profile': nrProfile,
      if (vcName != null) 'vc_name': vcName,
      if (itLevel != null) 'it_level': itLevel,
      if (itStatus != null) 'it_status': itStatus,
    });
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseGatewayProvider)),
);
