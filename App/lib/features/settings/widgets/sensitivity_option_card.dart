import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_spacing.dart';
import '../models/scan_preferences.dart';

class SensitivityOptionCard extends StatelessWidget {
  const SensitivityOptionCard({
    required this.value,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final SimilarPhotoSensitivity value;
  final bool selected;
  final VoidCallback onTap;

  String get _description => switch (value) {
    SimilarPhotoSensitivity.strict => 'Only very close matches.',
    SimilarPhotoSensitivity.balanced => 'A helpful mix of similar moments.',
    SimilarPhotoSensitivity.broad => 'More suggestions, more to review.',
  };

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? TidyColors.violetTint : TidyColors.surface,
    borderRadius: BorderRadius.circular(TidyRadii.card),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TidyRadii.card),
      child: Container(
        padding: const EdgeInsets.all(TidySpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? TidyColors.primary : Colors.transparent,
            width: selected ? 1.5 : 0,
          ),
          borderRadius: BorderRadius.circular(TidyRadii.card),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: TidySpacing.xs),
                  Text(
                    _description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check, color: TidyColors.primary),
          ],
        ),
      ),
    ),
  );
}
