import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_sizes.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';
import '../../../core/widgets/tidy_glyph.dart';
import '../../../core/widgets/tidy_orb.dart';
import '../models/photo_group.dart';

class PhotoCleanEmptyState extends StatelessWidget {
  const PhotoCleanEmptyState({required this.kind, super.key});

  final PhotoCollectionKind kind;

  @override
  Widget build(BuildContext context) {
    final screenshot = kind == PhotoCollectionKind.screenshots;
    final blurry = kind == PhotoCollectionKind.blurry;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TidySpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TidyOrb(
            glyph: TidyGlyphName.photo,
            tone: screenshot
                ? TidyOrbTone.sky
                : blurry
                ? TidyOrbTone.amber
                : TidyOrbTone.violet,
            size: TidySizes.illustrationOrb,
          ),
          const SizedBox(height: TidySpacing.xl),
          Text(
            screenshot
                ? 'No screenshots to clean'
                : blurry
                ? 'No possibly blurry photos'
                : 'Every shot is its own.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: TidySpacing.sm),
          Text(
            screenshot
                ? 'You’re all caught up here.'
                : blurry
                ? 'No photos were flagged by the on-device blur check.'
                : 'No similar photos to review. Your memories have room to be themselves.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: TidyColors.secondaryText),
          ),
          const SizedBox(height: TidySpacing.xl),
          TidyActionButton(
            label: 'Back to Home',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}
