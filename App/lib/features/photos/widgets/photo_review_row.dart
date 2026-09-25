import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_shadows.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_clay_surface.dart';
import '../../scan/models/scan_state.dart';
import '../models/photo_format.dart';
import 'photo_asset_thumbnail.dart';

class PhotoReviewRow extends StatelessWidget {
  const PhotoReviewRow({
    required this.photo,
    required this.onPreview,
    required this.onRemove,
    super.key,
  });

  final MediaRecord photo;
  final VoidCallback onPreview;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => TidyClaySurface(
    radius: TidyRadii.nested,
    color: TidyColors.surface,
    shadows: TidyShadows.raised,
    child: Padding(
      padding: const EdgeInsets.all(TidySpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: PhotoAssetThumbnail(
              photo: photo,
              selected: true,
              onPreview: onPreview,
              onToggleSelection: onRemove,
              semanticContext: 'Selected photo',
            ),
          ),
          const SizedBox(width: TidySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Photo', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: TidySpacing.xs),
                Text(
                  formatPhotoDate(photo.createdAt),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  photo.bytes == null
                      ? 'Size unavailable'
                      : formatPhotoSize(photo.bytes!),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove from selection',
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    ),
  );
}
