import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/app.dart';
import 'package:tidy/core/router/app_router.dart';
import 'package:tidy/features/scan/models/scan_state.dart';
import 'package:tidy/features/scan/controllers/scan_controller.dart';
import 'package:tidy/features/scan/repositories/scan_repository.dart';
import 'package:tidy/features/scan/services/library_scan_service.dart';
import 'package:tidy/features/videos/controllers/videos_controller.dart';
import 'package:tidy/features/videos/models/video_record.dart';
import 'package:tidy/features/videos/services/video_library_service.dart';

Map<String, Object?> _media(
  String id, {
  required int? bytes,
  bool video = true,
  int? createdAt,
}) => {
  'id': id,
  'video': video,
  'screenshot': false,
  'bytes': bytes,
  'width': 3840,
  'height': 2160,
  'duration': 60.0,
  'favorite': false,
  ...?(createdAt == null
      ? null
      : {'createdAt': createdAt, 'modifiedAt': createdAt}),
};

ScanState _scanState([Set<String> removed = const {}]) => ScanState(
  phase: ScanPhase.success,
  permissions: const {'photos': 'authorized', 'contacts': 'denied'},
  media: [
    MediaRecord.fromMap(_media('largest', bytes: 400000000, createdAt: 1000)),
    MediaRecord.fromMap(_media('newest', bytes: 200000000, createdAt: 3000)),
    MediaRecord.fromMap(_media('small', bytes: 30000000, createdAt: 2000)),
    MediaRecord.fromMap(
      _media('photo', bytes: 900000000, video: false, createdAt: 4000),
    ),
    MediaRecord.fromMap(_media('unknown', bytes: null, createdAt: 5000)),
  ].where((record) => !removed.contains(record.id)).toList(),
);

class _ScanRepository extends ScanRepository {
  _ScanRepository() : super(const LibraryScanService());
  final Set<String> removed = {};

  @override
  Future<void> start() async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<ScanState> read() async => _scanState(removed);

  @override
  Future<ScanState> applyDeleted(Set<String> ids) async {
    removed.addAll(ids);
    return read();
  }
}

class _VideoService extends VideoLibraryService {
  _VideoService();

  final List<Set<String>> deleteRequests = [];
  Object? deleteError;

  @override
  bool get supported => true;

  @override
  Future<VideoPreviewData> preview(String id) async =>
      VideoPreviewData(fileName: '$id.MOV');

  @override
  Future<VideoDetails> details(String id) async =>
      VideoDetails(fileName: '$id.MOV', frameRate: 30);

  @override
  Future<VideoDeletionOutcome> delete(List<VideoRecord> videos) async {
    deleteRequests.add(videos.map((video) => video.id).toSet());
    if (deleteError != null) throw deleteError!;
    final ids = videos.map((video) => video.id).toSet();
    return VideoDeletionOutcome(
      deletedIds: ids,
      remainingIds: const {},
      estimatedBytes: videos.fold<int>(0, (sum, video) => sum + video.bytes),
    );
  }
}

ProviderContainer _container(_VideoService service) => ProviderContainer(
  overrides: [
    scanRepositoryProvider.overrideWithValue(_ScanRepository()),
    videoLibraryServiceProvider.overrideWithValue(service),
  ],
);

Future<void> _loadScan(ProviderContainer container) async {
  container.read(videosControllerProvider);
  await container.read(scanControllerProvider.notifier).start();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'large-video scan results exclude other and unmeasured assets',
    () async {
      final container = _container(_VideoService());
      addTearDown(container.dispose);
      await _loadScan(container);

      final videos = container.read(largeVideosProvider);
      expect(videos.map((video) => video.id), ['largest', 'newest']);
      expect(videos.first.resolutionLabel, '4K');
      expect(videos.first.durationLabel, '1:00');
      expect(container.read(videosControllerProvider).selectedIds, isEmpty);
    },
  );

  test('all sort orders use real size and capture dates', () async {
    final container = _container(_VideoService());
    addTearDown(container.dispose);
    await _loadScan(container);
    final controller = container.read(videosControllerProvider.notifier);

    controller.setSortOrder(VideoSortOrder.newest);
    expect(container.read(largeVideosProvider).map((video) => video.id), [
      'newest',
      'largest',
    ]);
    controller.setSortOrder(VideoSortOrder.oldest);
    expect(container.read(largeVideosProvider).map((video) => video.id), [
      'largest',
      'newest',
    ]);
  });

  test(
    'explicit select-all and deselect-all only affect large videos',
    () async {
      final container = _container(_VideoService());
      addTearDown(container.dispose);
      await _loadScan(container);
      final controller = container.read(videosControllerProvider.notifier);
      final videos = container.read(largeVideosProvider);

      controller.toggleAll(videos);
      expect(container.read(videosControllerProvider).selectedIds, {
        'largest',
        'newest',
      });
      controller.toggleAll(videos);
      expect(container.read(videosControllerProvider).selectedIds, isEmpty);
    },
  );

  test('deletion scope is only the selected frozen review set', () async {
    final service = _VideoService();
    final container = _container(service);
    addTearDown(container.dispose);
    await _loadScan(container);
    final controller = container.read(videosControllerProvider.notifier);
    final videos = container.read(largeVideosProvider);
    controller.toggle(videos.first.id);

    final outcome = await controller.deleteSelected(videos);

    expect(service.deleteRequests, [
      <String>{'largest'},
    ]);
    expect(outcome?.deletedIds, {'largest'});
    expect(container.read(videosControllerProvider).selectedIds, isEmpty);
  });

  test(
    'failed deletion preserves reviewed selections for another review',
    () async {
      final service = _VideoService()
        ..deleteError = StateError('Photos failed');
      final container = _container(service);
      addTearDown(container.dispose);
      await _loadScan(container);
      final controller = container.read(videosControllerProvider.notifier);
      final videos = container.read(largeVideosProvider);
      controller.toggle(videos.first.id);

      final outcome = await controller.deleteSelected(videos);

      expect(outcome, isNull);
      expect(container.read(videosControllerProvider).selectedIds, {'largest'});
      expect(
        container.read(videosControllerProvider).error,
        contains('Photos failed'),
      );
    },
  );

  testWidgets(
    'video list selection, review cancellation and confirmed deletion',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final service = _VideoService();
      final container = _container(service);
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      router.go('/videos');
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const TidyApp()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Large Videos'), findsOneWidget);
      expect(find.text('videos'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('largest.MOV'), findsOneWidget);
      expect(find.text('small.MOV'), findsNothing);
      expect(find.text('0 selected'), findsOneWidget);

      await tester.tap(find.byTooltip('Select video for review').first);
      await tester.pump();
      expect(find.text('1 selected'), findsOneWidget);
      await tester.tap(find.text('Review Videos'));
      await tester.pumpAndSettle();
      expect(find.text('Review Videos'), findsNWidgets(2));
      await tester.tap(find.text('Continue to Confirmation'));
      await tester.pumpAndSettle();
      expect(find.text('Delete 1 videos?'), findsOneWidget);
      await tester.tap(find.text('Keep Videos'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);
      expect(service.deleteRequests, isEmpty);

      await tester.tap(find.text('Review Videos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to Confirmation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete from Photos'));
      await tester.pumpAndSettle();
      expect(service.deleteRequests.single, {'largest'});
      expect(find.text('1 video deleted.'), findsOneWidget);
      await container.read(scanControllerProvider.notifier).cancel();
    },
  );
}
