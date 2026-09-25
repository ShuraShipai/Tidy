import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_colors.dart';
import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../../scan/controllers/scan_controller.dart';
import '../../../scan/models/scan_state.dart' as scan;
import '../../controllers/videos_controller.dart';
import '../../models/video_record.dart';
import '../../widgets/video_card.dart';
import '../../widgets/video_library_state_panel.dart';
import '../../widgets/video_selection_bar.dart';
import '../../widgets/video_sort_control.dart';
import '../../widgets/video_review_sheet.dart';
import '../../widgets/video_delete_confirmation.dart';

class VideosPage extends ConsumerStatefulWidget {
  const VideosPage({super.key});

  @override
  ConsumerState<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends ConsumerState<VideosPage> {
  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanControllerProvider);
    final videos = ref.watch(largeVideosProvider);
    final featureState = ref.watch(videosControllerProvider);
    final controller = ref.read(videosControllerProvider.notifier);
    final selected = videos
        .where((video) => featureState.selectedIds.contains(video.id))
        .toList(growable: false);
    final selectedBytes = selected.fold<int>(
      0,
      (sum, video) => sum + video.bytes,
    );

    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        TidySpacing.lg,
                        TidySpacing.pageTop,
                        TidySpacing.lg,
                        TidySpacing.lg,
                      ),
                      sliver: SliverList.list(
                        children: [
                          Text(
                            'Large Videos',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: TidySpacing.xs),
                          Text(
                            'A few big files. A lot more room.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: TidyColors.secondaryText),
                          ),
                          const SizedBox(height: TidySpacing.md),
                          _summary(context, videos),
                          const SizedBox(height: TidySpacing.md),
                          if (_isBusy(scanState))
                            VideoLibraryStatePanel(
                              title: 'Scanning your library',
                              message:
                                  scanState.processed != null &&
                                      scanState.total != null
                                  ? '${scanState.processed} of ${scanState.total} accessible items checked. Videos will appear when the scan completes.'
                                  : 'Checking accessible Photos and video items on this iPhone.',
                              actionLabel: 'Cancel Scan',
                              onAction: () => ref
                                  .read(scanControllerProvider.notifier)
                                  .cancel(),
                              loading: true,
                            )
                          else if (!scanState.hasResults &&
                              (scanState.phase == scan.ScanPhase.error ||
                                  scanState.phase == scan.ScanPhase.stale ||
                                  scanState.phase == scan.ScanPhase.cancelled))
                            VideoLibraryStatePanel(
                              title: scanState.phase == scan.ScanPhase.stale
                                  ? 'Your video list needs a refresh'
                                  : 'Videos could not be scanned',
                              message:
                                  scanState.message ??
                                  'Scan the current accessible library before reviewing videos.',
                              actionLabel: 'Scan Again',
                              onAction: () => ref
                                  .read(scanControllerProvider.notifier)
                                  .start(),
                            )
                          else if (!scanState.canReadVideos)
                            VideoLibraryStatePanel(
                              title: 'Video access is off',
                              message:
                                  'Allow Photos access to review videos. With limited access, only the videos you selected in iOS are available here.',
                              actionLabel: 'Manage Photo Access',
                              onAction: () =>
                                  context.push('/onboarding/photos'),
                            )
                          else if (!scanState.hasResults)
                            const VideoLibraryStatePanel(
                              title: 'Video scan is not ready',
                              message:
                                  'Wait for the current library scan to finish, then review the videos it found.',
                              loading: true,
                            )
                          else ...[
                            if (scanState.isLimitedVideosAccess)
                              _notice(
                                'Limited Photos access · only the videos selected in iOS are included.',
                                TidyColors.noteBackground,
                              ),
                            if (_unknownVideoCount(scanState) > 0)
                              _notice(
                                '${_unknownVideoCount(scanState)} video sizes could not be read locally. They are not classified as large or selectable.',
                                TidyColors.noteBackground,
                              ),
                            if (featureState.deletionOutcome != null)
                              _deletionMessage(
                                context,
                                featureState.deletionOutcome!,
                              ),
                            if (featureState.error != null)
                              _notice(
                                featureState.error!,
                                const Color(0xFFFFE9E8),
                              ),
                            VideoSortControl(
                              value: featureState.sortOrder,
                              onChanged: controller.setSortOrder,
                            ),
                            if (videos.isNotEmpty)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => controller.toggleAll(videos),
                                  child: Text(
                                    _allSelected(
                                          videos,
                                          featureState.selectedIds,
                                        )
                                        ? 'Deselect All'
                                        : 'Select All',
                                  ),
                                ),
                              ),
                            if (videos.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: TidySpacing.xl,
                                ),
                                child: VideoLibraryStatePanel(
                                  title: 'No large videos found',
                                  message: _unknownVideoCount(scanState) == 0
                                      ? 'There are no accessible videos with a readable primary resource of 100 MiB or more.'
                                      : 'No large videos could be verified among the readable files. Some video sizes are unavailable.',
                                  actionLabel: 'Scan Again',
                                  onAction: () => ref
                                      .read(scanControllerProvider.notifier)
                                      .start(),
                                ),
                              )
                            else
                              for (final video in videos)
                                VideoCard(
                                  key: ValueKey(video.id),
                                  video: video,
                                  selected: featureState.selectedIds.contains(
                                    video.id,
                                  ),
                                  onOpen: () => _openVideo(video),
                                  onToggle: () => controller.toggle(video.id),
                                ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (scanState.hasResults && scanState.canReadVideos)
                VideoSelectionBar(
                  count: selected.length,
                  knownBytes: selectedBytes,
                  onReview: () => _review(selected),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summary(BuildContext context, List<VideoRecord> videos) {
    final bytes = videos.fold<int>(0, (sum, video) => sum + video.bytes);
    return Row(
      children: [
        Text(
          '${videos.length}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(width: TidySpacing.xs),
        Text('videos', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: TidySpacing.md),
        const SizedBox(height: 24, child: VerticalDivider(width: 1)),
        const SizedBox(width: TidySpacing.md),
        Text(_size(bytes), style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _notice(String message, Color color) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: TidySpacing.sm),
    padding: const EdgeInsets.all(TidySpacing.sm),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(message, style: const TextStyle(color: TidyColors.primaryText)),
  );

  Widget _deletionMessage(BuildContext context, VideoDeletionOutcome outcome) {
    final removed = outcome.deletedIds.length;
    final remaining = outcome.remainingIds.length;
    final text = removed == 0
        ? 'Photos did not verify that any selected videos were deleted. They remain available to review.'
        : remaining == 0
        ? '$removed videos were deleted from Photos. Recently Deleted may retain them for a while.'
        : '$removed videos were deleted; $remaining remain available to review.';
    return Padding(
      padding: const EdgeInsets.only(bottom: TidySpacing.md),
      child: _notice(text, const Color(0xFFE8F8F1)),
    );
  }

  Future<void> _openVideo(VideoRecord video) async {
    final location = Uri(
      path: '/videos/viewer',
      queryParameters: {'id': video.id},
    ).toString();
    await context.push<void>(location);
  }

  Future<void> _review(List<VideoRecord> initiallySelected) async {
    final controller = ref.read(videosControllerProvider.notifier);
    final reviewed = await showModalBottomSheet<List<VideoRecord>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: TidyColors.surface,
      builder: (context) => VideoReviewSheet(
        videos: initiallySelected,
        onRemoveFromSelection: controller.toggle,
      ),
    );
    if (!mounted || reviewed == null || reviewed.isEmpty) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoDeleteConfirmation(videos: reviewed),
    );
    if (!mounted || confirmed != true) return;
    final outcome = await controller.deleteSelected(reviewed);
    if (!mounted) return;
    if (outcome == null) {
      final error = ref.read(videosControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Photos could not verify deletion.')),
      );
    } else {
      final deleted = outcome.deletedIds.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deleted == 0
                ? 'No video deletions were verified.'
                : '$deleted ${deleted == 1 ? 'video' : 'videos'} deleted.',
          ),
        ),
      );
    }
  }

  bool _isBusy(scan.ScanState value) =>
      value.phase == scan.ScanPhase.loading ||
      value.phase == scan.ScanPhase.scanning;

  int _unknownVideoCount(scan.ScanState value) =>
      value.media.where((item) => item.video && item.bytes == null).length;

  bool _allSelected(List<VideoRecord> videos, Set<String> selected) =>
      videos.isNotEmpty && videos.every((video) => selected.contains(video.id));

  String _size(int bytes) => bytes >= 1000000000
      ? '${(bytes / 1000000000).toStringAsFixed(1)} GB'
      : '${(bytes / 1000000).round()} MB';
}
