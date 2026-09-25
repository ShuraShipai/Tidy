import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tidy_colors.dart';
import '../../../core/widgets/tidy_glyph.dart';
import '../services/photo_library_service.dart';

class PhotoViewerImage extends ConsumerWidget {
  const PhotoViewerImage({required this.assetId, super.key});

  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(photoViewerImageProvider(assetId));
    return image.when(
      data: (bytes) => bytes == null
          ? const _UnavailablePhoto()
          : Image.memory(
              bytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const _UnavailablePhoto(),
            ),
      error: (error, stackTrace) => const _UnavailablePhoto(),
      loading: () => const Center(
        child: CircularProgressIndicator(color: TidyColors.lightViolet),
      ),
    );
  }
}

class _UnavailablePhoto extends StatelessWidget {
  const _UnavailablePhoto();

  @override
  Widget build(BuildContext context) => const Center(
    child: TidyGlyph(TidyGlyphName.photo, size: 42, color: Colors.white54),
  );
}
