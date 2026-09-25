import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';

class PhotoLimitedAccessNote extends StatelessWidget {
  const PhotoLimitedAccessNote({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: TidySpacing.sm),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 17, color: TidyColors.violetDeep),
        const SizedBox(width: TidySpacing.xs),
        Expanded(
          child: Text(
            'Limited access · only selected photos are shown.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    ),
  );
}
