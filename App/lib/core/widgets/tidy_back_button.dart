import 'package:flutter/material.dart';

import '../design/tidy_colors.dart';

/// A compact chevron control for returning from a pushed screen.
class TidyBackButton extends StatelessWidget {
  const TidyBackButton({
    required this.onPressed,
    required this.tooltip,
    this.color = TidyColors.primary,
    super.key,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    padding: EdgeInsets.zero,
    color: color,
    icon: const Icon(Icons.chevron_left, size: 24),
  );
}
