import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';
import '../../../core/widgets/tidy_orb.dart';
import '../../../core/widgets/tidy_glyph.dart';

class CleanupEmptySelectionState extends StatelessWidget {
  const CleanupEmptySelectionState({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(TidySpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TidyOrb(glyph: TidyGlyphName.photo),
          const SizedBox(height: TidySpacing.md),
          Text(
            'Your selection starts here',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: TidySpacing.xs),
          Text(
            'Choose the items you want to review. Finding something never selects it.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: TidySpacing.md),
          TidyActionButton(
            label: 'Explore Photos',
            onPressed: () => context.go('/photos'),
          ),
        ],
      ),
    ),
  );
}
