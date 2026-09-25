import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/features/bonus/presentation/pages/video_compression_page.dart';
import 'package:tidy/features/bonus/services/group_eight_service.dart';
import 'package:tidy/features/scan/controllers/scan_controller.dart';
import 'package:tidy/features/scan/models/scan_state.dart';
import 'package:tidy/features/bonus/presentation/widgets/video_compression_preview.dart';

void main() {
  for (final (label, ratio) in <(String, double)>[
    ('portrait', 9 / 16),
    ('landscape', 16 / 9),
    ('square', 1),
  ]) {
    testWidgets('$label preview stays compact and keeps its aspect ratio', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 345,
                child: Row(
                  children: [
                    VideoCompressionPreview(
                      aspectRatio: ratio,
                      preview: Future.value(null),
                      onPlay: () {},
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(AspectRatio));
      expect(size.height, lessThanOrEqualTo(84));
      expect(size.width / size.height, closeTo(ratio, 0.01));
    });
  }

  testWidgets('tapping the preview requests full-screen playback', (
    tester,
  ) async {
    var plays = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: VideoCompressionPreview(
              aspectRatio: 9 / 16,
              preview: Future.value(null),
              onPlay: () => plays++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final preview = find.byType(VideoCompressionPreview);
    await tester.ensureVisible(preview);
    await tester.tap(preview);

    expect(plays, 1);
  });

  testWidgets(
    'compression controls remain below preview and survive playback',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = _PreviewService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scanControllerProvider.overrideWith(_VideoScanController.new),
            groupEightServiceProvider.overrideWithValue(service),
          ],
          child: const MaterialApp(
            home: VideoCompressionPage(assetId: 'on-device-video'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Compression'), findsOneWidget);
      expect(find.text('Smaller'), findsOneWidget);
      expect(find.text('Balanced'), findsOneWidget);
      final preview = find.byType(VideoCompressionPreview);
      final previewBottom = tester.getRect(preview).bottom;
      final compressionTop = tester.getTopLeft(find.text('Compression')).dy;
      expect(compressionTop, greaterThan(previewBottom));
      expect(compressionTop, lessThan(600));
      await tester.tap(find.text('Smaller'));
      await tester.pumpAndSettle();
      final smallerCard = find
          .ancestor(of: find.text('Smaller'), matching: find.byType(Card))
          .first;
      expect(
        (tester.widget<Card>(smallerCard).shape as RoundedRectangleBorder)
            .side
            .width,
        2,
      );
      await tester.ensureVisible(preview);
      await tester.tap(preview);
      await tester.pumpAndSettle();

      expect(service.playedAssetId, 'on-device-video');
      expect(find.text('Compression'), findsOneWidget);
      expect(find.text('Smaller'), findsOneWidget);
      expect(
        (tester.widget<Card>(smallerCard).shape as RoundedRectangleBorder)
            .side
            .width,
        2,
      );
    },
  );
}

class _VideoScanController extends ScanController {
  @override
  ScanState build() => ScanState(
    phase: ScanPhase.success,
    media: [
      MediaRecord.fromMap({
        'id': 'on-device-video',
        'video': true,
        'screenshot': false,
        'bytes': 50000000,
        'width': 1080,
        'height': 1920,
        'duration': 42.0,
        'favorite': false,
      }),
    ],
  );
}

class _PreviewService extends GroupEightService {
  String? playedAssetId;

  @override
  Future<Uint8List?> compressionThumbnail({
    String? assetId,
    String? path,
  }) async => null;

  @override
  Future<void> playCompressionPreview({String? assetId, String? path}) async {
    playedAssetId = assetId;
  }
}
