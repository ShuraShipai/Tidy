import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../models/video_record.dart';

class VideoLibraryService {
  const VideoLibraryService();

  static const MethodChannel _channel = MethodChannel('tidy/videos');

  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<VideoPreviewData> preview(String id) async {
    _requireIos();
    final value = await _channel.invokeMapMethod<Object?, Object?>('preview', {
      'id': id,
      'width': 480,
      'height': 480,
    });
    if (value == null) {
      throw const VideoLibraryException('Video preview is unavailable.');
    }
    return VideoPreviewData(
      thumbnailBytes: value['thumbnail'] as List<int>?,
      fileName: value['fileName'] as String?,
    );
  }

  Future<VideoDetails> details(String id) async {
    _requireIos();
    final value = await _channel.invokeMapMethod<Object?, Object?>('details', {
      'id': id,
    });
    if (value == null) {
      throw const VideoLibraryException('Video details are unavailable.');
    }
    return VideoDetails(
      fileName: value['fileName'] as String?,
      frameRate: (value['frameRate'] as num?)?.toDouble(),
    );
  }

  Future<void> playFullScreen(String id) async {
    _requireIos();
    await _channel.invokeMethod<void>('playFullScreen', {'id': id});
  }

  Future<VideoDeletionOutcome> delete(List<VideoRecord> selected) async {
    _requireIos();
    if (selected.isEmpty) {
      throw const VideoLibraryException('Select at least one video.');
    }
    final measuredBytes = {for (final video in selected) video.id: video.bytes};
    final value = await _channel.invokeMapMethod<Object?, Object?>('delete', {
      'records': [
        for (final video in selected)
          {
            'id': video.id,
            'createdAt': video.createdAt?.millisecondsSinceEpoch,
            'modifiedAt': video.modifiedAt?.millisecondsSinceEpoch,
            'width': video.width,
            'height': video.height,
            'duration': video.duration,
          },
      ],
    });
    if (value == null) {
      throw VideoLibraryException('Photos could not confirm the deletion.');
    }
    final requestedIds = measuredBytes.keys.toSet();
    final deleted = (value['deleted'] as List? ?? const [])
        .whereType<String>()
        .where(requestedIds.contains)
        .toSet();
    final remaining = requestedIds.difference(deleted);
    if (deleted.isEmpty && value['succeeded'] != true) {
      throw VideoLibraryException(
        value['error'] as String? ?? 'Photos could not confirm the deletion.',
      );
    }
    return VideoDeletionOutcome(
      deletedIds: Set.unmodifiable(deleted),
      remainingIds: Set.unmodifiable(remaining),
      estimatedBytes: deleted.fold<int>(
        0,
        (sum, id) => sum + (measuredBytes[id] ?? 0),
      ),
    );
  }

  void _requireIos() {
    if (!supported) {
      throw const VideoLibraryException(
        'Video library features require iOS Photos access.',
      );
    }
  }
}

class VideoLibraryException implements Exception {
  const VideoLibraryException(this.message);

  final String message;

  @override
  String toString() => message;
}

final videoLibraryServiceProvider = Provider<VideoLibraryService>(
  (ref) => const VideoLibraryService(),
);
