import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../../scan/controllers/scan_controller.dart';
import '../../../scan/controllers/scan_snapshot_provider.dart';
import '../../../scan/models/scan_snapshot.dart';
import '../../../scan/models/scan_state.dart' as scan_data;
import '../../widgets/home_header.dart';
import '../../widgets/home_storage_card.dart';
import '../../widgets/home_scan_banner.dart';
import '../../widgets/home_category_card.dart';
import '../../widgets/home_empty_state.dart';
import '../../widgets/home_access_card.dart';
import '../../widgets/scan_status_note.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(scanSnapshotProvider);
    final state = ref.watch(scanControllerProvider);
    final noAccess = snapshot.phase == ScanPhase.noAccess;
    final showEmpty =
        snapshot.phase == ScanPhase.complete &&
        !snapshot.hasFindings &&
        !state.incomplete;
    void scan() {
      if (!state.running) ref.read(scanControllerProvider.notifier).start();
      context.push('/scan');
    }

    return Scaffold(
      body: TidyPageBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(TidySpacing.lg),
            children: [
              HomeHeader(
                onHistory: null,
                showTitle: !state.running,
                showHistory: !showEmpty,
                compact: state.running,
              ),
              const SizedBox(height: TidySpacing.lg),
              if (showEmpty)
                HomeEmptyState(snapshot: snapshot, onScan: scan)
              else ...[
                if (state.phase != scan_data.ScanPhase.idle)
                  ScanStatusNote(state: state),
                if (noAccess) ...[
                  HomeAccessCard(
                    onManage: () => context.push('/onboarding/photos'),
                  ),
                  const SizedBox(height: TidySpacing.md),
                ],
                if (state.running) ...[
                  HomeScanBanner(snapshot: snapshot, onOpen: scan),
                  const SizedBox(height: TidySpacing.md),
                ],
                HomeStorageCard(
                  snapshot: snapshot,
                  onScan: scan,
                  permissionUnavailable: noAccess,
                ),
                const SizedBox(height: TidySpacing.lg),
                Text(
                  'Your cleanup categories',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: TidySpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: TidySpacing.md,
                  crossAxisSpacing: TidySpacing.md,
                  mainAxisExtent:
                      170 +
                      (MediaQuery.textScalerOf(context).scale(16) - 16) * 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final category in CleanupCategory.values)
                      HomeCategoryCard(
                        category: category,
                        finding: snapshot.findings[category],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
