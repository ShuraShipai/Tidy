import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../scan/models/scan_state.dart';
import '../models/video_record.dart';
import '../services/video_library_service.dart';

class VideoRepository {
  const VideoRepository(this.service);

  final VideoLibraryService service;

  List<VideoRecord> largeVideos(ScanState scan) => [
    for (final media in scan.media)
      if (media.video && media.largeVideo) VideoRecord.fromMedia(media),
  ];

  List<VideoRecord> sorted(ScanState scan, VideoSortOrder order) {
    final videos = largeVideos(scan);
    int byDate(VideoRecord a, VideoRecord b, {required bool descending}) {
      final left = a.createdAt;
      final right = b.createdAt;
      if (left == null && right == null) return a.id.compareTo(b.id);
      if (left == null) return 1;
      if (right == null) return -1;
      final comparison = left.compareTo(right);
      return descending ? -comparison : comparison;
    }

    videos.sort((a, b) {
      final comparison = switch (order) {
        VideoSortOrder.largest => b.bytes.compareTo(a.bytes),
        VideoSortOrder.newest => byDate(a, b, descending: true),
        VideoSortOrder.oldest => byDate(a, b, descending: false),
      };
      return comparison == 0 ? a.id.compareTo(b.id) : comparison;
    });
    return List.unmodifiable(videos);
  }

  Future<VideoPreviewData> preview(String id) => service.preview(id);

  Future<VideoDetails> details(String id) => service.details(id);

  Future<void> playFullScreen(String id) => service.playFullScreen(id);

  Future<VideoDeletionOutcome> delete(List<VideoRecord> selected) {
    return service.delete(selected);
  }
}

final videoRepositoryProvider = Provider<VideoRepository>(
  (ref) => VideoRepository(ref.watch(videoLibraryServiceProvider)),
);
