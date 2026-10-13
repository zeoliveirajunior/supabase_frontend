import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/logs/presentation/logs_page.dart';
import '../../features/profiles/presentation/profiles_page.dart';
import '../../features/session/application/session_controller.dart';
import '../../features/session/presentation/branch_selection_page.dart';
import '../../features/session/presentation/no_company_page.dart';
import '../../features/users/presentation/users_page.dart';
import '../../shared/widgets/splash_page.dart';

abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const selectBranch = '/selecionar-filial';
  static const noCompany = '/sem-empresa';
  static const dashboard = '/dashboard';
  static const users = '/usuarios';
  static const profiles = '/perfis';
  static const logs = '/logs';

  /// Rotas que nao fazem sentido com a sessao pronta.
  static const transient = {splash, login, selectBranch, noCompany};
}

/// Avisa o GoRouter sempre que o estado de sessao muda.
class _SessionListenable extends ChangeNotifier {
  _SessionListenable(Ref ref) {
    ref.listen<SessionState>(
      sessionControllerProvider,
      (_, __) => notifyListeners(),
    );
  }
}

/// Toda navegacao e decidida pelo estado da sessao: o usuario nunca ve uma
/// tela interna sem filial escolhida, nem o login com sessao valida.
final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _SessionListenable(ref);
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: listenable,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final location = state.matchedLocation;

      String? stay(String target) => location == target ? null : target;

      return switch (session.status) {
        SessionStatus.loading => stay(AppRoutes.splash),
        SessionStatus.signedOut => stay(AppRoutes.login),
        SessionStatus.noCompany => stay(AppRoutes.noCompany),
        SessionStatus.needsSelection => stay(AppRoutes.selectBranch),
        SessionStatus.ready =>
          AppRoutes.transient.contains(location) ? AppRoutes.dashboard : null,
      };
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
      GoRoute(
        path: AppRoutes.selectBranch,
        builder: (_, __) => const BranchSelectionPage(),
      ),
      GoRoute(
        path: AppRoutes.noCompany,
        builder: (_, __) => const NoCompanyPage(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (_, __) => const DashboardPage(),
      ),
      GoRoute(path: AppRoutes.users, builder: (_, __) => const UsersPage()),
      GoRoute(
        path: AppRoutes.profiles,
        builder: (_, __) => const ProfilesPage(),
      ),
      GoRoute(path: AppRoutes.logs, builder: (_, __) => const LogsPage()),
    ],
  );
});
