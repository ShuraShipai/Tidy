import 'package:flutter/material.dart';

import '../../../core/design/tidy_spacing.dart';

class PhotoReviewUnavailableState extends StatelessWidget {
  const PhotoReviewUnavailableState({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(TidySpacing.lg),
      child: Text(
        'The photo library changed or access is unavailable. Return to Photos and review the current library before continuing.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
  );
}
