import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/tidy_colors.dart';
import '../design/tidy_radii.dart';
import '../design/tidy_sizes.dart';
import '../design/tidy_shadows.dart';
import 'tidy_glyph.dart';
import 'tidy_clay_surface.dart';

enum TidyOrbTone { violet, pink, sky, green, amber }

class TidyOrb extends StatelessWidget {
  const TidyOrb({
    required this.glyph,
    this.tone = TidyOrbTone.violet,
    this.size = TidySizes.illustrationOrb,
    super.key,
  });

  final TidyGlyphName glyph;
  final TidyOrbTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (Color light, Color mid, Color deep) = switch (tone) {
      TidyOrbTone.violet => (
        TidyColors.orbVioletLight,
        TidyColors.orbVioletMid,
        TidyColors.primary,
      ),
      TidyOrbTone.pink => (
        TidyColors.orbPinkLight,
        TidyColors.orbPinkMid,
        TidyColors.pink,
      ),
      TidyOrbTone.sky => (
        TidyColors.orbSkyLight,
        TidyColors.orbSkyMid,
        TidyColors.orbSkyDeep,
      ),
      TidyOrbTone.green => (
        TidyColors.orbGreenLight,
        TidyColors.orbGreenMid,
        TidyColors.emerald,
      ),
      TidyOrbTone.amber => (
        TidyColors.orbAmberLight,
        TidyColors.orbAmberMid,
        TidyColors.orbAmberDeep,
      ),
    };

    return ExcludeSemantics(
      child: Transform.rotate(
        angle: -7 * math.pi / 180,
        child: TidyClaySurface(
          radius: size >= TidySizes.illustrationOrb
              ? TidyRadii.illustration
              : size * TidySizes.orbRadiusRatio,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const <double>[0, 0.55, 1],
            colors: <Color>[light, mid, Color.lerp(mid, deep, 0.56)!],
          ),
          shadows: TidyShadows.orb,
          child: SizedBox(
            width: size,
            height: size * TidySizes.orbAspectRatio,
            child: Center(
              child: TidyGlyph(
                glyph,
                size: size * TidySizes.orbIconRatio,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
