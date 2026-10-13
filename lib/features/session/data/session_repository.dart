import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_info.dart';
import '../../../core/supabase/supabase_gateway.dart';
import '../domain/session_context.dart';
import 'selection_store.dart';

/// Chama `ad.session_context`. E o "login no app" depois do Supabase Auth:
/// valida o usuario no banco, devolve empresas/filiais/perfis e grava o log.
class SessionRepository {
  SessionRepository(this._gateway, this._appVersion);

  final SupabaseGateway _gateway;
  final String _appVersion;

  Future<SessionContext> loadContext({SelectedBranchIds? selected}) async {
    final json = await _gateway.rpc('session_context', {
      'it_app': AppConfig.itApp,
      'vc_device': AppConfig.deviceName,
      'vc_app_version': _appVersion,
      if (selected != null) 'nr_company': selected.nrCompany,
      if (selected != null) 'nr_branch': selected.nrBranch,
    });
    return SessionContext.fromJson(json);
  }
}

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(
    ref.watch(supabaseGatewayProvider),
    ref.watch(appVersionProvider),
  ),
);
