import 'package:flutter/material.dart';

import '../../../core/design/tidy_spacing.dart';

class PhotoInfoItem extends StatelessWidget {
  const PhotoInfoItem({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: TidySpacing.xs),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: Colors.white),
        ),
      ],
    ),
  );
}
