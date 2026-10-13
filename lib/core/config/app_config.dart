import 'package:flutter/foundation.dart';

/// Configuracao do app, resolvida em tempo de compilacao com `--dart-define`.
///
/// Os valores default apontam para o projeto Supabase de HOMOLOGACAO, para que
/// `flutter run` funcione sem configuracao. A chave publicavel e publica por
/// natureza (vai dentro do app); toda a seguranca esta na RLS e nas functions.
/// O CI passa os valores de cada environment (staging / production).
abstract final class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wnmuzwohzerlmtlqfezw.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_bUGbEWxJyY1VmlHtlOj-SQ_s_fjMHyp',
  );

  /// dev | staging | production
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static bool get isProduction => environment == 'production';

  /// `nr_version` enviado em toda RPC. Sobe junto com `fn_check_version` no banco.
  static const int contractVersion = 1;

  /// `it_app` do `session_context`: 1 web | 2 android | 3 ios | 9 outro.
  static int get itApp {
    if (kIsWeb) return 1;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 2,
      TargetPlatform.iOS => 3,
      _ => 9,
    };
  }

  static String get deviceName {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
