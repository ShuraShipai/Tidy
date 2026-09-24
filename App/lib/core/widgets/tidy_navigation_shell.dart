import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'tidy_navigation_bar.dart';

class TidyNavigationShell extends StatelessWidget {
  const TidyNavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: TidyNavigationBar(
      currentIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
    ),
  );
}
