import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/design/tidy_sizes.dart';
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
            bottom: 14,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 210,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  color: TidyColors.orbShadow,
                ),
              ),
            ),
          ),
          TidyOrb(glyph: glyph, tone: tone),
          if (showCompanions) ...<Widget>[
            const Positioned(
              right: 20,
              top: 55,
              child: TidyOrb(
                glyph: TidyGlyphName.video,
                tone: TidyOrbTone.pink,
                size: 64,
              ),
            ),
            const Positioned(
              left: 21,
              top: 145,
              child: TidyOrb(
                glyph: TidyGlyphName.photo,
                tone: TidyOrbTone.sky,
                size: 64,
              ),
            ),
          ],
          const Positioned(
            right: 59,
            bottom: 36,
            child: TidyGlyph(
              TidyGlyphName.spark,
              size: 30,
              color: TidyColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
