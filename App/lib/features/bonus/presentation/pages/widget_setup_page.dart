import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_spacing.dart';
import '../../../../core/widgets/tidy_action_button.dart';
import '../../../scan/controllers/scan_snapshot_provider.dart';
import '../../../scan/models/scan_snapshot.dart';
import '../../services/group_eight_service.dart';
import '../../widgets/bonus_page_frame.dart';

class WidgetSetupPage extends ConsumerStatefulWidget {
  const WidgetSetupPage({super.key});

  @override
  ConsumerState<WidgetSetupPage> createState() => _WidgetSetupPageState();
}

class _WidgetSetupPageState extends ConsumerState<WidgetSetupPage> {
  bool _busy = false;
  String? _message;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(scanSnapshotProvider);
    final storage = summary.storage;
    final ready = summary.phase == ScanPhase.complete && storage != null;
    final used = storage == null
        ? null
        : storage.capacityBytes - storage.availableBytes;
    return BonusPageFrame(
      title: 'A little space.\nAt a glance.',
      subtitle: 'Add a Tidy storage widget to your Home Screen.',
      backLabel: 'Optional Features',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!ready)
            TidyActionButton(
              label: _busy ? 'Updating…' : 'Open Scan',
              onPressed: _busy || summary.phase == ScanPhase.scanning
                  ? null
                  : () => context.push('/scan?start=true'),
            )
          else
            TidyActionButton(
              label: _busy ? 'Updating…' : 'Update Widget Summary',
              onPressed: _busy ? null : () => _publish(summary),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('SMALL', style: TextStyle(letterSpacing: 1.1)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(TidySpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.storage_outlined),
                      SizedBox(width: TidySpacing.xs),
                      Text('Storage'),
                    ],
                  ),
                  const SizedBox(height: TidySpacing.sm),
                  Text(
                    used == null
                        ? 'Storage unavailable'
                        : '${_gb(used)} GB used',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (storage != null)
                    Text('of ${_gb(storage.capacityBytes)} GB'),
                  const SizedBox(height: TidySpacing.xs),
                  Text(ready ? _reviewable(summary) : _freshness(summary)),
                  if (summary.lastScanned != null)
                    Text(
                      'Updated ${_date(summary.lastScanned!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TidySpacing.lg),
          const Text('MEDIUM', style: TextStyle(letterSpacing: 1.1)),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(TidySpacing.md),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 96,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: storage == null || storage.capacityBytes <= 0
                              ? null
                              : used! / storage.capacityBytes,
                          strokeWidth: 9,
                        ),
                        Text(used == null ? '—' : _gb(used)),
                      ],
                    ),
                  ),
                  const SizedBox(width: TidySpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Storage',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          storage == null
                              ? 'Available space unavailable'
                              : '${_gb(storage.availableBytes)} GB free',
                        ),
                        Text(
                          ready ? _reviewable(summary) : _freshness(summary),
                        ),
                        if (summary.lastScanned != null)
                          Text(
                            'Updated ${_date(summary.lastScanned!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TidySpacing.lg),
          const Text(
            'After updating, touch and hold your Home Screen, tap Edit, then Add Widget and search for Tidy.',
          ),
          if (_message != null) Text(_message!),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }

  Future<void> _publish(ScanSnapshot snapshot) async {
    final storage = snapshot.storage;
    if (storage == null) return;
    setState(() {
      _busy = true;
      _message = null;
      _error = null;
    });
    try {
      await ref.read(groupEightServiceProvider).updateWidgetSummary({
        'capacityBytes': storage.capacityBytes,
        'availableBytes': storage.availableBytes,
        'usedBytes': (storage.capacityBytes - storage.availableBytes).clamp(
          0,
          storage.capacityBytes,
        ),
        'reviewableBytes': snapshot.unknownReviewableSizes > 0
            ? null
            : snapshot.reviewableBytes,
        'unknownReviewableSizes': snapshot.unknownReviewableSizes,
        'scannedAt': snapshot.lastScanned?.millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      if (mounted) {
        setState(
          () => _message =
              'Widget summary updated. Add the Tidy widget from your Home Screen to view it.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Widget summary could not be updated: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _reviewable(ScanSnapshot state) =>
      state.unknownReviewableSizes > 0 || state.reviewableBytes == null
      ? 'Reviewable size unavailable'
      : '${_gb(state.reviewableBytes!)} GB ready to review';

  String _freshness(ScanSnapshot state) => switch (state.phase) {
    ScanPhase.notScanned => 'Scan to see a real library summary',
    ScanPhase.scanning => 'Library scan is in progress',
    ScanPhase.noAccess => 'Library access is not available',
    ScanPhase.failed => 'Scan needs to be refreshed',
    ScanPhase.complete => 'Storage reading unavailable',
  };

  static String _gb(int bytes) =>
      (bytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
  static String _date(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}
