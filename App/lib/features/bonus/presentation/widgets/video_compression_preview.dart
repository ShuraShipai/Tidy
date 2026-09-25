import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/design/tidy_radii.dart';
import '../../../../core/design/tidy_spacing.dart';

class VideoCompressionPreview extends StatelessWidget {
  const VideoCompressionPreview({
    required this.aspectRatio,
    required this.preview,
    required this.onPlay,
    super.key,
  });

  final double aspectRatio;
  final Future<Uint8List?> preview;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 150, maxHeight: 84),
    child: AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TidyRadii.thumbnail),
        child: Material(
          color: Colors.black,
          child: InkWell(
            onTap: onPlay,
            child: Semantics(
              button: true,
              label: 'Play video full screen',
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  FutureBuilder<Uint8List?>(
                    future: preview,
                    builder: (context, snapshot) {
                      final bytes = snapshot.data;
                      if (bytes == null) {
                        return const Center(
                          child: Icon(
                            Icons.video_file_outlined,
                            color: Colors.white70,
                          ),
                        );
                      }
                      return Image.memory(bytes, fit: BoxFit.contain);
                    },
                  ),
                  const IgnorePointer(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 38,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: TidySpacing.xs,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
