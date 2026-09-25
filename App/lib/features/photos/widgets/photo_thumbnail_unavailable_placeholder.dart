import 'package:flutter/material.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/widgets/tidy_glyph.dart';

class PhotoThumbnailUnavailablePlaceholder extends StatelessWidget {
  const PhotoThumbnailUnavailablePlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: TidyGlyph(
      TidyGlyphName.photo,
      size: 30,
      color: TidyColors.violetDeep,
    ),
  );
}
