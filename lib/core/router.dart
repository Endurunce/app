import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/plan/week_detail_screen.dart';
import '../features/injury/injury_screen.dart';
import '../features/coach/coach_screen.dart';
import '../features/strava/strava_screen.dart';
import '../features/tips/tips_screen.dart';
import '../features/profile/intake_screen.dart';
import '../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/plan',
    redirect: (context, state) {
      final loggedIn = authState.token != null;
      final loc = state.matchedLocation;
      final onAuth = loc.startsWith('/login') || loc.startsWith('/register');

      if (loc == '/') return loggedIn ? '/plan' : '/login';
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) return '/plan';
      return null;
    },
    routes: [
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/intake',   builder: (_, __) => const IntakeScreen()),

      // Main shell with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
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
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/injuries',
              builder: (_, __) => const InjuryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/coach',
              builder: (_, __) => const CoachScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/strava',
              builder: (_, __) => const StravaScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tips',
              builder: (_, __) => const TipsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});
