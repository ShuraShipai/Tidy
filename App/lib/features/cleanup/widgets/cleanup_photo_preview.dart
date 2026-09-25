import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../photos/services/photo_library_service.dart';
import '../../scan/models/scan_state.dart';

class CleanupPhotoPreview extends ConsumerWidget {
  const CleanupPhotoPreview({required this.photo, super.key});

  final MediaRecord photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnail = ref.watch(photoThumbnailProvider(photo.id));
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: 48,
        child: thumbnail.when(
          data: (bytes) => bytes == null
              ? const ColoredBox(color: Color(0xFFEDE5F7))
              : Image.memory(bytes, fit: BoxFit.cover),
          error: (error, stackTrace) =>
              const ColoredBox(color: Color(0xFFEDE5F7)),
          loading: () => const ColoredBox(
            color: Color(0xFFEDE5F7),
            child: Center(
              child: SizedBox.square(
                dimension: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
