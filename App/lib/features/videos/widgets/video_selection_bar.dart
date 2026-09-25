import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_shadows.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';
import '../../../core/widgets/tidy_clay_surface.dart';

class VideoSelectionBar extends StatelessWidget {
  const VideoSelectionBar({
    required this.count,
    required this.knownBytes,
    required this.onReview,
    super.key,
  });

  final int count;
  final int knownBytes;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: TidyClaySurface(
      radius: TidyRadii.card,
      color: TidyColors.surface,
      shadows: TidyShadows.raised,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TidySpacing.md,
          TidySpacing.sm,
          TidySpacing.md,
          TidySpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  '$count selected',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  _size(knownBytes),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TidyColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TidySpacing.sm),
            TidyActionButton(
              label: 'Review Videos',
              onPressed: count == 0 ? null : onReview,
            ),
          ],
        ),
      ),
    ),
  );

  String _size(int bytes) => bytes >= 1000000000
      ? '${(bytes / 1000000000).toStringAsFixed(2)} GB'
      : '${(bytes / 1000000).round()} MB';
}
