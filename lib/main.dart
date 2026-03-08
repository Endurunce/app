import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api_client.dart';
import 'core/router.dart';
import 'features/auth/auth_provider.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On web: check if we're returning from Strava/Google OAuth (token in URL hash)
  String? webDisplayName;
  if (kIsWeb) {
    final uri = Uri.base;
    final fragment = uri.fragment; // e.g. "token=xxx&is_admin=false&email=...&display_name=..."
    if (fragment.contains('token=')) {
      final params = Uri.splitQueryString(fragment);
      final token = params['token'];
      if (token != null) {
        await saveToken(token);
      }
      webDisplayName = params['display_name'];
    }
  }

  runApp(ProviderScope(child: EnduranceApp(webDisplayName: webDisplayName)));
}

class EnduranceApp extends ConsumerStatefulWidget {
  final String? webDisplayName;
  const EnduranceApp({super.key, this.webDisplayName});

  @override
  ConsumerState<EnduranceApp> createState() => _EnduranceAppState();
}

class _EnduranceAppState extends ConsumerState<EnduranceApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(authProvider.notifier).init();
      // Pas display_name toe vanuit web OAuth hash (Strava/Google)
      if (widget.webDisplayName != null && widget.webDisplayName!.isNotEmpty) {
        ref.read(authProvider.notifier).applyWebAuthHash(widget.webDisplayName!);
      }
    });
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
