import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_sizes.dart';

class SettingsPageTopBar extends StatelessWidget {
  const SettingsPageTopBar({required this.backLabel, super.key});

  final String backLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/settings');
          }
        },
        icon: const Icon(Icons.chevron_left, size: TidySizes.backIcon),
        label: Text(backLabel),
        style: TextButton.styleFrom(
          foregroundColor: TidyColors.primary,
          padding: EdgeInsets.zero,
          minimumSize: const Size(44, 44),
        ),
      ),
    ),
  );
}
