import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_shadows.dart';
import '../../../core/widgets/tidy_clay_surface.dart';
import '../../scan/models/scan_state.dart';
import '../models/photo_format.dart';
import 'photo_asset_thumbnail.dart';

class PhotoScreenshotTile extends StatelessWidget {
  const PhotoScreenshotTile({
    required this.photo,
    required this.selected,
    required this.onPreview,
    required this.onToggle,
    super.key,
  });

  final MediaRecord photo;
  final bool selected;
  final VoidCallback onPreview;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => TidyClaySurface(
    radius: TidyRadii.thumbnail,
    color: TidyColors.surface,
    shadows: TidyShadows.raised,
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhotoAssetThumbnail(
            photo: photo,
            selected: selected,
            semanticContext: 'Screenshot',
            onPreview: onPreview,
            onToggleSelection: onToggle,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 4, 5, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Screenshot',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  formatPhotoDate(photo.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: TidyColors.secondaryText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
