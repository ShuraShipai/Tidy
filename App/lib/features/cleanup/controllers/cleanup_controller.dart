import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../contacts/controllers/contacts_controller.dart';
import '../../contacts/models/contact_record.dart';
import '../../photos/controllers/photo_selection_controller.dart';
import '../../photos/services/photo_library_service.dart';
import '../../scan/controllers/scan_controller.dart';
import '../../scan/models/scan_state.dart';
import '../../videos/controllers/videos_controller.dart';
import '../../videos/models/video_record.dart';
import '../../videos/repositories/video_repository.dart';
import '../models/cleanup_plan.dart';

enum CleanupPhase { idle, cleaning, complete, partial, failed }

class CleanupResult {
  const CleanupResult({
    required this.requestedCount,
    required this.deletedEntries,
    required this.remainingEntries,
    required this.knownBytesDeleted,
  });

  final int requestedCount;
  final List<CleanupEntry> deletedEntries;
  final List<CleanupEntry> remainingEntries;
  final int knownBytesDeleted;

  bool get isComplete => remainingEntries.isEmpty && deletedEntries.isNotEmpty;
}

class CleanupState {
  const CleanupState({
    this.phase = CleanupPhase.idle,
    this.message,
    this.result,
    this.error,
  });

  final CleanupPhase phase;
  final String? message;
  final CleanupResult? result;
  final String? error;
}

final cleanupPlanProvider = Provider<CleanupPlan>((ref) {
  final scan = ref.watch(scanControllerProvider);
  final photoSelection = ref.watch(photoSelectionControllerProvider);
  final videoState = ref.watch(videosControllerProvider);
  final videos = ref.watch(largeVideosProvider);
  final contactsAsync = ref.watch(contactsControllerProvider);
  final selectedPhotos = photoSelection.selectedIds;
  final selectedVideos = videoState.selectedIds;
  final contactState = contactsAsync.asData?.value;
  final entries = <CleanupEntry>[];
  final seen = <String>{};
  final similarPhotoIds = {for (final group in scan.similar) ...group.ids};

  for (final photo in scan.media) {
    if (photo.video ||
        !selectedPhotos.contains(photo.id) ||
        !seen.add(photo.id)) {
      continue;
    }
    final category = photo.screenshot
        ? CleanupCategory.screenshots
        : photo.possiblyBlurry == true
        ? CleanupCategory.possiblyBlurry
        : similarPhotoIds.contains(photo.id)
        ? CleanupCategory.similarPhotos
        : CleanupCategory.selectedPhotos;
    entries.add(
      CleanupEntry(
        id: photo.id,
        category: category,
        title: category.label,
        detail: photo.bytes == null ? 'Size unavailable' : _size(photo.bytes!),
        media: photo,
      ),
    );
  }
  final mediaById = {for (final item in scan.media) item.id: item};
  for (final video in videos) {
    if (!selectedVideos.contains(video.id) || !seen.add(video.id)) continue;
    final media = mediaById[video.id];
    if (media == null) continue;
    entries.add(
      CleanupEntry(
        id: video.id,
        category: CleanupCategory.largeVideos,
        title: 'Video',
        detail: video.sizeLabel,
        media: media,
      ),
    );
  }
  for (final contact in contactState?.contacts ?? const <ContactRecord>[]) {
    if (!contactState!.selected.contains(contact.id)) continue;
    entries.add(
      CleanupEntry(
        id: contact.id,
        category: CleanupCategory.duplicateContacts,
        title: contact.name,
        detail: [...contact.phones, ...contact.emails].join(' · '),
        contact: contact,
      ),
    );
  }
  return CleanupPlan(entries: entries);
});

final cleanupControllerProvider =
    NotifierProvider<CleanupController, CleanupState>(CleanupController.new);

class CleanupController extends Notifier<CleanupState> {
  bool _running = false;

  @override
  CleanupState build() => const CleanupState();

