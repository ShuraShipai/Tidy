import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/widgets/tidy_back_button.dart';

class PhotoPageTopBar extends StatelessWidget {
  const PhotoPageTopBar({
    required this.backLabel,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String backLabel;
  final String? actionLabel;
  final VoidCallback? onAction;

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }

    // Photo screens are pushed above the tab shell. When opened directly (or
    // after the route stack has been replaced), Navigator.maybePop can consume
    // the tap without returning to the Photos branch.
    context.go(backLabel == 'Similar Photos' ? '/photos/similar' : '/photos');
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      children: [
        TidyBackButton(
          onPressed: () => _goBack(context),
          tooltip: backLabel == 'Back' ? 'Back' : 'Back to $backLabel',
          color: TidyColors.primary,
        ),
        const Spacer(),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: TidyColors.primary,
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
            ),
            child: Text(actionLabel!),
          ),
      ],
    ),
  );
}
