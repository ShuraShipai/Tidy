import 'package:flutter/material.dart';

import '../../../core/widgets/tidy_glyph.dart';

class PhotoViewerUnavailablePlaceholder extends StatelessWidget {
  const PhotoViewerUnavailablePlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: TidyGlyph(TidyGlyphName.photo, size: 42, color: Colors.white54),
  );
}
