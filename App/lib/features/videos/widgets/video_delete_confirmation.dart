import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../models/video_record.dart';

class VideoDeleteConfirmation extends StatelessWidget {
  const VideoDeleteConfirmation({required this.videos, super.key});

  final List<VideoRecord> videos;

  @override
  Widget build(BuildContext context) {
    final bytes = videos.fold<int>(0, (sum, video) => sum + video.bytes);
    final amount = bytes >= 1000000000
        ? '${(bytes / 1000000000).toStringAsFixed(2)} GB'
        : '${(bytes / 1000000).round()} MB';
    return AlertDialog(
      title: Text('Delete ${videos.length} videos?'),
      content: Text(
        'You reviewed these videos ($amount of primary resource data). Photos will ask for approval. Deleted items may remain in Recently Deleted, so available storage may not increase immediately.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep Videos'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Delete from Photos',
            style: TextStyle(color: TidyColors.destructive),
          ),
        ),
      ],
    );
  }
}
