import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/features/photos/models/photo_group.dart';
import 'package:tidy/features/photos/presentation/pages/photo_collection_page.dart';
import 'package:tidy/features/photos/services/photo_library_service.dart';
import 'package:tidy/features/scan/controllers/scan_controller.dart';
import 'package:tidy/features/scan/models/scan_state.dart';

class _PresetScanController extends ScanController {
  _PresetScanController(this.result);

  final ScanState result;

  @override
  ScanState build() => result;
}

MediaRecord _blurryPhoto(String id) => MediaRecord.fromMap({
  'id': id,
  'video': false,
  'screenshot': false,
  'bytes': 1024,
  'width': 1200,
  'height': 800,
  'duration': 0,
  'favorite': false,
  'possiblyBlurry': true,
});

void main() {
  testWidgets('blurry collection renders the discovered photo thumbnails', (
    tester,
  ) async {
    final photos = [_blurryPhoto('blur-1'), _blurryPhoto('blur-2')];
    final scan = ScanState(
      phase: ScanPhase.success,
      media: photos,
      permissions: const {'photos': 'authorized'},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scanControllerProvider.overrideWith(
            () => _PresetScanController(scan),
          ),
          photoPermissionProvider.overrideWith((ref) async => 'authorized'),
          photoThumbnailProvider.overrideWith((ref, id) async => null),
        ],
        child: const MaterialApp(
          home: PhotoCollectionPage(kind: PhotoCollectionKind.blurry),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Possibly Blurry'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Possibly blurry photo, not selected'),
      findsNWidgets(2),
    );
  });
}
