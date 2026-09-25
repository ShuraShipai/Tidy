import '../../scan/models/scan_state.dart';

enum VideoSortOrder { largest, newest, oldest }

extension VideoSortOrderLabel on VideoSortOrder {
  String get label => switch (this) {
    VideoSortOrder.largest => 'Largest',
    VideoSortOrder.newest => 'Newest',
    VideoSortOrder.oldest => 'Oldest',
  };
}

/// A video that the real scan classified as large from a measured resource.
/// Unknown-size videos remain visible as an incomplete-scan count, not a
/// fabricated large-video finding.
class VideoRecord {
  const VideoRecord({
    required this.id,
    required this.bytes,
    required this.width,
    required this.height,
    required this.duration,
    this.createdAt,
    this.modifiedAt,
  });

  factory VideoRecord.fromMedia(MediaRecord media) => VideoRecord(
    id: media.id,
    bytes: media.bytes!,
    width: media.width,
    height: media.height,
    duration: media.duration,
    createdAt: media.createdAt,
    modifiedAt: media.modifiedAt,
  );

  final String id;
  final int bytes;
  final int width;
  final int height;
  final double duration;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  String get resolutionLabel {
    final largerSide = width > height ? width : height;
    if (largerSide >= 3800) return '4K';
    if (largerSide >= 2500) return 'QHD';
    if (largerSide >= 1900) return '1080p';
    return '$width × $height';
  }

  String get durationLabel {
    final totalSeconds = duration.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get sizeLabel {
    if (bytes >= 1000000000) {
      return '${(bytes / 1000000000).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1000000) {
      return '${(bytes / 1000000).round()} MB';
    }
    return '${(bytes / 1000).round()} KB';
  }
}

class VideoPreviewData {
  const VideoPreviewData({this.thumbnailBytes, this.fileName});

  final List<int>? thumbnailBytes;
  final String? fileName;
}

class VideoDetails {
  const VideoDetails({this.fileName, this.frameRate});

  final String? fileName;
  final double? frameRate;
}

class VideoDeletionOutcome {
  const VideoDeletionOutcome({
    required this.deletedIds,
    required this.remainingIds,
    required this.estimatedBytes,
  });

  final Set<String> deletedIds;
  final Set<String> remainingIds;
  final int estimatedBytes;
}
