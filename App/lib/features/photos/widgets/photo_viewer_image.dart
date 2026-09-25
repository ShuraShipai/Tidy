import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/tidy_colors.dart';
import '../services/photo_library_service.dart';
import 'photo_viewer_unavailable_placeholder.dart';

class PhotoViewerImage extends ConsumerWidget {
  const PhotoViewerImage({required this.assetId, super.key});

  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(photoViewerImageProvider(assetId));
    return image.when(
      data: (bytes) => bytes == null
          ? const PhotoViewerUnavailablePlaceholder()
          : Image.memory(
              bytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const PhotoViewerUnavailablePlaceholder(),
            ),
      error: (error, stackTrace) => const PhotoViewerUnavailablePlaceholder(),
      loading: () => const Center(
        child: CircularProgressIndicator(color: TidyColors.lightViolet),
      ),
    );
  }
}
