import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/widgets/tidy_back_button.dart';

class OnboardingBackButton extends StatelessWidget {
  const OnboardingBackButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TidyBackButton(
    onPressed: onPressed,
    tooltip: 'Back',
    color: TidyColors.primary,
  );
}
