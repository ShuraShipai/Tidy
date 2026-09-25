import 'package:flutter/material.dart';

class SuggestedKeeperBadge extends StatelessWidget {
  const SuggestedKeeperBadge({super.key});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFD7F1E6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          '✓ Suggested to Keep',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF14674A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}
