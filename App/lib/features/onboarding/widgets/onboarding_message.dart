import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/design/tidy_sizes.dart';
import '../../../core/widgets/tidy_glyph.dart';
import '../../../core/widgets/tidy_orb.dart';
import 'onboarding_illustration.dart';

class OnboardingMessage extends StatelessWidget {
  const OnboardingMessage({
    required this.title,
    required this.description,
    required this.glyph,
    this.tone = TidyOrbTone.violet,
    this.showCompanions = false,
    this.alignment = TextAlign.center,
    this.titleSize = TidySizes.onboardingTitleText,
    this.child,
    super.key,
  });

  final String title;
  final String description;
  final TidyGlyphName glyph;
  final TidyOrbTone tone;
  final bool showCompanions;
  final TextAlign alignment;
  final double titleSize;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OnboardingIllustration(
          glyph: glyph,
          tone: tone,
          showCompanions: showCompanions,
        ),
        const SizedBox(height: TidySpacing.lg),
        Text(
          title,
          textAlign: alignment,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: titleSize,
            color: TidyColors.primaryText,
          ),
        ),
        if (description.isNotEmpty) ...<Widget>[
          const SizedBox(height: TidySpacing.md),
          Text(
            description,
            textAlign: alignment,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: TidySizes.onboardingBodyText,
              height: TidySizes.onboardingBodyLineHeight,
              color: TidyColors.secondaryText,
            ),
          ),
        ],
        ?child,
      ],
    );
  }
}
