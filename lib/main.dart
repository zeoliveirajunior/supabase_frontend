import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'core/config/app_info.dart';
import 'core/supabase/supabase_gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // URLs sem # na web (/login em vez de /#/login); no-op nas outras plataformas.
  usePathUrlStrategy();
  await SupabaseGateway.initialize();
  final info = await PackageInfo.fromPlatform();

  runApp(
    ProviderScope(
      overrides: [
        appVersionProvider.overrideWithValue(
          '${info.version}+${info.buildNumber}',
        ),
      ],
      child: const App(),
    ),
  );
}
