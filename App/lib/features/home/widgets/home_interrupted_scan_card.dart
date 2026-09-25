import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_radii.dart';
import '../../../core/design/tidy_shadows.dart';
import '../../../core/widgets/tidy_clay_surface.dart';

class HomeInterruptedScanCard extends StatelessWidget {
  const HomeInterruptedScanCard({required this.hasResults, super.key});

  final bool hasResults;

  @override
  Widget build(BuildContext context) => TidyClaySurface(
    radius: TidyRadii.card,
    color: TidyColors.surface,
    shadows: TidyShadows.raised,
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(TidyRadii.card),
      child: ListTile(
        leading: const Icon(Icons.info_outline, color: TidyColors.amber),
        title: const Text('Scan interrupted'),
        subtitle: Text(
          hasResults
              ? 'Your last completed results are still available.'
              : 'The scan stopped before results were completed.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/scan/interrupted'),
      ),
    ),
  );
}
