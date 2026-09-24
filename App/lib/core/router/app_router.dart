import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../widgets/section_placeholder_page.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TidyNavigationShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/photos',
                name: 'photos',
                builder: (context, state) =>
                    const SectionPlaceholderPage(title: 'Photos'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/videos',
                name: 'videos',
                builder: (context, state) =>
                    const SectionPlaceholderPage(title: 'Videos'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/contacts',
                name: 'contacts',
                builder: (context, state) =>
                    const SectionPlaceholderPage(title: 'Contacts'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) =>
                    const SectionPlaceholderPage(title: 'Settings'),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
