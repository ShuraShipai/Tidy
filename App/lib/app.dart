import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/design/tidy_theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/tidy_navigation_bar.dart';

class TidyApp extends ConsumerWidget {
  const TidyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Tidy',
      debugShowCheckedModeBanner: false,
      theme: TidyTheme.light,
      routerConfig: router,
    );
  }
}

class TidyNavigationShell extends StatelessWidget {
  const TidyNavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: TidyNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
