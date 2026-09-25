import 'package:flutter/material.dart';

import '../../../core/design/tidy_spacing.dart';
import '../models/cleanup_plan.dart';

class CleanupOutcomeRow extends StatelessWidget {
  const CleanupOutcomeRow({
    required this.category,
    required this.value,
    super.key,
  });

  final CleanupCategory category;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TidySpacing.sm),
    child: Row(
      children: [
        Icon(switch (category) {
          CleanupCategory.similarPhotos => Icons.photo_outlined,
          CleanupCategory.screenshots => Icons.crop_free,
          CleanupCategory.possiblyBlurry => Icons.blur_on,
          CleanupCategory.selectedPhotos => Icons.photo_outlined,
          CleanupCategory.largeVideos => Icons.video_library_outlined,
          CleanupCategory.duplicateContacts => Icons.contacts_outlined,
        }),
        const SizedBox(width: TidySpacing.sm),
        Expanded(child: Text(category.label)),
        Text(value, style: Theme.of(context).textTheme.labelLarge),
      ],
    ),
  );
}
