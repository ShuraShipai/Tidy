import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_shadows.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_clay_surface.dart';
import '../../scan/models/scan_snapshot.dart';

class HomeScanBanner extends StatelessWidget {
  const HomeScanBanner({
    required this.snapshot,
    required this.onOpen,
    super.key,
  });

  final ScanSnapshot snapshot;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => TidyClaySurface(
    radius: TidyRadii.card,
    color: TidyColors.surface,
    shadows: TidyShadows.raised,
    child: InkWell(
      borderRadius: BorderRadius.circular(TidyRadii.card),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(TidySpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Scanning your library…',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                ),
                if (snapshot.progress != null)
                  Text(
                    '${(snapshot.progress! * 100).clamp(0, 100).round()}%',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
              ],
            ),
            const SizedBox(height: TidySpacing.sm),
            LinearProgressIndicator(
              value: snapshot.progress?.clamp(0.0, 1.0),
              minHeight: 9,
              borderRadius: BorderRadius.circular(9),
              color: TidyColors.primary,
              backgroundColor: TidyColors.violetTint,
            ),
            const SizedBox(height: TidySpacing.sm),
            Text(
              snapshot.currentCategory == CleanupCategory.duplicateContacts
                  ? 'Checking accessible contacts…'
                  : 'Checking similar photos…',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: TidyColors.secondaryText),
            ),
          ],
        ),
      ),
    ),
  );
}
