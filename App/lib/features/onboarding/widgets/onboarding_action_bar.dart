import 'package:flutter/material.dart';

import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';

class OnboardingActionBar extends StatelessWidget {
  const OnboardingActionBar({
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.tertiaryLabel,
    this.onTertiary,
    this.secondaryStyle = TidyActionStyle.quiet,
    super.key,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? tertiaryLabel;
  final VoidCallback? onTertiary;
  final TidyActionStyle secondaryStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TidySpacing.lg,
        TidySpacing.actionTop,
        TidySpacing.lg,
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TidyActionButton(label: primaryLabel, onPressed: onPrimary),
          if (secondaryLabel != null) ...<Widget>[
            const SizedBox(height: TidySpacing.actionGap),
            TidyActionButton(
              label: secondaryLabel!,
              onPressed: onSecondary,
              style: secondaryStyle,
            ),
          ],
          if (tertiaryLabel != null) ...<Widget>[
            const SizedBox(height: TidySpacing.xs),
            TidyActionButton(
              label: tertiaryLabel!,
              onPressed: onTertiary,
              style: TidyActionStyle.quiet,
            ),
          ],
        ],
      ),
    );
  }
}
