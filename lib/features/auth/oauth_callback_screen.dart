import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_provider.dart';

class OAuthCallbackScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const OAuthCallbackScreen({super.key, required this.sessionId});

  @override
  ConsumerState<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends ConsumerState<OAuthCallbackScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_exchange);
  }

  Future<void> _exchange() async {
    if (_started) return;
    _started = true;

    if (widget.sessionId.isEmpty) {
      if (mounted) context.go('/login');
      return;
    }
    if (ref.read(authProvider).token != null) {
      if (mounted) context.go('/plan');
      return;
    }
    final (ok, isNew) = await ref.read(authProvider.notifier).loginWithSession(widget.sessionId);
    if (!mounted) return;
    if (!ok) {
      context.go('/login');
    } else if (isNew) {
      context.go('/intake', extra: true);
    } else {
      context.go('/plan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(authProvider).error;

    return Scaffold(
      body: Center(
        child: error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Terug naar inloggen'),
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
