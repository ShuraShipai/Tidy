import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';
import '../../../core/widgets/tidy_glyph.dart';
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
    final itemLabel = videos.length == 1 ? 'video' : 'videos';
    final reviewedLabel = videos.length == 1 ? 'this video' : 'these videos';
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: TidyColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            TidySpacing.lg,
            TidySpacing.sm,
            TidySpacing.lg,
            TidySpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: TidyColors.sheetHandle,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: TidySpacing.lg),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: TidyColors.orbPinkLight,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: TidyColors.orbShadow,
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const TidyGlyph(
                  TidyGlyphName.trash,
                  size: 28,
                  color: TidyColors.destructive,
                ),
              ),
              const SizedBox(height: TidySpacing.md),
              Text(
                'Delete ${videos.length} $itemLabel?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: TidySpacing.sm),
              Text(
                'You reviewed $reviewedLabel ($amount of primary resource data).',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TidyColors.secondaryText,
                ),
              ),
              const SizedBox(height: TidySpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: TidySpacing.xs),
                    child: TidyGlyph(
                      TidyGlyphName.shield,
                      size: 18,
                      color: TidyColors.violetDeep,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'iOS Photos will ask for approval. Deleted items may remain in Recently Deleted, so available storage may not increase immediately.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TidyColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TidySpacing.md),
              TidyActionButton(
                label: 'Delete from Photos',
                style: TidyActionStyle.destructive,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: TidySpacing.xs),
              TidyActionButton(
                label: 'Cancel',
                style: TidyActionStyle.secondary,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
