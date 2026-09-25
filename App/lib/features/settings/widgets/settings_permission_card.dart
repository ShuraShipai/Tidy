import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';

class SettingsPermissionCard extends StatelessWidget {
  const SettingsPermissionCard({
    required this.title,
    required this.status,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String title;
  final String status;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(TidySpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: TidyColors.violetTint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: TidyColors.violetDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TidySpacing.xs),
        Text(
          description,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: TidyColors.secondaryText),
        ),
        const SizedBox(height: TidySpacing.xs),
        Center(
          child: TextButton(onPressed: onAction, child: Text(actionLabel)),
        ),
      ],
    ),
  );
}
