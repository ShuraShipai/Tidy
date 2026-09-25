import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../controllers/cleanup_controller.dart';
import '../../models/cleanup_plan.dart';

class CleanupProgressPage extends ConsumerStatefulWidget {
  const CleanupProgressPage({this.reviewedPlan, super.key});

  final CleanupPlan? reviewedPlan;

  @override
  ConsumerState<CleanupProgressPage> createState() =>
      _CleanupProgressPageState();
}

class _CleanupProgressPageState extends ConsumerState<CleanupProgressPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reviewed = widget.reviewedPlan;
      if (mounted && reviewed != null) {
        unawaited(
          ref.read(cleanupControllerProvider.notifier).execute(reviewed),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cleanupControllerProvider);
    ref.listen(cleanupControllerProvider, (previous, next) {
      if (next.phase == CleanupPhase.complete ||
          next.phase == CleanupPhase.partial ||
          next.phase == CleanupPhase.failed) {
        context.go('/cleanup/result');
      }
    });
    if (widget.reviewedPlan == null && state.phase == CleanupPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/cleanup/review');
      });
    }
    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(TidySpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator.adaptive(),
                  const SizedBox(height: TidySpacing.lg),
                  Text(
                    'Cleaning your selected items',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: TidySpacing.sm),
                  Text(
                    state.message ?? 'Checking your selection…',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
