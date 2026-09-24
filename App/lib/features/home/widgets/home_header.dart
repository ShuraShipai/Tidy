import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_spacing.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.onHistory,
    this.showTitle = true,
    this.showHistory = true,
    this.compact = false,
    super.key,
  });

  final VoidCallback? onHistory;
  final bool showTitle;
  final bool showHistory;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (showTitle)
        Row(
          children: [
            Expanded(
              child: Text(
                'Storage',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            if (showHistory)
              IconButton(
                onPressed: onHistory,
                icon: const Icon(Icons.history_rounded),
                tooltip: 'Cleanup history',
              ),
          ],
        ),
      SizedBox(
        height: compact
            ? 42
            : showTitle
            ? TidySpacing.sm
            : 0,
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          color: TidyColors.violetTint,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 13,
                color: TidyColors.violetDeep,
              ),
              const SizedBox(width: 5),
              Text(
                'Analyzed on device',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: TidyColors.violetDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
