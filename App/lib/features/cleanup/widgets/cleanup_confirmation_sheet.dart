import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';

class CleanupConfirmationSheet extends StatelessWidget {
  const CleanupConfirmationSheet({
    required this.count,
    required this.sizeEstimate,
    this.photosMayRetainItems = true,
    super.key,
  });

  final int count;
  final String sizeEstimate;
  final bool photosMayRetainItems;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TidySpacing.lg,
          TidySpacing.xl,
          TidySpacing.lg,
          TidySpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.delete_outline,
              size: 44,
              color: TidyColors.destructive,
            ),
            const SizedBox(height: TidySpacing.md),
            Text(
              'Clean selected items?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: TidySpacing.xs),
            Text(
              '$count selected items will be sent for removal. $sizeEstimate. ${photosMayRetainItems ? 'Photos may keep media in Recently Deleted.' : 'Contact changes are checked against the address book after confirmation.'}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: TidySpacing.md),
            TidyActionButton(
              label: 'Clean $count Items',
              style: TidyActionStyle.destructive,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: TidySpacing.xs),
            TidyActionButton(
              label: 'Cancel',
              style: TidyActionStyle.secondary,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
}
