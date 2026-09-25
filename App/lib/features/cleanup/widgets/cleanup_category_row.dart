import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';
import '../models/cleanup_plan.dart';

class CleanupCategoryRow extends StatelessWidget {
  const CleanupCategoryRow({
    required this.category,
    required this.count,
    required this.sizeText,
    required this.onEdit,
    super.key,
  });

  final CleanupCategory category;
  final int count;
  final String sizeText;
  final VoidCallback onEdit;

  IconData get _icon => switch (category) {
    CleanupCategory.similarPhotos => Icons.photo_outlined,
    CleanupCategory.screenshots => Icons.crop_free,
    CleanupCategory.possiblyBlurry => Icons.blur_on,
    CleanupCategory.selectedPhotos => Icons.photo_outlined,
    CleanupCategory.largeVideos => Icons.video_library_outlined,
    CleanupCategory.duplicateContacts => Icons.contacts_outlined,
  };

  Color get _color => switch (category) {
    CleanupCategory.similarPhotos => TidyColors.violetDeep,
    CleanupCategory.screenshots => TidyColors.sky,
    CleanupCategory.possiblyBlurry => TidyColors.amber,
    CleanupCategory.selectedPhotos => TidyColors.violetDeep,
    CleanupCategory.largeVideos => TidyColors.pink,
    CleanupCategory.duplicateContacts => TidyColors.emerald,
  };

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TidySpacing.sm),
    child: Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(_icon, color: _color),
          ),
        ),
        const SizedBox(width: TidySpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.label,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 2),
              Text(
                '$count ${category == CleanupCategory.duplicateContacts ? 'contacts' : 'items'}${sizeText.isEmpty ? '' : ' · $sizeText'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        TextButton(onPressed: onEdit, child: const Text('Edit')),
      ],
    ),
  );
}
