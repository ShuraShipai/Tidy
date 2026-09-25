import 'package:flutter/material.dart';

import '../../../core/design/tidy_spacing.dart';

class SettingsDoneButton extends StatelessWidget {
  const SettingsDoneButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TidySpacing.lg,
      TidySpacing.sm,
      TidySpacing.lg,
      TidySpacing.md,
    ),
    child: SizedBox(
      width: double.infinity,
      child: FilledButton(onPressed: onPressed, child: const Text('Done')),
    ),
  );
}