  Future<CleanupResult?> execute(CleanupPlan reviewed) async {
    if (_running || reviewed.isEmpty) return null;
    final scan = ref.read(scanControllerProvider);
    if (!scan.hasResults) {
      state = const CleanupState(
        phase: CleanupPhase.failed,
        error:
            'The completed scan is no longer available. Return Home and scan again.',
      );
      return null;
    }
    _running = true;
    final deleted = <CleanupEntry>[];
    final remaining = <CleanupEntry>[];
    var deletedBytes = 0;
    state = const CleanupState(
      phase: CleanupPhase.cleaning,
      message: 'Checking the reviewed selection…',
    );
    try {
      final currentMedia = {for (final media in scan.media) media.id: media};
      final currentPhotoSelection = ref
          .read(photoSelectionControllerProvider)
          .selectedIds;
      final currentVideoSelection = ref
          .read(videosControllerProvider)
          .selectedIds;

      final photoEntries = reviewed.entries
          .where(
            (entry) =>
                entry.category == CleanupCategory.similarPhotos ||
                entry.category == CleanupCategory.screenshots ||
                entry.category == CleanupCategory.possiblyBlurry ||
                entry.category == CleanupCategory.selectedPhotos,
          )
          .toList(growable: false);
      final videoEntries = reviewed.forCategory(CleanupCategory.largeVideos);
      final contactEntries = reviewed.forCategory(
        CleanupCategory.duplicateContacts,
      );

      if (photoEntries.isNotEmpty) {
        state = const CleanupState(
          phase: CleanupPhase.cleaning,
          message: 'Reviewing photo access…',
        );
        final ids = photoEntries.map((entry) => entry.id).toSet();
        final valid =
            scan.canReadPhotos &&
            ids.every(
              (id) =>
                  currentPhotoSelection.contains(id) &&
                  currentMedia[id] != null &&
                  !currentMedia[id]!.video,
            );
        if (!valid) {
          remaining.addAll(photoEntries);
        } else {
          try {
            final outcome = await ref
                .read(photoLibraryServiceProvider)
                .delete(ids);
            final verified = outcome.deletedIds.intersection(ids);
            for (final entry in photoEntries) {
              if (verified.contains(entry.id)) {
                deleted.add(entry);
                deletedBytes += entry.media?.bytes ?? 0;
              } else {
                remaining.add(entry);
              }
            }
          } catch (_) {
            remaining.addAll(photoEntries);
          }
          final verifiedIds = deleted
              .where(
                (entry) => photoEntries.any((photo) => photo.id == entry.id),
              )
              .map((entry) => entry.id)
              .toSet();
          if (verifiedIds.isNotEmpty) {
            ref
                .read(photoSelectionControllerProvider.notifier)
                .removeDeleted(verifiedIds);
            try {
              await ref
                  .read(scanControllerProvider.notifier)
                  .applyDeleted(verifiedIds);
            } catch (_) {}
          }
        }
      }

      if (videoEntries.isNotEmpty) {
        state = const CleanupState(
          phase: CleanupPhase.cleaning,
          message: 'Reviewing video access…',
        );
        final ids = videoEntries.map((entry) => entry.id).toSet();
        final videoRecords = <VideoRecord>[];
        for (final entry in videoEntries) {
          final media = currentMedia[entry.id];
          if (media == null ||
              !media.video ||
              !media.largeVideo ||
              !currentVideoSelection.contains(entry.id)) {
            continue;
          }
          videoRecords.add(VideoRecord.fromMedia(media));
        }
        if (!scan.canReadVideos || videoRecords.length != ids.length) {
          remaining.addAll(videoEntries);
        } else {
          try {
            final outcome = await ref
                .read(videoRepositoryProvider)
                .delete(videoRecords);
            final verified = outcome.deletedIds.intersection(ids);
            for (final entry in videoEntries) {
              if (verified.contains(entry.id)) {
                deleted.add(entry);
                deletedBytes += entry.media?.bytes ?? 0;
              } else {
                remaining.add(entry);
              }
            }
          } catch (_) {
            remaining.addAll(videoEntries);
          }
          final verifiedIds = deleted
              .where(
                (entry) => videoEntries.any((video) => video.id == entry.id),
              )
              .map((entry) => entry.id)
              .toSet();
          if (verifiedIds.isNotEmpty) {
            try {
              await ref
                  .read(scanControllerProvider.notifier)
                  .applyDeleted(verifiedIds);
            } catch (_) {}
          }
        }
      }

      if (contactEntries.isNotEmpty) {
        state = const CleanupState(
          phase: CleanupPhase.cleaning,
          message: 'Reviewing Contacts access…',
        );
        final ids = contactEntries.map((entry) => entry.id).toSet();
        final contacts = ref.read(contactsRepositoryProvider);
        final selectedContactIds =
            ref.read(contactsControllerProvider).asData?.value.selected ??
            const <String>{};
        try {
          final (access, currentContacts) = await contacts.read(ids);
          final currentById = {
            for (final contact in currentContacts) contact.id: contact,
          };
          final fixed = <ContactRecord>[];
          var canDelete = access == 'authorized' || access == 'limited';
          for (final entry in contactEntries) {
            final selected = selectedContactIds.contains(entry.id);
            final current = currentById[entry.id];
            if (!selected ||
                current == null ||
                current.version != entry.contact?.version) {
              canDelete = false;
            } else {
              fixed.add(current);
            }
          }
          if (!canDelete || fixed.length != ids.length) {
            remaining.addAll(contactEntries);
          } else {
            var deleteCallCompleted = false;
            try {
              await contacts.delete(fixed);
              deleteCallCompleted = true;
            } catch (_) {
              // A native delete can partially succeed; verify the fixed IDs below.
            }
            final (verifyAccess, after) = await contacts.read(ids);
            final afterIds = after.map((contact) => contact.id).toSet();
            for (final entry in contactEntries) {
              final accessStillMatches = access == verifyAccess;
              final accessCanVerify =
                  verifyAccess == 'authorized' ||
                  (verifyAccess == 'limited' && deleteCallCompleted);
              if (accessStillMatches &&
                  accessCanVerify &&
                  !afterIds.contains(entry.id)) {
                deleted.add(entry);
              } else {
                remaining.add(entry);
              }
            }
            try {
              await ref.read(contactsControllerProvider.notifier).refresh();
              await ref.read(scanControllerProvider.notifier).refresh();
            } catch (_) {}
          }
        } catch (_) {
          remaining.addAll(contactEntries);
        }
      }

      final result = CleanupResult(
        requestedCount: reviewed.itemCount,
        deletedEntries: List.unmodifiable(deleted),
        remainingEntries: List.unmodifiable(remaining),
        knownBytesDeleted: deletedBytes,
      );
      final phase = result.isComplete
          ? CleanupPhase.complete
          : deleted.isEmpty
          ? CleanupPhase.failed
          : CleanupPhase.partial;
      state = CleanupState(
        phase: phase,
        result: result,
        error: phase == CleanupPhase.failed
            ? 'No selected items were confirmed removed. Your selection remains available for review.'
            : null,
      );
      return result;
    } finally {
      _running = false;
    }
  }
}

extension CleanupScanAccess on ScanState {
  bool get canReadPhotos =>
      ['authorized', 'limited'].contains(permissions['photos']);
}

String _size(int bytes) => bytes >= 1000000000
    ? '${(bytes / 1000000000).toStringAsFixed(1)} GB'
    : bytes >= 1000000
    ? '${(bytes / 1000000).round()} MB'
    : '${(bytes / 1000).round()} KB';
