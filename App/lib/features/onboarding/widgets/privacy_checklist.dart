import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/design/tidy_sizes.dart';
import '../../../core/widgets/tidy_glyph.dart';

class PrivacyChecklist extends StatelessWidget {
  const PrivacyChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    const lines = <String>[
      'On-device analysis',
      'Nothing deleted automatically',
      'Review everything first',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TidySpacing.sm,
        TidySpacing.lg,
        TidySpacing.sm,
        0,
      ),
      child: Column(
        children: <Widget>[
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: TidySpacing.sm),
              child: Row(
                children: <Widget>[
                  const TidyGlyph(
                    TidyGlyphName.check,
                    size: TidySizes.checklistIcon,
                    color: TidyColors.emerald,
                  ),
                  const SizedBox(width: TidySpacing.md),
                  Expanded(
                    child: Text(
                      line,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
