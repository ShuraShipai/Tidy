import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/widgets/tidy_back_button.dart';

class SettingsPageTopBar extends StatelessWidget {
  const SettingsPageTopBar({required this.backLabel, super.key});

  final String backLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Align(
      alignment: Alignment.centerLeft,
      child: TidyBackButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/settings');
          }
        },
        tooltip: backLabel == 'Back' ? 'Back' : 'Back to $backLabel',
        color: TidyColors.primary,
      ),
    ),
  );
}
