import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/video_record.dart';

/// A bounded, non-playing preview used on the video detail screen.
class VideoDetailPreview extends StatelessWidget {
  const VideoDetailPreview({
    required this.preview,
    required this.onPlay,
    super.key,
  });

  final Future<VideoPreviewData?> preview;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 200,
    width: double.infinity,
    child: Material(
      color: const Color(0xFF1F1C27),
      child: InkWell(
        onTap: onPlay,
        child: Semantics(
          button: true,
          label: 'Play video full screen',
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: FutureBuilder<VideoPreviewData?>(
                  future: preview,
                  builder: (context, snapshot) {
                    final bytes = snapshot.data?.thumbnailBytes;
                    if (bytes != null) {
                      return Image.memory(
                        Uint8List.fromList(bytes),
                        fit: BoxFit.contain,
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Icon(
                          Icons.videocam_off_outlined,
                          color: Colors.white70,
                          size: 44,
                        ),
                      );
                    }
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    );
                  },
                ),
              ),
              const IgnorePointer(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 56,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
