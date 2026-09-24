import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/design/tidy_sizes.dart';
import '../../../core/widgets/tidy_glyph.dart';

class OnboardingBenefits extends StatelessWidget {
  const OnboardingBenefits({super.key});

  @override
  Widget build(BuildContext context) {
    const items = <(TidyGlyphName, String)>[
      (TidyGlyphName.shield, 'On-device'),
      (TidyGlyphName.photo, 'Safe review'),
      (TidyGlyphName.check, 'You choose what goes'),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: TidySpacing.lg),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: TidySpacing.md,
        runSpacing: TidySpacing.sm,
        children: <Widget>[
          for (final (icon, label) in items)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TidyGlyph(
                  icon,
                  size: TidySizes.smallIcon,
                  color: TidyColors.primary,
                ),
                const SizedBox(height: TidySpacing.xs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: TidyColors.secondaryText,
                    fontSize: TidySizes.benefitText,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
