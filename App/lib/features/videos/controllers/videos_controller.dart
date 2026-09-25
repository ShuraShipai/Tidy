import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../scan/controllers/scan_controller.dart';
import '../../scan/models/scan_state.dart' as scan;
import '../models/video_record.dart';
import '../repositories/video_repository.dart';

class VideosState {
  const VideosState({
    this.sortOrder = VideoSortOrder.largest,
    this.selectedIds = const {},
    this.deleting = false,
    this.deletionOutcome,
    this.error,
  });

  final VideoSortOrder sortOrder;
  final Set<String> selectedIds;
  final bool deleting;
  final VideoDeletionOutcome? deletionOutcome;
  final String? error;

  VideosState copyWith({
    VideoSortOrder? sortOrder,
    Set<String>? selectedIds,
    bool? deleting,
    VideoDeletionOutcome? deletionOutcome,
    bool clearDeletionOutcome = false,
    String? error,
    bool clearError = false,
  }) => VideosState(
    sortOrder: sortOrder ?? this.sortOrder,
    selectedIds: selectedIds ?? this.selectedIds,
    deleting: deleting ?? this.deleting,
    deletionOutcome: clearDeletionOutcome
        ? null
        : deletionOutcome ?? this.deletionOutcome,
    error: clearError ? null : error ?? this.error,
  );
}

class VideosController extends Notifier<VideosState> {
  @override
  VideosState build() {
    ref.listen(scanControllerProvider, (previous, next) {
      final access = next.permissions['photos'];
      if (access != null && !['authorized', 'limited'].contains(access)) {
        state = state.copyWith(
          selectedIds: const {},
          clearDeletionOutcome: true,
        );
      } else if (next.hasResults) {
        final eligible = {
          for (final record in next.media)
            if (record.video && record.largeVideo) record.id,
        };
        state = state.copyWith(
          selectedIds: state.selectedIds.intersection(eligible),
        );
      }
    });
    return const VideosState();
  }

  void setSortOrder(VideoSortOrder value) {
    if (state.deleting || state.sortOrder == value) return;
    state = state.copyWith(sortOrder: value, clearError: true);
  }

  void toggle(String id) {
    if (state.deleting) return;
    if (!_eligibleIds().contains(id)) return;
    final updated = Set<String>.of(state.selectedIds);
    if (!updated.add(id)) updated.remove(id);
    state = state.copyWith(
      selectedIds: Set.unmodifiable(updated),
      clearDeletionOutcome: true,
      clearError: true,
    );
  }

  void toggleAll(Iterable<VideoRecord> videos) {
    if (state.deleting) return;
    final ids = videos
        .map((video) => video.id)
        .toSet()
        .intersection(_eligibleIds());
    final updated = Set<String>.of(state.selectedIds);
    if (ids.isNotEmpty && ids.every(updated.contains)) {
      updated.removeAll(ids);
    } else {
      updated.addAll(ids);
    }
    state = state.copyWith(
      selectedIds: Set.unmodifiable(updated),
      clearDeletionOutcome: true,
      clearError: true,
    );
  }

  void clearSelection() {
    if (state.deleting) return;
    state = state.copyWith(
      selectedIds: const {},
      clearDeletionOutcome: true,
      clearError: true,
    );
  }

  Future<VideoDeletionOutcome?> deleteSelected(
    Iterable<VideoRecord> availableVideos,
  ) async {
    if (state.deleting) return null;
    final scanState = ref.read(scanControllerProvider);
    if (!scanState.hasResults || !scanState.canReadVideos) {
      state = state.copyWith(
        error: 'Video access or scan results changed. Scan and review again.',
      );
      return null;
    }
    final eligible = _eligibleIds();
    final selected = availableVideos
        .where(
          (video) =>
              state.selectedIds.contains(video.id) &&
              eligible.contains(video.id),
        )
        .toList(growable: false);
    if (selected.isEmpty) return null;

    state = state.copyWith(
      deleting: true,
      clearError: true,
      clearDeletionOutcome: true,
    );
    try {
      final outcome = await ref.read(videoRepositoryProvider).delete(selected);
      if (!ref.mounted) return outcome;
      await ref
          .read(scanControllerProvider.notifier)
          .applyDeleted(outcome.deletedIds);
      if (!ref.mounted) return outcome;
      state = state.copyWith(
        deleting: false,
        selectedIds: Set.unmodifiable(
          state.selectedIds.difference(outcome.deletedIds),
        ),
        deletionOutcome: outcome,
      );
      return outcome;
    } catch (error) {
      if (!ref.mounted) return null;
      final message = error is PlatformException
          ? (error.message ?? 'Photos could not complete this deletion.')
          : error.toString();
      state = state.copyWith(deleting: false, error: message);
      return null;
    }
  }

  Set<String> _eligibleIds() {
    final scanState = ref.read(scanControllerProvider);
    if (!scanState.hasResults || !scanState.canReadVideos) return const {};
    return {
      for (final record in scanState.media)
        if (record.video && record.largeVideo) record.id,
    };
  }
}

final videosControllerProvider =
    NotifierProvider<VideosController, VideosState>(VideosController.new);

final largeVideosProvider = Provider<List<VideoRecord>>((ref) {
  final scan = ref.watch(scanControllerProvider);
  final state = ref.watch(videosControllerProvider);
  return ref.watch(videoRepositoryProvider).sorted(scan, state.sortOrder);
});

extension VideoAccessStatus on scan.ScanState {
  bool get canReadVideos =>
      ['authorized', 'limited'].contains(permissions['photos']);

  bool get isLimitedVideosAccess => permissions['photos'] == 'limited';
}
