import 'package:flutter/material.dart';

import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';

/// Explicitly confirms removal of Photos originals after their Vault copies
/// have been created and verified.
class VaultMoveConfirmationSheet extends StatelessWidget {
  const VaultMoveConfirmationSheet({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(TidySpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Remove $count ${count == 1 ? 'original' : 'originals'} from Photos?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: TidySpacing.md),
          Text(
            'The encrypted Vault ${count == 1 ? 'copy is' : 'copies are'} ready. '
            'iOS may keep removed items in Recently Deleted. Tidy cannot '
            'permanently delete items from Recently Deleted.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: TidySpacing.lg),
          TidyActionButton(
            label: 'Remove Originals from Photos',
            style: TidyActionStyle.destructive,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: TidySpacing.xs),
          TidyActionButton(
            label: 'Keep Originals',
            style: TidyActionStyle.secondary,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    ),
  );
}
