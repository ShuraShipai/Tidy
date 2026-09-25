import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_shadows.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_clay_surface.dart';
import '../../../core/widgets/tidy_glyph.dart';
import '../../../core/widgets/tidy_orb.dart';

class PhotoOverviewCard extends StatelessWidget {
  const PhotoOverviewCard({
    required this.title,
    required this.detail,
    required this.glyph,
    required this.tone,
    required this.onTap,
    super.key,
  });

  final String title;
  final String detail;
  final TidyGlyphName glyph;
  final TidyOrbTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$title. $detail',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TidyRadii.card),
        child: TidyClaySurface(
          radius: TidyRadii.card,
          shadows: TidyShadows.raised,
          color: TidyColors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TidySpacing.md,
              vertical: TidySpacing.md,
            ),
            child: Row(
              children: [
                TidyOrb(glyph: glyph, tone: tone, size: 58),
                const SizedBox(width: TidySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: TidySpacing.xs),
                      Text(
                        detail,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TidySpacing.xs),
                const Icon(Icons.chevron_right, color: TidyColors.primaryText),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
