import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_shadows.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_clay_surface.dart';
import '../models/photo_format.dart';
import '../models/photo_group.dart';
import 'photo_keeper_badge.dart';
import 'photo_asset_thumbnail.dart';

class PhotoGroupCard extends StatelessWidget {
  const PhotoGroupCard({
    required this.group,
    required this.selectedIds,
    required this.keeperId,
    required this.onPreview,
    required this.onToggle,
    required this.onChooseKeeper,
    required this.onSelectAllExceptBest,
    required this.onCompare,
    super.key,
  });

  final PhotoGroup group;
  final Set<String> selectedIds;
  final String keeperId;
  final ValueChanged<String> onPreview;
  final ValueChanged<String> onToggle;
  final ValueChanged<String>? onChooseKeeper;
  final VoidCallback onSelectAllExceptBest;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) => TidyClaySurface(
    radius: TidyRadii.card,
    color: TidyColors.surface,
    shadows: TidyShadows.raised,
    child: Padding(
      padding: const EdgeInsets.all(TidySpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.kind == PhotoGroupKind.exactDuplicate
                          ? 'Duplicate Set'
                          : 'Similar Set',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: TidySpacing.xs),
                    Text(
                      _summary(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const PhotoKeeperBadge(),
            ],
          ),
          const SizedBox(height: TidySpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - TidySpacing.sm * 2) / 3;
              return Wrap(
                spacing: TidySpacing.sm,
                runSpacing: TidySpacing.sm,
                children: [
                  for (final photo in group.items)
                    SizedBox(
                      width: tileWidth,
                      child: PhotoAssetThumbnail(
                        photo: photo,
                        selected: selectedIds.contains(photo.id),
                        isKeeper: photo.id == keeperId,
                        semanticContext:
                            group.kind == PhotoGroupKind.exactDuplicate
                            ? 'Duplicate photo'
                            : 'Similar photo',
                        onPreview: () => onPreview(photo.id),
                        onChooseKeeper: onChooseKeeper == null
                            ? null
                            : () => onChooseKeeper!(photo.id),
                        onToggleSelection: () => onToggle(photo.id),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: TidySpacing.sm),
          Row(
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: TextButton(
                  onPressed: onSelectAllExceptBest,
                  style: TextButton.styleFrom(
                    foregroundColor: TidyColors.primary,
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                  ),
                  child: const Text(
                    'Select All Except Best',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onCompare,
                style: TextButton.styleFrom(
                  foregroundColor: TidyColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                ),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Compare'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  String _summary() {
    final bytes = group.knownBytes;
    final size = group.unknownSizeCount == 0
        ? formatPhotoSize(bytes)
        : '${formatPhotoSize(bytes)} known';
    DateTime? date;
    for (final item in group.items) {
      if (item.createdAt != null) {
        date = item.createdAt;
        break;
      }
    }
    return '${group.items.length} photos · $size${date == null ? '' : ' · ${formatPhotoDate(date)}'}';
  }
}
