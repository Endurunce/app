import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api_client.dart';
import 'core/router.dart';
import 'features/auth/auth_provider.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On web: check if we're returning from Google OAuth (token in URL hash)
  if (kIsWeb) {
    final uri = Uri.base;
    final fragment = uri.fragment; // e.g. "token=xxx&is_admin=false&email=..."
    if (fragment.contains('token=')) {
      final params = Uri.splitQueryString(fragment);
      final token = params['token'];
      if (token != null) {
        await saveToken(token);
        // Clean up URL
        // ignore: undefined_prefixed_name
        // We can't easily manipulate history here without dart:html, router will handle navigation
      }
    }
  }

  runApp(const ProviderScope(child: EnduranceApp()));
}

class EnduranceApp extends ConsumerStatefulWidget {
  const EnduranceApp({super.key});

  @override
  ConsumerState<EnduranceApp> createState() => _EnduranceAppState();
}

class _EnduranceAppState extends ConsumerState<EnduranceApp> {
  @override
  void initState() {
    super.initState();
    // Restore JWT token from secure storage on startup
    Future.microtask(() => ref.read(authProvider.notifier).init());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Endurance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: router,
    );
  }
}
