import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_sizes.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_glyph.dart';
import '../../../core/widgets/tidy_orb.dart';

class SplashIdentity extends StatelessWidget {
  const SplashIdentity({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: TidySizes.splashBottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const TidyOrb(
              glyph: TidyGlyphName.storage,
              size: TidySizes.splashOrb,
            ),
            const SizedBox(height: TidySpacing.lg),
            Text(
              'tidy',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: TidySizes.wordmarkText,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: TidySpacing.sm),
            Text(
              'Make room for what matters.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: TidyColors.secondaryText),
            ),
          ],
        ),
      ),
    ),
  );
}
