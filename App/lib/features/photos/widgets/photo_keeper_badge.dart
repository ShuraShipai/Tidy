import 'package:flutter/material.dart';

import '../../../core/design/tidy_radii.dart';

class PhotoKeeperBadge extends StatelessWidget {
  const PhotoKeeperBadge({super.key});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFD7F1E6),
      borderRadius: BorderRadius.circular(TidyRadii.button),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Text(
        '✓ Suggested to keep',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF14674A),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
