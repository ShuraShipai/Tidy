import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../../core/widgets/tidy_orb.dart';
import '../../../../core/widgets/tidy_glyph.dart';
import '../controllers/scan_controller.dart';

class ScanInterruptedRecovery extends ConsumerWidget {
  const ScanInterruptedRecovery({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanControllerProvider);
    final mediaCount = scan.reviewableIds.length;
    final contactGroups = scan.contacts.length;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TidyOrb(glyph: TidyGlyphName.spark, tone: TidyOrbTone.amber),
            const SizedBox(height: TidySpacing.lg),
            Text(
              'Scan interrupted',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: TidySpacing.sm),
            Text(
              scan.hasResults
                  ? 'Your last completed results are still available. This scan cannot resume from its stopping point.'
                  : 'The scan stopped before results were completed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (scan.hasResults) ...[
              const SizedBox(height: TidySpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(TidySpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last completed scan',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: TidySpacing.xs),
                      Text(
                        '$mediaCount reviewable media items · $contactGroups contact match groups.',
                      ),
                      const SizedBox(height: TidySpacing.xs),
                      TidyActionButton(
                        label: 'Review Last Scan',
                        style: TidyActionStyle.quiet,
                        onPressed: () => context.go('/home'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
