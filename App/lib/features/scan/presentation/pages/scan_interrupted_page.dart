import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../../core/widgets/tidy_back_button.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../controllers/scan_controller.dart';
import '../../widgets/scan_interrupted_recovery.dart';

class ScanInterruptedPage extends ConsumerWidget {
  const ScanInterruptedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: TidyPageBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TidySpacing.lg),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TidyBackButton(
                  onPressed: () => context.pop(),
                  tooltip: 'Back',
                ),
              ),
              const Expanded(child: ScanInterruptedRecovery()),
              TidyActionButton(
                label: 'Start Again',
                onPressed: () {
                  ref.read(scanControllerProvider.notifier).start();
                  context.push('/scan');
                },
              ),
              const SizedBox(height: TidySpacing.xs),
              TidyActionButton(
                label: 'Back to Home',
                style: TidyActionStyle.secondary,
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
