import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../controllers/cleanup_controller.dart';
import '../../models/cleanup_plan.dart';
import '../../widgets/cleanup_outcome_row.dart';

class CleanupResultPage extends ConsumerWidget {
  const CleanupResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cleanupControllerProvider);
    final result = state.result;
    final deleted = result?.deletedEntries ?? const <CleanupEntry>[];
    final remaining = result?.remainingEntries ?? const <CleanupEntry>[];
    final complete = state.phase == CleanupPhase.complete;
    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(TidySpacing.lg),
            children: [
              const SizedBox(height: TidySpacing.xl),
              Icon(
                complete ? Icons.check_circle_outline : Icons.info_outline,
                size: 72,
              ),
              const SizedBox(height: TidySpacing.md),
              Text(
                complete ? 'Cleanup complete' : 'Cleanup needs review',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: TidySpacing.sm),
              Text(
                complete
                    ? '${deleted.length} selected ${deleted.length == 1 ? 'item was' : 'items were'} confirmed removed.'
                    : '${deleted.length} removed · ${remaining.length} still need attention.',
                textAlign: TextAlign.center,
              ),
              if ((result?.knownBytesDeleted ?? 0) > 0) ...[
                const SizedBox(height: TidySpacing.xs),
                Text(
                  'Known size of removed media: ${_size(result?.knownBytesDeleted ?? 0)}. Actual free space may update later.',
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: TidySpacing.lg),
              for (final category in CleanupCategory.values) ...[
                if (deleted
                    .where((entry) => entry.category == category)
                    .isNotEmpty)
                  CleanupOutcomeRow(
                    category: category,
                    value:
                        '${deleted.where((entry) => entry.category == category).length} removed',
                  ),
                if (remaining
                    .where((entry) => entry.category == category)
                    .isNotEmpty)
                  CleanupOutcomeRow(
                    category: category,
                    value:
                        '${remaining.where((entry) => entry.category == category).length} remaining',
                  ),
              ],
              if (state.error != null) ...[
                const SizedBox(height: TidySpacing.md),
                Text(state.error!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: TidySpacing.lg),
              if (remaining.isNotEmpty) ...[
                TidyActionButton(
                  label: 'Review Remaining',
                  onPressed: () => context.go('/cleanup/remaining'),
                ),
                const SizedBox(height: TidySpacing.xs),
                TidyActionButton(
                  label: 'Try Again',
                  style: TidyActionStyle.secondary,
                  onPressed: () => context.go('/cleanup/review'),
                ),
              ],
              const SizedBox(height: TidySpacing.xs),
              TidyActionButton(
                label: 'Done',
                style: remaining.isEmpty
                    ? TidyActionStyle.primary
                    : TidyActionStyle.quiet,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _size(int bytes) => bytes >= 1000000000
      ? '${(bytes / 1000000000).toStringAsFixed(1)} GB'
      : bytes >= 1000000
      ? '${(bytes / 1000000).round()} MB'
      : '${(bytes / 1000).round()} KB';
}
