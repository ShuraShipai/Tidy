import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_shadows.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_clay_surface.dart';
import '../../../core/widgets/tidy_glyph.dart';
import '../../../core/widgets/tidy_orb.dart';
import '../../scan/models/scan_snapshot.dart';

class HomeCategoryCard extends StatelessWidget {
  const HomeCategoryCard({
    required this.category,
    required this.finding,
    required this.onTap,
    super.key,
  });

  final CleanupCategory category;
  final CategoryFinding? finding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (title, glyph, tint, tone, unit, footnote) = switch (category) {
      CleanupCategory.similarPhotos => (
        'Similar Photos',
        TidyGlyphName.photo,
        const Color(0xFFF1E9FF),
        TidyOrbTone.violet,
        'photos',
        'Duplicates & similar shots',
      ),
      CleanupCategory.screenshots => (
        'Screenshots',
        TidyGlyphName.photo,
        const Color(0xFFE8F5FF),
        TidyOrbTone.sky,
        'photos',
        'Review →',
      ),
      CleanupCategory.largeVideos => (
        'Large Videos',
        TidyGlyphName.video,
        const Color(0xFFFFEDF5),
        TidyOrbTone.pink,
        'videos',
        'Review →',
      ),
      CleanupCategory.duplicateContacts => (
        'Duplicate Contacts',
        TidyGlyphName.contacts,
        const Color(0xFFE7F8F2),
        TidyOrbTone.green,
        'groups',
        'Possible duplicates',
      ),
    };
    final currentFinding = finding;
    final count = currentFinding?.count;
    final value = currentFinding == null
        ? 'Not scanned'
        : category == CleanupCategory.duplicateContacts
        ? '$count groups'
        : currentFinding.estimatedBytes == null
        ? count == 0
              ? '0 B'
              : 'Size unavailable'
        : _formatSize(currentFinding.estimatedBytes!);
    return TidyClaySurface(
      radius: TidyRadii.nested,
      color: tint,
      shadows: TidyShadows.raised,
      child: InkWell(
        borderRadius: BorderRadius.circular(TidyRadii.nested),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(TidySpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TidyOrb(glyph: glyph, tone: tone, size: 35),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: TidyColors.lightViolet,
                  ),
                ],
              ),
              const SizedBox(height: TidySpacing.sm),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: TidyColors.primaryText),
              ),
              const SizedBox(height: TidySpacing.xs),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 19),
              ),
              if (count != null) ...[
                if (category != CleanupCategory.duplicateContacts)
                  Text(
                    '$count $unit',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                Text(
                  footnote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes >= 1000000000) {
      return '${(bytes / 1000000000).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1000000) return '${(bytes / 1000000).round()} MB';
    return '${(bytes / 1000).round()} KB';
  }
}
