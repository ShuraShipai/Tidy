import 'package:flutter/material.dart';

import '../../../core/design/tidy_spacing.dart';

class PhotoNoSelectionState extends StatelessWidget {
  const PhotoNoSelectionState({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(TidySpacing.lg),
      child: Text(
        'No photos are selected. Your library has not changed.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
  );
}
