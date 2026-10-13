import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_gateway.dart';
import '../../session/application/session_controller.dart';

/// Login com e-mail e senha: Supabase Auth e, em seguida, `session_context`.
/// O estado assincrono alimenta o botao (loading) e o snackbar de erro.
class LoginController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(supabaseGatewayProvider)
          .signInWithPassword(email: email.trim(), password: password);
      await ref.read(sessionControllerProvider.notifier).afterSignIn();
    });
    state = result;
    return !result.hasError;
  }
}

final loginControllerProvider = AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);
