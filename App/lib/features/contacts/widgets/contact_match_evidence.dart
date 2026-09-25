import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';

class ContactMatchEvidence extends StatelessWidget {
  const ContactMatchEvidence({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: TidyColors.orbGreenLight,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: TidyColors.violetDeep),
    ),
  );
}
