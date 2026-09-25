import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scan/controllers/scan_controller.dart';
import '../../scan/models/scan_state.dart';
import '../models/photo_group.dart';

class PhotoSelectionState {
  PhotoSelectionState({
    Set<String> selectedIds = const {},
    Map<String, String> keepers = const {},
  }) : selectedIds = Set.unmodifiable(selectedIds),
       keepers = Map.unmodifiable(keepers);

  final Set<String> selectedIds;
  final Map<String, String> keepers;

  String keeperFor(PhotoGroup group) =>
      keepers[group.selectionKey] ?? group.suggestedKeeper.id;
}

class PhotoSelectionController extends Notifier<PhotoSelectionState> {
  @override
  PhotoSelectionState build() => PhotoSelectionState();

  void toggle(String id) {
    final selected = {...state.selectedIds};
    if (!selected.add(id)) selected.remove(id);
    state = PhotoSelectionState(selectedIds: selected, keepers: state.keepers);
  }

  void select(Iterable<String> ids, {required bool selected}) {
    final next = {...state.selectedIds};
    if (selected) {
      next.addAll(ids);
    } else {
      next.removeAll(ids);
    }
    state = PhotoSelectionState(selectedIds: next, keepers: state.keepers);
  }

  void selectAllExceptBest(PhotoGroup group) {
    final keeperId = state.keeperFor(group);
    final next = {...state.selectedIds}
      ..addAll(group.items.map((item) => item.id))
      ..remove(keeperId);
    state = PhotoSelectionState(selectedIds: next, keepers: state.keepers);
  }

  void setKeeper(PhotoGroup group, String id) {
    if (!group.items.any((item) => item.id == id)) return;
    final keepers = {...state.keepers, group.selectionKey: id};
    state = PhotoSelectionState(
      selectedIds: state.selectedIds,
      keepers: keepers,
    );
  }

  void reconcile(Set<String> accessiblePhotoIds) {
    final next = state.selectedIds.intersection(accessiblePhotoIds);
    if (next.length != state.selectedIds.length) {
      state = PhotoSelectionState(selectedIds: next, keepers: state.keepers);
    }
  }

  void removeDeleted(Set<String> deletedIds) {
    if (deletedIds.isEmpty) return;
    final next = state.selectedIds.difference(deletedIds);
    state = PhotoSelectionState(selectedIds: next, keepers: state.keepers);
  }
}

final photoSelectionControllerProvider =
    NotifierProvider<PhotoSelectionController, PhotoSelectionState>(
      PhotoSelectionController.new,
    );

final selectedPhotoTotalsProvider = Provider<SelectedPhotoTotals>((ref) {
  final selection = ref.watch(photoSelectionControllerProvider);
  final scan = ref.watch(scanControllerProvider);
  final records = {
    for (final photo in scan.media)
      if (!photo.video && selection.selectedIds.contains(photo.id))
        photo.id: photo,
  };
  final knownBytes = records.values.fold<int>(
    0,
    (sum, photo) => sum + (photo.bytes ?? 0),
  );
  final unknownSizes = records.values
      .where((photo) => photo.bytes == null)
      .length;
  return SelectedPhotoTotals(
    count: records.length,
    knownBytes: knownBytes,
    unknownSizes: unknownSizes,
    selectedIds: Set.unmodifiable(records.keys),
    photos: List.unmodifiable(records.values),
  );
});

class SelectedPhotoTotals {
  const SelectedPhotoTotals({
    required this.count,
    required this.knownBytes,
    required this.unknownSizes,
    required this.selectedIds,
    required this.photos,
  });

  final int count;
  final int knownBytes;
  final int unknownSizes;
  final Set<String> selectedIds;
  final List<MediaRecord> photos;
}
