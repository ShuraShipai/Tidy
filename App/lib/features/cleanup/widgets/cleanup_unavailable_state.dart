import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';

class CleanupUnavailableState extends StatelessWidget {
  const CleanupUnavailableState({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(TidySpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_empty, size: 48),
          const SizedBox(height: TidySpacing.md),
          Text(
            'No completed scan to review',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: TidySpacing.xs),
          const Text('Return Home to view your current scan state.'),
          const SizedBox(height: TidySpacing.md),
          TidyActionButton(label: 'Home', onPressed: () => context.go('/home')),
        ],
      ),
    ),
  );
}
