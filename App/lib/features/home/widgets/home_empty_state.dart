import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_shadows.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_action_button.dart';
import '../../../core/widgets/tidy_clay_surface.dart';
import '../../../core/widgets/tidy_glyph.dart';
import '../../../core/widgets/tidy_orb.dart';
import '../../scan/models/scan_snapshot.dart';

class HomeEmptyState extends StatelessWidget {
  const HomeEmptyState({
    required this.snapshot,
    required this.onScan,
    super.key,
  });

  final ScanSnapshot snapshot;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final clean = snapshot.phase == ScanPhase.complete;
    final title = clean ? 'Looking tidy' : 'Ready when you are';
    final message = clean
        ? 'Nothing significant to clean right now.'
        : 'Scan your library to see what may need a closer look.';
    return Column(
      children: [
        const SizedBox(height: 54),
        SizedBox(
          height: 155,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const TidyOrb(
                glyph: TidyGlyphName.storage,
                tone: TidyOrbTone.green,
                size: 140,
              ),
              const Positioned(
                right: 40,
                bottom: 3,
                child: TidyGlyph(
                  TidyGlyphName.spark,
                  size: 26,
                  color: TidyColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 56),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: TidySpacing.md),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: TidyColors.secondaryText),
        ),
        if (clean && snapshot.lastScanned != null) ...[
          const SizedBox(height: TidySpacing.lg),
          TidyClaySurface(
            radius: TidyRadii.card,
            color: TidyColors.surface,
            shadows: TidyShadows.raised,
            child: Padding(
              padding: const EdgeInsets.all(TidySpacing.lg),
              child: Column(
                children: [
                  Text(
                    'Last scanned',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: TidySpacing.xs),
                  Text(
                    '${MaterialLocalizations.of(context).formatMediumDate(snapshot.lastScanned!)}, ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(snapshot.lastScanned!))}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 42),
        TidyActionButton(
          label: clean ? 'Scan Again' : 'Scan Library',
          onPressed: onScan,
        ),
      ],
    );
  }
}
