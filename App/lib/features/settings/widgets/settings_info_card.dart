import 'package:flutter/material.dart';

import '../../../core/design/tidy_spacing.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_shadows.dart';
import '../../../core/widgets/tidy_clay_surface.dart';

class SettingsInfoCard extends StatelessWidget {
  const SettingsInfoCard({
    this.icon,
    this.title,
    required this.body,
    super.key,
  });

  final IconData? icon;
  final String? title;
  final String body;

  @override
  Widget build(BuildContext context) => TidyClaySurface(
    radius: TidyRadii.card,
    shadows: TidyShadows.raised,
    child: Padding(
      padding: const EdgeInsets.all(TidySpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 32),
            const SizedBox(height: TidySpacing.md),
          ],
          if (title != null) ...[
            Text(title!, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: TidySpacing.xs),
          ],
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    ),
  );
}
