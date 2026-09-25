import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';

class ContactPageHeading extends StatelessWidget {
  const ContactPageHeading({
    required this.title,
    required this.subtitle,
    required this.backLabel,
    required this.onBack,
    super.key,
  });

  final String title;
  final String subtitle;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextButton.icon(
        onPressed: onBack,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        icon: const Icon(Icons.chevron_left),
        label: Text(backLabel),
      ),
      const SizedBox(height: TidySpacing.md),
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
