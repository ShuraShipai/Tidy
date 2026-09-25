import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_back_button.dart';

class ContactPageHeading extends StatelessWidget {
  const ContactPageHeading({
    required this.title,
    required this.subtitle,
    this.backLabel = 'Back',
    this.onBack,
    super.key,
  });

  final String title;
  final String subtitle;
  final String backLabel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (onBack != null) ...[
        TidyBackButton(
          onPressed: onBack,
          tooltip: backLabel == 'Back' ? 'Back' : 'Back to $backLabel',
        ),
        const SizedBox(height: TidySpacing.md),
      ],
      Text(title, style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: TidySpacing.xs),
      Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: TidyColors.secondaryText),
      ),
    ],
  );
}
