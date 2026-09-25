import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../scan/controllers/scan_controller.dart';
import '../../controllers/videos_controller.dart';
import '../../models/video_record.dart';
import '../../repositories/video_repository.dart';
import '../../widgets/video_library_state_panel.dart';
import '../../widgets/video_player_surface.dart';

class VideoViewerPage extends ConsumerStatefulWidget {
  const VideoViewerPage({required this.assetId, super.key});

  final String assetId;

  @override
  ConsumerState<VideoViewerPage> createState() => _VideoViewerPageState();
}

class _VideoViewerPageState extends ConsumerState<VideoViewerPage> {
  late Future<VideoDetails?> _details;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void didUpdateWidget(covariant VideoViewerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetId != widget.assetId) _loadDetails();
  }

  void _loadDetails() {
    _details = ref
        .read(videoRepositoryProvider)
        .details(widget.assetId)
        .then((value) => value, onError: (Object _) => null);
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanControllerProvider);
    final match = scanState.media.where(
      (record) => record.id == widget.assetId && record.video,
    );
    if (!scanState.hasResults || match.isEmpty || !scanState.canReadVideos) {
      return Scaffold(
        backgroundColor: const Color(0xFF1F1C27),
        body: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              const Expanded(
                child: VideoLibraryStatePanel(
                  title: 'This video is no longer available',
                  message:
                      'The library or its access changed. Return to Videos and scan again before reviewing it.',
                  dark: true,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final media = match.first;
    if (!media.largeVideo) {
      return Scaffold(
        backgroundColor: const Color(0xFF1F1C27),
        body: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              const Expanded(
                child: VideoLibraryStatePanel(
                  title: 'Video details changed',
                  message:
                      'This item is no longer in the large-video review list. Scan again to refresh the results.',
                  dark: true,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final video = VideoRecord.fromMedia(media);
    final feature = ref.watch(videosControllerProvider);
    final selected = feature.selectedIds.contains(video.id);
    final controller = ref.read(videosControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF1F1C27),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    VideoPlayerSurface(video: video),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TidySpacing.lg,
                        TidySpacing.md,
                        TidySpacing.lg,
                        TidySpacing.lg,
                      ),
                      child: FutureBuilder<VideoDetails?>(
                        future: _details,
                        builder: (context, snapshot) {
                          final details = snapshot.data;
                          final title = details?.fileName;
                          final fps = details?.frameRate;
                          final resolution = fps != null && fps > 0
                              ? '${video.resolutionLabel} · ${fps.round()} fps'
                              : video.resolutionLabel;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title == null || title.isEmpty
                                    ? 'Video'
                                    : title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: TidySpacing.md),
                              Row(
                                children: [
                                  _metadata(
                                    context,
                                    'Date',
                                    _date(context, video.createdAt),
                                  ),
                                  _metadata(context, 'Resolution', resolution),
                                  _metadata(
                                    context,
                                    'File size',
                                    video.sizeLabel,
                                  ),
                                ],
                              ),
                              const SizedBox(height: TidySpacing.md),
                              TidyActionButton(
                                label: 'Compress Video',
                                style: TidyActionStyle.secondary,
                                onPressed: () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Video compression is not available yet.',
                                        ),
                                      ),
                                    ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TidySpacing.lg,
                TidySpacing.sm,
                TidySpacing.lg,
                TidySpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TidyActionButton(
                      label: 'Keep',
                      style: TidyActionStyle.secondary,
                      onPressed: () {
                        if (selected) controller.toggle(video.id);
                        context.pop();
                      },
                    ),
                  ),
                  const SizedBox(width: TidySpacing.sm),
                  Expanded(
                    child: TidyActionButton(
                      label: selected ? 'Selected ✓' : 'Select for Cleanup',
                      onPressed: () => controller.toggle(video.id),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: TidySpacing.sm),
    child: Row(
      children: [
        TextButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          label: const Text('Back', style: TextStyle(color: Colors.white)),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Close video preview',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    ),
  );

  Widget _metadata(BuildContext context, String label, String value) =>
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: TidySpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: TidySpacing.xs),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );

  String _date(BuildContext context, DateTime? date) => date == null
      ? 'Unavailable'
      : MaterialLocalizations.of(context).formatMediumDate(date);
}
