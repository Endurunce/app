import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/plan/plan_screen.dart';
import '../features/plan/week_detail_screen.dart';
import '../features/injury/injury_screen.dart';
import '../features/coach/coach_screen.dart';
import '../features/tips/tips_screen.dart';
import '../features/profile/intake_screen.dart';
import '../features/profile/profile_screen.dart';
import '../shared/widgets/main_shell.dart';

// Shared transition builders
CustomTransitionPage<T> _slidePage<T>(BuildContext ctx, GoRouterState state, Widget child) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(
          begin: const Offset(1.0, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: offset, child: child),
        );
      },
    );

CustomTransitionPage<T> _fadePage<T>(BuildContext ctx, GoRouterState state, Widget child) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );

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
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, state) => _fadePage(ctx, state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (ctx, state) => _fadePage(ctx, state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/intake',
        pageBuilder: (ctx, state) => _slidePage(ctx, state, const IntakeScreen()),
      ),

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
                  pageBuilder: (ctx, state) => _slidePage(
                    ctx, state,
                    WeekDetailScreen(
                      weekNumber: int.parse(state.pathParameters['weekNumber']!),
                    ),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/injuries', builder: (_, __) => const InjuryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/coach', builder: (_, __) => const CoachScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/tips', builder: (_, __) => const TipsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
