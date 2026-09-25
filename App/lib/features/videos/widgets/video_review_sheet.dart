import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';
import '../models/video_record.dart';
import '../repositories/video_repository.dart';

class VideoReviewSheet extends ConsumerStatefulWidget {
  const VideoReviewSheet({
    required this.videos,
    required this.onRemoveFromSelection,
    super.key,
  });

  final List<VideoRecord> videos;
  final ValueChanged<String> onRemoveFromSelection;

  @override
  ConsumerState<VideoReviewSheet> createState() => _VideoReviewSheetState();
}

class _VideoReviewSheetState extends ConsumerState<VideoReviewSheet> {
  late List<VideoRecord> _videos;
  late Map<String, Future<VideoPreviewData?>> _previews;

  @override
  void initState() {
    super.initState();
    _videos = List.of(widget.videos);
    _previews = {
      for (final video in _videos)
        video.id: ref
            .read(videoRepositoryProvider)
            .preview(video.id)
            .then((value) => value, onError: (Object _) => null),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _videos.fold<int>(0, (sum, video) => sum + video.bytes);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TidySpacing.lg,
          TidySpacing.lg,
          TidySpacing.lg,
          TidySpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Videos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: TidySpacing.xs),
            Text(
              '${_videos.length} selected · ${_size(bytes)} primary resource bytes',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: TidyColors.secondaryText),
            ),
            const SizedBox(height: TidySpacing.sm),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _videos.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final video = _videos[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: FutureBuilder<VideoPreviewData?>(
                      future: _previews[video.id],
                      builder: (context, snapshot) {
                        final name = snapshot.data?.fileName;
                        return Text(
                          name == null || name.isEmpty
                              ? _title(context, video)
                              : name,
                        );
                      },
                    ),
                    subtitle: Text(
                      '${video.sizeLabel} · ${video.durationLabel}',
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove from selection',
                      onPressed: () {
                        widget.onRemoveFromSelection(video.id);
                        setState(() {
                          _videos.removeWhere((item) => item.id == video.id);
                        });
                      },
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: TidyColors.secondaryText,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: TidySpacing.sm),
            Text(
              'These are file-size estimates for one readable PhotoKit resource per video. iOS may keep deleted items in Recently Deleted; freed space can differ.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: TidyColors.secondaryText),
            ),
            const SizedBox(height: TidySpacing.md),
            TidyActionButton(
              label: 'Continue to Confirmation',
              style: TidyActionStyle.secondary,
              onPressed: _videos.isEmpty
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pop(List<VideoRecord>.unmodifiable(_videos)),
            ),
            const SizedBox(height: TidySpacing.xs),
            TidyActionButton(
              label: 'Cancel',
              style: TidyActionStyle.quiet,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }

  String _title(BuildContext context, VideoRecord video) {
    final date = video.createdAt;
    return date == null
        ? 'Video · ${video.resolutionLabel}'
        : 'Video · ${MaterialLocalizations.of(context).formatShortDate(date)}';
  }

  String _size(int bytes) => bytes >= 1000000000
      ? '${(bytes / 1000000000).toStringAsFixed(2)} GB'
      : '${(bytes / 1000000).round()} MB';
}
