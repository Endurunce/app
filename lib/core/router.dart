import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/plan/week_detail_screen.dart';
import '../features/injury/injury_screen.dart';
import '../features/profile/intake_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = authState.token != null;
      final onAuth = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register');

      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) return '/plan';
      return null;
    },
    routes: [
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/intake',   builder: (_, __) => const IntakeScreen()),
      GoRoute(
        path: '/plan',
        builder: (_, __) => const PlanScreen(),
        routes: [
          GoRoute(
            path: 'week/:weekNumber',
            builder: (_, state) => WeekDetailScreen(
              weekNumber: int.parse(state.pathParameters['weekNumber']!),
            ),
          ),
        ],
      ),
      GoRoute(path: '/injuries', builder: (_, __) => const InjuryScreen()),
    ],
  );
});
