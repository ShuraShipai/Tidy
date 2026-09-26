import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_page_background.dart';
import '../../../scan/controllers/scan_controller.dart';
import '../../../scan/controllers/scan_snapshot_provider.dart';
import '../../../scan/models/scan_snapshot.dart';
import '../../../scan/models/scan_state.dart' as scan_data;
import '../../../bonus/services/group_eight_service.dart';
import '../../widgets/home_header.dart';
import '../../widgets/home_storage_card.dart';
import '../../widgets/home_scan_banner.dart';
import '../../widgets/home_category_card.dart';
import '../../widgets/home_empty_state.dart';
import '../../widgets/home_access_card.dart';
import '../../widgets/home_interrupted_scan_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  ProviderSubscription<ScanSnapshot>? _widgetSummarySubscription;
  String? _lastPublishedSummary;

  @override
  void initState() {
    super.initState();
    _widgetSummarySubscription = ref.listenManual(
      scanSnapshotProvider,
      (previous, next) => _syncWidgetSummary(next),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _widgetSummarySubscription?.close();
    super.dispose();
  }

  void _syncWidgetSummary(ScanSnapshot snapshot) {
    final storage = snapshot.storage;
    final scannedAt = snapshot.lastScanned;
    if (snapshot.phase != ScanPhase.complete ||
        storage == null ||
        scannedAt == null) {
      return;
    }
    final bytes = snapshot.unknownReviewableSizes > 0
        ? null
        : snapshot.reviewableBytes;
    final key = [
      storage.capacityBytes,
      storage.availableBytes,
      bytes,
      snapshot.unknownReviewableSizes,
      scannedAt.millisecondsSinceEpoch,
    ].join(':');
    if (_lastPublishedSummary == key) return;
    _lastPublishedSummary = key;
    unawaited(_publishWidgetSummary(snapshot, key));
  }

  Future<void> _publishWidgetSummary(ScanSnapshot snapshot, String key) async {
    final storage = snapshot.storage!;
    try {
      await ref.read(groupEightServiceProvider).updateWidgetSummary({
        'capacityBytes': storage.capacityBytes,
        'availableBytes': storage.availableBytes,
        'reviewableBytes': snapshot.unknownReviewableSizes > 0
            ? null
            : snapshot.reviewableBytes,
        'scannedAt': snapshot.lastScanned!.millisecondsSinceEpoch,
      });
    } catch (_) {
      if (_lastPublishedSummary == key) _lastPublishedSummary = null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              if (state.phase == scan_data.ScanPhase.cancelled) ...[
                HomeInterruptedScanCard(hasResults: state.hasResults),
                const SizedBox(height: TidySpacing.md),
              ],
              if (showEmpty)
                HomeEmptyState(snapshot: snapshot, onScan: scan)
              else ...[
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
                  onReview: () => context.push('/cleanup/review'),
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
                        onTap: () => context.go(switch (category) {
                          CleanupCategory.similarPhotos => '/photos/similar',
                          CleanupCategory.screenshots => '/photos/screenshots',
                          CleanupCategory.largeVideos => '/videos',
                          CleanupCategory.duplicateContacts => '/contacts',
                        }),
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
