import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';

class PhotoAnalysisNote extends StatelessWidget {
  const PhotoAnalysisNote({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: TidySpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 17, color: TidyColors.violetDeep),
        const SizedBox(width: TidySpacing.xs),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: TidyColors.secondaryText),
          ),
        ),
      ],
    ),
  );
}
