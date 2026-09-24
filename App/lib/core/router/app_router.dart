import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/models/permission_subject.dart';
import '../../features/onboarding/presentation/pages/permission_handoff_page.dart';
import '../../features/onboarding/presentation/pages/permission_page.dart';
import '../../features/onboarding/presentation/pages/privacy_page.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/welcome_page.dart';
import '../widgets/section_placeholder_page.dart';
import '../widgets/tidy_navigation_shell.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    routes: <RouteBase>[
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding/welcome',
        pageBuilder: (context, state) =>
            CupertinoPage<void>(key: state.pageKey, child: const WelcomePage()),
      ),
      GoRoute(
        path: '/onboarding/privacy',
        pageBuilder: (context, state) =>
            CupertinoPage<void>(key: state.pageKey, child: const PrivacyPage()),
      ),
      for (final subject in PermissionSubject.values) ...<RouteBase>[
        GoRoute(
          path: '/onboarding/${subject.name}',
          pageBuilder: (context, state) => CupertinoPage<void>(
            key: state.pageKey,
            child: PermissionPage(subject: subject),
          ),
        ),
        GoRoute(
          path: '/onboarding/${subject.name}/preview',
          pageBuilder: (context, state) => CupertinoPage<void>(
            key: state.pageKey,
            child: PermissionHandoffPage(subject: subject),
          ),
        ),
      ],
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
