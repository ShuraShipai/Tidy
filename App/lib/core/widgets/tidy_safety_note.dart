import 'package:flutter/material.dart';

import '../design/tidy_colors.dart';
import '../design/tidy_spacing.dart';
import '../design/tidy_sizes.dart';
import 'tidy_glyph.dart';

class TidySafetyNote extends StatelessWidget {
  const TidySafetyNote({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TidySpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const TidyGlyph(
            TidyGlyphName.shield,
            size: TidySizes.smallIcon,
            color: TidyColors.violetDeep,
          ),
          const SizedBox(width: TidySpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: TidyColors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}
