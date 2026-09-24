import 'package:flutter/material.dart';

import '../design/tidy_colors.dart';
import '../design/tidy_radii.dart';
import '../design/tidy_sizes.dart';
import '../design/tidy_spacing.dart';
import '../design/tidy_shadows.dart';
import '../design/tidy_motion.dart';
import 'tidy_clay_surface.dart';

enum TidyActionStyle { primary, secondary, quiet }

class TidyActionButton extends StatefulWidget {
  const TidyActionButton({
    required this.label,
    required this.onPressed,
    this.style = TidyActionStyle.primary,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final TidyActionStyle style;

  @override
  State<TidyActionButton> createState() => _TidyActionButtonState();
}

class _TidyActionButtonState extends State<TidyActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool quiet = widget.style == TidyActionStyle.quiet;
    final BorderRadius borderRadius = BorderRadius.circular(TidyRadii.button);
    final Color foreground = switch (widget.style) {
      TidyActionStyle.primary => Colors.white,
      TidyActionStyle.secondary => TidyColors.violetDeep,
      TidyActionStyle.quiet => TidyColors.secondaryText,
    };

    final control = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onPressed,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        borderRadius: borderRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: TidySizes.actionHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TidySpacing.sm,
                vertical: TidySpacing.actionTop,
              ),
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontSize: TidySizes.actionText,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return AnimatedScale(
      scale: _pressed ? TidyMotion.pressScale : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : TidyMotion.pressDuration,
      curve: TidyMotion.pressCurve,
      child: SizedBox(
        width: double.infinity,
        child: quiet
            ? control
            : TidyClaySurface(
                radius: TidyRadii.button,
                color: TidyColors.buttonSecondary,
                gradient: widget.style == TidyActionStyle.primary
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          TidyColors.lightViolet,
                          TidyColors.primary,
                        ],
                      )
                    : null,
                shadows: TidyShadows.action,
                child: control,
              ),
      ),
    );
  }
}
