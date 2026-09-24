import 'package:flutter/cupertino.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_sizes.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_glyph.dart';

class OnboardingBackButton extends StatelessWidget {
  const OnboardingBackButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.only(left: TidySpacing.md),
    minimumSize: const Size(TidySizes.touchTarget, TidySizes.touchTarget),
    onPressed: onPressed,
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TidyGlyph(
          TidyGlyphName.back,
          size: TidySizes.backIcon,
          color: TidyColors.primary,
        ),
        Text(
          'Back',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontSize: TidySizes.actionText,
            color: TidyColors.primary,
          ),
        ),
      ],
    ),
  );
}
