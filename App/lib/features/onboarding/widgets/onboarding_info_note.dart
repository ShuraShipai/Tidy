import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_spacing.dart';

class OnboardingInfoNote extends StatelessWidget {
  const OnboardingInfoNote({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: TidySpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: TidySpacing.sm,
        vertical: TidySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: TidyColors.noteBackground,
        borderRadius: BorderRadius.circular(TidyRadii.thumbnail),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: TidyColors.secondaryText),
      ),
    );
  }
}
