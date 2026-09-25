import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';
import '../controllers/photo_selection_controller.dart';
import '../models/photo_format.dart';

class PhotoSelectionBar extends StatelessWidget {
  const PhotoSelectionBar({
    required this.totals,
    required this.actionLabel,
    required this.onReview,
    super.key,
  });

  final SelectedPhotoTotals totals;
  final String actionLabel;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final canReview = totals.count > 0;
    final sizeText = totals.unknownSizes == 0
        ? formatPhotoSize(totals.knownBytes)
        : '${formatPhotoSize(totals.knownBytes)} known · ${totals.unknownSizes} unknown';
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: TidyColors.background,
        border: Border(top: BorderSide(color: TidyColors.divider)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          TidySpacing.lg,
          TidySpacing.sm,
          TidySpacing.lg,
          TidySpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${totals.count} selected',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(sizeText, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: TidySpacing.sm),
            Opacity(
              opacity: canReview ? 1 : 0.52,
              child: TidyActionButton(
                label: actionLabel,
                onPressed: canReview ? onReview : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
