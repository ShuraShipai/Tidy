import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/features/photos/controllers/photo_selection_controller.dart';
import 'package:tidy/features/photos/models/photo_group.dart';
import 'package:tidy/features/scan/models/scan_state.dart';

MediaRecord _photo(String id, int pixels) => MediaRecord.fromMap({
  'id': id,
  'video': false,
  'screenshot': false,
  'bytes': 100,
  'contentHash': id,
  'width': pixels,
  'height': pixels,
  'duration': 0,
  'favorite': false,
});

void main() {
  test('discovered photos start unselected', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(photoSelectionControllerProvider).selectedIds,
      isEmpty,
    );
  });

  test(
    'select all except best uses measured resolution and preserves other picks',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(
        photoSelectionControllerProvider.notifier,
      );
      final group = PhotoGroup(
        items: [
          _photo('lower', 1200),
          _photo('higher', 2400),
          _photo('middle', 1800),
        ],
        kind: PhotoGroupKind.similar,
      );

      controller.toggle('another-group-photo');
      controller.toggle('higher');
      controller.selectAllExceptBest(group);

      expect(container.read(photoSelectionControllerProvider).selectedIds, {
        'another-group-photo',
        'lower',
        'middle',
      });
      expect(
        container.read(photoSelectionControllerProvider).keeperFor(group),
        'higher',
      );
    },
  );

  test('permission reconciliation removes inaccessible photos only', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      photoSelectionControllerProvider.notifier,
    );
    controller.select(['accessible', 'unavailable'], selected: true);

    controller.reconcile({'accessible'});

    expect(container.read(photoSelectionControllerProvider).selectedIds, {
      'accessible',
    });
  });
}
