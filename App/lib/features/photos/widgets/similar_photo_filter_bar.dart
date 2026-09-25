import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';
import '../models/photo_group.dart';

class SimilarPhotoFilterBar extends StatelessWidget {
  const SimilarPhotoFilterBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final SimilarPhotoFilter selected;
  final ValueChanged<SimilarPhotoFilter> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: TidyColors.violetTint,
      borderRadius: BorderRadius.circular(TidySpacing.md),
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final filter in SimilarPhotoFilter.values)
            Expanded(
              child: Material(
                color: selected == filter
                    ? TidyColors.surface
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(TidySpacing.sm),
                child: InkWell(
                  onTap: () => onChanged(filter),
                  borderRadius: BorderRadius.circular(TidySpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      switch (filter) {
                        SimilarPhotoFilter.all => 'All',
                        SimilarPhotoFilter.duplicates => 'Duplicates',
                        SimilarPhotoFilter.similar => 'Similar',
                      },
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected == filter
                            ? TidyColors.violetDeep
                            : TidyColors.secondaryText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
