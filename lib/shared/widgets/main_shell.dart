import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon:          Icon(Icons.directions_run_outlined),
            selectedIcon:  Icon(Icons.directions_run),
            label:         'Training',
          ),
          NavigationDestination(
            icon:          Icon(Icons.healing_outlined),
            selectedIcon:  Icon(Icons.healing),
            label:         'Blessures',
          ),
        ],
      ),
    );
  }
}
