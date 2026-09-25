import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';
import '../models/photo_format.dart';

class PhotoCollectionMetrics extends StatelessWidget {
  const PhotoCollectionMetrics({
    required this.count,
    required this.bytes,
    super.key,
  });

  final int count;
  final int? bytes;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text('$count', style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(width: TidySpacing.xs),
      Text('photos', style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(width: TidySpacing.md),
      Container(width: 1, height: 24, color: TidyColors.divider),
      const SizedBox(width: TidySpacing.md),
      Expanded(
        child: Text(
          '${bytes == null ? 'Size unavailable' : formatPhotoSize(bytes!)} reviewable',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  );
}
