import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../controllers/cleanup_controller.dart';
import '../../models/cleanup_plan.dart';

class CleanupRemainingPage extends ConsumerWidget {
  const CleanupRemainingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries =
        ref.watch(cleanupControllerProvider).result?.remainingEntries ??
        const [];
    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(TidySpacing.lg),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Text(
                      'Remaining Items',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('No remaining items.'))
                    : ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) => ListTile(
                          leading: const Icon(Icons.error_outline),
                          title: Text(entries[index].title),
                          subtitle: Text(
                            '${entries[index].category.label} · ${entries[index].detail}',
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(TidySpacing.lg),
                child: Column(
                  children: [
                    if (entries.isNotEmpty)
                      TidyActionButton(
                        label: 'Review Remaining',
                        onPressed: () => context.go('/cleanup/review'),
                      ),
                    const SizedBox(height: TidySpacing.xs),
                    TidyActionButton(
                      label: 'Done',
                      style: entries.isEmpty
                          ? TidyActionStyle.primary
                          : TidyActionStyle.quiet,
                      onPressed: () => context.go('/home'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
