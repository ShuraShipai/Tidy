import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_sizes.dart';
import '../../../core/design/tidy_spacing.dart';
import '../../../core/widgets/tidy_glyph.dart';
import '../../../core/widgets/tidy_orb.dart';

class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    required this.glyph,
    this.tone = TidyOrbTone.violet,
    this.showCompanions = false,
    super.key,
  });

  final TidyGlyphName glyph;
  final TidyOrbTone tone;
  final bool showCompanions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: TidySizes.illustrationHeight,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            bottom: TidySpacing.illustrationShadowBottom,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: TidySizes.illustrationShadowBlur,
                sigmaY: TidySizes.illustrationShadowBlur,
              ),
              child: Container(
                width: TidySizes.illustrationShadowWidth,
                height: TidySizes.illustrationShadowHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    TidySizes.illustrationShadowRadius,
                  ),
                  color: TidyColors.orbShadow,
                ),
              ),
            ),
          ),
          TidyOrb(glyph: glyph, tone: tone),
          if (showCompanions) ...<Widget>[
            const Positioned(
              right: TidySpacing.companionVideoRight,
              top: TidySpacing.companionVideoTop,
              child: TidyOrb(
                glyph: TidyGlyphName.video,
                tone: TidyOrbTone.pink,
                size: TidySizes.companionOrb,
              ),
            ),
            const Positioned(
              left: TidySpacing.companionPhotoLeft,
              top: TidySpacing.companionPhotoTop,
              child: TidyOrb(
                glyph: TidyGlyphName.photo,
                tone: TidyOrbTone.sky,
                size: TidySizes.companionOrb,
              ),
            ),
          ],
          const Positioned(
            right: TidySpacing.illustrationSparkRight,
            bottom: TidySpacing.illustrationSparkBottom,
            child: TidyGlyph(
              TidyGlyphName.spark,
              size: TidySizes.sparkIcon,
              color: TidyColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
