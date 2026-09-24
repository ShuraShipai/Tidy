import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_shadows.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';
import '../../../core/widgets/tidy_clay_surface.dart';
import '../../scan/models/scan_snapshot.dart';

class HomeStorageCard extends StatelessWidget {
  const HomeStorageCard({
    required this.snapshot,
    required this.onScan,
    this.onReview,
    this.permissionUnavailable = false,
    super.key,
  });

  final ScanSnapshot snapshot;
  final VoidCallback onScan;
  final VoidCallback? onReview;
  final bool permissionUnavailable;

  String _size(int bytes) {
    final gb = bytes / 1000000000;
    return gb >= 1
        ? '${gb.toStringAsFixed(1)} GB'
        : '${(bytes / 1000000).toStringAsFixed(0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final storage = snapshot.storage;
    final used = storage == null
        ? null
        : storage.capacityBytes - storage.availableBytes;
    final ratio = storage == null || storage.capacityBytes <= 0
        ? null
        : (used! / storage.capacityBytes).clamp(0.0, 1.0);
    return TidyClaySurface(
      radius: TidyRadii.card,
      color: TidyColors.surface,
      shadows: TidyShadows.raised,
      child: Padding(
        padding: const EdgeInsets.all(TidySpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'iPhone Storage',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: TidySpacing.sm),
            if (storage != null && ratio != null) ...[
              Row(
                children: [
                  SizedBox(
                    width: 112,
                    height: 112,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size.square(112),
                          painter: _StorageRingPainter(ratio),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _size(used!),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'used',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: TidySpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _size(storage.availableBytes),
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 24),
                        ),
                        Text(
                          'Free space',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: TidySpacing.md),
                        Text(
                          '${_size(used)} used of ${_size(storage.capacityBytes)}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 34),
                child: Center(
                  child: Text(
                    permissionUnavailable
                        ? 'Read when you are'
                        : 'Storage information unavailable',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: TidyColors.secondaryText,
                    ),
                  ),
                ),
              ),
            const Divider(height: 28),
            Text(
              permissionUnavailable
                  ? 'Ready when you are'
                  : snapshot.phase == ScanPhase.complete
                  ? _reviewSummary(snapshot)
                  : 'Ready when you are',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: TidySpacing.sm),
            if (snapshot.phase != ScanPhase.complete && !permissionUnavailable)
              Padding(
                padding: const EdgeInsets.only(bottom: TidySpacing.sm),
                child: Text(
                  'Find a little breathing room.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: TidyColors.secondaryText,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TidyActionButton(
                    label: 'Review Cleanup',
                    onPressed: snapshot.hasFindings ? onReview : null,
                  ),
                ),
                const SizedBox(width: TidySpacing.xs),
                Expanded(
                  child: TidyActionButton(
                    label: 'Scan Again',
                    style: TidyActionStyle.quiet,
                    onPressed: onScan,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _reviewSummary(ScanSnapshot value) {
    if (!value.hasFindings) return 'Looking tidy';
    if (value.unknownReviewableSizes > 0) return 'Known size ready to review';
    final bytes = value.reviewableBytes;
    return bytes == null
        ? 'Items ready to review'
        : '${_size(bytes)} ready to review';
  }
}

class _StorageRingPainter extends CustomPainter {
  const _StorageRingPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    const stroke = 10.0;
    final ringRect = Rect.fromCircle(
      center: center,
      radius: size.width / 2 - stroke / 2,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = TidyColors.violetTint;
    canvas.drawArc(ringRect, 0, 6.283185307179586, false, track);
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..shader = const SweepGradient(
        colors: [TidyColors.lightViolet, TidyColors.primary, TidyColors.pink],
        stops: [0, .78, 1],
      ).createShader(ringRect);
    canvas.drawArc(
      ringRect,
      -1.570796326794897,
      6.283185307179586 * value,
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _StorageRingPainter oldDelegate) =>
      oldDelegate.value != value;
}
