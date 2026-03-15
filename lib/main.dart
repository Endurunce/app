import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'features/auth/auth_provider.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global platform error handler (async / isolate errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log(
      'PlatformError: $error',
      name: 'global',
      error: error,
      stackTrace: stack,
    );
    return true; // prevent crash, error is logged
  };

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('nl', 'NL'),
        Locale('en', 'US'),
      ],
      locale: const Locale('nl', 'NL'),
    );
  }
}
