import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_shadows.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';
import '../../../core/widgets/tidy_clay_surface.dart';

class HomeAccessCard extends StatelessWidget {
  const HomeAccessCard({required this.onManage, super.key});

  final VoidCallback onManage;

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
          Text(
            'Your library, your choice.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: TidySpacing.sm),
          Text(
            'Allow access to find photos, videos or contacts to review.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: TidyColors.secondaryText),
          ),
          const SizedBox(height: TidySpacing.sm),
          TidyActionButton(
            label: 'Manage Permissions',
            style: TidyActionStyle.secondary,
            onPressed: onManage,
          ),
        ],
      ),
    ),
  );
}
