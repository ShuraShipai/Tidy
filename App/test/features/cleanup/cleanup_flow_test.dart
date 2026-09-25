import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tidy/features/cleanup/controllers/cleanup_controller.dart';
import 'package:tidy/features/cleanup/models/cleanup_plan.dart';
import 'package:tidy/features/cleanup/presentation/pages/cleanup_progress_page.dart';
import 'package:tidy/features/cleanup/presentation/pages/cleanup_result_page.dart';
import 'package:tidy/features/cleanup/presentation/pages/cleanup_review_page.dart';
import 'package:tidy/features/contacts/controllers/contacts_controller.dart';
import 'package:tidy/features/photos/controllers/photo_selection_controller.dart';
import 'package:tidy/features/photos/services/photo_library_service.dart';
import 'package:tidy/features/scan/controllers/scan_controller.dart';
import 'package:tidy/features/scan/models/scan_state.dart';
import 'package:tidy/features/videos/controllers/videos_controller.dart';

Map<String, Object?> _photo(String id) => {
  'id': id,
  'video': false,
  'screenshot': false,
  'bytes': 1024,
  'width': 100,
  'height': 100,
  'duration': 0.0,
  'favorite': false,
};

ScanState _completedScan(Iterable<MediaRecord> media) => ScanState(
  phase: ScanPhase.success,
  permissions: const {'photos': 'authorized', 'contacts': 'denied'},
  completedAt: DateTime(2026, 1, 1),
  media: media.toList(),
  similar: [
    MatchGroup(const {'photo-1', 'photo-2'}, 'device scan match'),
  ],
);

class _TestScanController extends ScanController {
  @override
  ScanState build() => _completedScan([
    MediaRecord.fromMap(_photo('photo-1')),
    MediaRecord.fromMap(_photo('photo-2')),
  ]);

  @override
  Future<void> applyDeleted(Set<String> ids) async {
    state = _completedScan(state.media.where((item) => !ids.contains(item.id)));
  }
}

class _TestContactsController extends ContactsController {
  @override
  Future<ContactsState> build() async => const ContactsState(status: 'denied');
}

class _SelectedPhotoController extends PhotoSelectionController {
  @override
  PhotoSelectionState build() =>
      PhotoSelectionState(selectedIds: const {'photo-2'});
}

class _PhotoService extends PhotoLibraryService {
  final requests = <Set<String>>[];

  @override
  bool get supported => true;

  @override
  Future<PhotoDeletionOutcome> delete(Set<String> identifiers) async {
    requests.add(Set.of(identifiers));
    return PhotoDeletionOutcome(
      succeeded: true,
      deletedIds: Set.of(identifiers),
      remainingIds: const {},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'cleanup uses explicit selection and counts only confirmed removals',
    () async {
      final photoService = _PhotoService();
      final container = ProviderContainer(
        overrides: [
          scanControllerProvider.overrideWith(_TestScanController.new),
          contactsControllerProvider.overrideWith(_TestContactsController.new),
          photoLibraryServiceProvider.overrideWithValue(photoService),
        ],
      );
      addTearDown(container.dispose);

      container.read(videosControllerProvider);
      container.read(contactsControllerProvider);
      container
          .read(photoSelectionControllerProvider.notifier)
          .toggle('photo-2');
      final reviewed = container.read(cleanupPlanProvider);

      expect(reviewed.itemCount, 1);
      expect(reviewed.entries.single.id, 'photo-2');
      final result = await container
          .read(cleanupControllerProvider.notifier)
          .execute(reviewed);

      expect(photoService.requests, [
        <String>{'photo-2'},
      ]);
      expect(result?.deletedEntries.map((item) => item.id), ['photo-2']);
      expect(result?.remainingEntries, isEmpty);
      expect(
        container.read(photoSelectionControllerProvider).selectedIds,
        isEmpty,
      );
      expect(
        container.read(scanControllerProvider).media.map((item) => item.id),
        ['photo-1'],
      );
    },
  );

  testWidgets('review requires confirmation before the result flow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final photoService = _PhotoService();
    final router = GoRouter(
      initialLocation: '/cleanup/review',
      routes: [
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
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scanControllerProvider.overrideWith(_TestScanController.new),
          contactsControllerProvider.overrideWith(_TestContactsController.new),
          photoSelectionControllerProvider.overrideWith(
            _SelectedPhotoController.new,
          ),
          photoLibraryServiceProvider.overrideWithValue(photoService),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Ready to clean'), findsOneWidget);
    await tester.tap(find.text('Clean 1 Items').first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Clean selected items?'), findsOneWidget);
    expect(photoService.requests, isEmpty);

    await tester.dragFrom(const Offset(195, 700), const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('Clean 1 Items').last);
    await tester.tap(find.text('Clean 1 Items').last);
    for (var frame = 0; frame < 8; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(photoService.requests, [
      <String>{'photo-2'},
    ]);
    expect(find.text('Cleanup complete'), findsOneWidget);
    expect(
      find.textContaining('1 selected item was confirmed removed.'),
      findsOneWidget,
    );
  });
}
