import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Versao do app (`1.2.3+45`), lida do pacote em `main.dart` e injetada aqui.
/// Vai no `vc_app_version` do `session_context`.
final appVersionProvider = Provider<String>((ref) => '0.0.0+0');
