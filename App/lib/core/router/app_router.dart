import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/pages/home_page.dart';
import '../../features/cleanup/presentation/pages/cleanup_review_page.dart';
import '../../features/cleanup/presentation/pages/cleanup_progress_page.dart';
import '../../features/cleanup/presentation/pages/cleanup_result_page.dart';
import '../../features/cleanup/presentation/pages/cleanup_remaining_page.dart';
import '../../features/cleanup/models/cleanup_plan.dart';
import '../../features/settings/presentation/pages/settings_home_page.dart';
import '../../features/settings/presentation/pages/settings_permissions_page.dart';
import '../../features/settings/presentation/pages/scan_preferences_page.dart';
import '../../features/settings/presentation/pages/photo_sensitivity_page.dart';
import '../../features/settings/presentation/pages/privacy_information_page.dart';
import '../../features/settings/presentation/pages/how_cleaning_works_page.dart';
import '../../features/settings/presentation/pages/about_tidy_page.dart';
import '../../features/onboarding/models/permission_subject.dart';
import '../../features/onboarding/presentation/pages/permission_page.dart';
import '../../features/onboarding/presentation/pages/permission_handoff_page.dart';
import '../../features/onboarding/presentation/pages/privacy_page.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/welcome_page.dart';
import '../../features/scan/presentation/pages/scan_page.dart';
import '../../features/scan/presentation/pages/scan_interrupted_page.dart';
import '../../features/videos/presentation/pages/videos_page.dart';
import '../../features/videos/presentation/pages/video_viewer_page.dart';
import '../../features/contacts/presentation/pages/contacts_page.dart';
import '../../features/bonus/presentation/pages/bonus_tools_page.dart';
import '../../features/bonus/presentation/pages/calendar_cleanup_page.dart';
import '../../features/bonus/presentation/pages/cleanup_history_page.dart';
import '../../features/bonus/presentation/pages/private_vault_page.dart';
import '../../features/bonus/presentation/pages/vault_add_page.dart';
import '../../features/bonus/presentation/pages/video_compression_page.dart';
import '../../features/bonus/presentation/pages/widget_setup_page.dart';
import '../../features/photos/models/photo_group.dart';
import '../../features/photos/presentation/pages/photo_collection_page.dart';
import '../../features/photos/presentation/pages/photo_comparison_page.dart';
import '../../features/photos/presentation/pages/photo_selection_review_page.dart';
import '../../features/photos/presentation/pages/photo_swipe_page.dart';
import '../../features/photos/presentation/pages/photo_viewer_page.dart';
import '../../features/photos/presentation/pages/photos_overview_page.dart';
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
          path: '/onboarding/${subject.name}/request',
          pageBuilder: (context, state) => CupertinoPage<void>(
            key: state.pageKey,
            child: PermissionHandoffPage(subject: subject),
          ),
        ),
      ],
      GoRoute(
        path: '/scan',
        name: 'scan',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: ScanPage(
            autoStart: state.uri.queryParameters['start'] == 'true',
          ),
        ),
      ),
      GoRoute(
        path: '/scan/interrupted',
        builder: (context, state) => const ScanInterruptedPage(),
      ),
      GoRoute(
        path: '/cleanup/review',
        builder: (context, state) => const CleanupReviewPage(),
      ),
      GoRoute(
        path: '/cleanup/progress',
        builder: (context, state) =>
            CleanupProgressPage(reviewedPlan: state.extra as CleanupPlan?),
      ),
      GoRoute(
        path: '/cleanup/result',
        builder: (context, state) => const CleanupResultPage(),
      ),
      GoRoute(
        path: '/cleanup/remaining',
        builder: (context, state) => const CleanupRemainingPage(),
      ),
      GoRoute(
        path: '/settings/permissions',
        builder: (context, state) => const SettingsPermissionsPage(),
      ),
      GoRoute(
        path: '/settings/preferences',
        builder: (context, state) => const ScanPreferencesPage(),
      ),
      GoRoute(
        path: '/settings/sensitivity',
        builder: (context, state) => const PhotoSensitivityPage(),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) => const PrivacyInformationPage(),
      ),
      GoRoute(
        path: '/settings/how',
        builder: (context, state) => const HowCleaningWorksPage(),
      ),
      GoRoute(
        path: '/settings/about',
        builder: (context, state) => const AboutTidyPage(),
      ),
      GoRoute(
        path: '/videos/viewer',
        name: 'video-viewer',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: VideoViewerPage(
            assetId: state.uri.queryParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/bonus/tools',
        name: 'bonus-tools',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const BonusToolsPage(),
        ),
      ),
      GoRoute(
        path: '/bonus/compression',
        name: 'video-compression',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: VideoCompressionPage(
            assetId: state.uri.queryParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/bonus/vault',
        name: 'private-vault',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const PrivateVaultPage(),
        ),
      ),
      GoRoute(
        path: '/bonus/vault/add',
        name: 'vault-add',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const VaultAddPage(),
        ),
      ),
      GoRoute(
        path: '/bonus/calendar',
        name: 'calendar-cleanup',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const CalendarCleanupPage(),
        ),
      ),
      GoRoute(
        path: '/bonus/widgets',
        name: 'storage-widgets',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const WidgetSetupPage(),
        ),
      ),
      GoRoute(
        path: '/bonus/history',
        name: 'cleanup-history',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const CleanupHistoryPage(),
        ),
      ),
      GoRoute(
        path: '/photos/similar',
        name: 'photo-similar',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const PhotoCollectionPage(kind: PhotoCollectionKind.similar),
        ),
      ),
      GoRoute(
        path: '/photos/screenshots',
        name: 'photo-screenshots',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const PhotoCollectionPage(
            kind: PhotoCollectionKind.screenshots,
          ),
        ),
      ),
      GoRoute(
        path: '/photos/blurry',
        name: 'photo-blurry',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const PhotoCollectionPage(kind: PhotoCollectionKind.blurry),
        ),
      ),
      GoRoute(
        path: '/photos/similar/group',
        name: 'photo-comparison',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: PhotoComparisonPage(
            anchorId: state.uri.queryParameters['photo'] ?? '',
            exactDuplicateOnly:
                state.uri.queryParameters['kind'] == 'exactDuplicate',
          ),
        ),
      ),
      GoRoute(
        path: '/photos/viewer',
        name: 'photo-viewer',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: PhotoViewerPage(
            assetId: state.uri.queryParameters['id'] ?? '',
            collection: state.uri.queryParameters['collection'] ?? 'similar',
          ),
        ),
      ),
      GoRoute(
        path: '/photos/review',
        name: 'photo-review',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const PhotoSelectionReviewPage(),
        ),
      ),
      GoRoute(
        path: '/photos/swipe',
        name: 'photo-swipe',
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const PhotoSwipePage(),
        ),
      ),
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
                builder: (context, state) => const PhotosOverviewPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/videos',
                name: 'videos',
                builder: (context, state) => const VideosPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/contacts',
                name: 'contacts',
                builder: (context, state) => const ContactsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsHomePage(),
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
