import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_snapshot.dart';
import '../models/scan_state.dart' as data;
import 'scan_controller.dart';

/// Presentation projection only. Findings remain distinct from user selections.
final scanSnapshotProvider = Provider<ScanSnapshot>((ref) {
  final state = ref.watch(scanControllerProvider);
  CategoryFinding finding(Iterable<data.MediaRecord> items) {
    final list = items.toList();
    return CategoryFinding(
      count: list.length,
      estimatedBytes: list.fold<int>(0, (sum, x) => sum + (x.bytes ?? 0)),
      unknownSizeCount: list.where((x) => x.bytes == null).length,
    );
  }

  final similarIds = {for (final group in state.similar) ...group.ids};
  bool access(String key) =>
      ['authorized', 'limited'].contains(state.permissions[key]);
  return ScanSnapshot(
    phase: state.running
        ? ScanPhase.scanning
        : state.hasResults
        ? ScanPhase.complete
        : state.phase == data.ScanPhase.permissionDenied
        ? ScanPhase.noAccess
        : [
            data.ScanPhase.error,
            data.ScanPhase.stale,
            data.ScanPhase.cancelled,
          ].contains(state.phase)
        ? ScanPhase.failed
        : ScanPhase.notScanned,
    // Contacts enumeration has no reliable precomputed total. Never invent one.
    progress:
        state.stage == 'media' &&
            state.total != null &&
            state.total! > 0 &&
            state.processed != null
        ? state.processed! / state.total!
        : null,
    currentCategory: state.stage == 'contacts'
        ? CleanupCategory.duplicateContacts
        : null,
    currentStage: state.stage,
    storage: state.capacity == null || state.free == null
        ? null
        : DeviceStorage(
            capacityBytes: state.capacity!,
            availableBytes: state.free!,
          ),
    lastScanned: state.completedAt,
    reviewableBytes: state.hasResults ? state.knownReviewableBytes : null,
    unknownReviewableSizes: state.unknownReviewableSizes,
    findings: !state.hasResults
        ? const {}
        : {
            if (access('photos')) ...{
              CleanupCategory.similarPhotos: finding(
                state.media.where((x) => similarIds.contains(x.id)),
              ),
              CleanupCategory.screenshots: finding(
                state.media.where((x) => x.screenshot),
              ),
              CleanupCategory.largeVideos: finding(
                state.media.where((x) => x.largeVideo),
              ),
            },
            if (access('contacts'))
              CleanupCategory.duplicateContacts: CategoryFinding(
                count: state.contacts.length,
              ),
          },
  );
});
