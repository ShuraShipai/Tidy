import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_colors.dart';
import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../controllers/scan_snapshot_provider.dart';
import '../../controllers/scan_controller.dart';
import '../../models/scan_state.dart' as data;
import '../../models/scan_snapshot.dart';
import '../../widgets/scan_progress_ring.dart';
import '../../widgets/scan_stage_list.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({this.autoStart = false, super.key});

  final bool autoStart;

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            ref.read(scanControllerProvider).phase == data.ScanPhase.idle) {
          ref.read(scanControllerProvider.notifier).start();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(scanSnapshotProvider);
    final state = ref.watch(scanControllerProvider);
    final scanning = snapshot.phase == ScanPhase.scanning;
    ref.listen(scanControllerProvider, (previous, next) {
      if (next.phase == data.ScanPhase.success ||
          next.phase == data.ScanPhase.empty ||
          next.phase == data.ScanPhase.permissionDenied) {
        context.go('/home');
      }
    });
    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TidySpacing.lg,
              TidySpacing.pageTop,
              TidySpacing.lg,
              TidySpacing.lg,
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scanning your iPhone',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: TidySpacing.sm),
                        Text(
                          'Looking for things you may not need…',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: TidyColors.secondaryText),
                        ),
                        const SizedBox(height: 38),
                        Center(
                          child: scanning
                              ? ScanProgressRing(progress: snapshot.progress)
                              : const Icon(
                                  Icons.search_rounded,
                                  size: 150,
                                  color: TidyColors.lightViolet,
                                ),
                        ),
                        const SizedBox(height: 46),
                        ScanStageList(snapshot: snapshot),
                        if (state.message != null)
                          Padding(
                            padding: const EdgeInsets.only(top: TidySpacing.md),
                            child: Text(
                              state.message!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: TidySpacing.sm),
                TidyActionButton(
                  label: 'Cancel',
                  style: TidyActionStyle.secondary,
                  onPressed: () async {
                    if (scanning) {
                      await ref.read(scanControllerProvider.notifier).cancel();
                      if (context.mounted) context.go('/home');
                    } else {
                      context.pop();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
