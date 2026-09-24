enum ScanPhase {
  idle,
  loading,
  scanning,
  success,
  empty,
  permissionDenied,
  cancelled,
  stale,
  error,
}

class MediaRecord {
  MediaRecord.fromMap(Map<Object?, Object?> map)
    : id = map['id']! as String,
      video = map['video']! as bool,
      screenshot = map['screenshot']! as bool,
      bytes = map['bytes'] as int?,
      width = map['width']! as int,
      height = map['height']! as int,
      duration = (map['duration']! as num).toDouble(),
      favorite = map['favorite']! as bool,
      createdAt = _date(map['createdAt']),
      modifiedAt = _date(map['modifiedAt']);
  final String id;
  final bool video, screenshot, favorite;
  final int? bytes;
  final int width, height;
  final double duration;
  final DateTime? createdAt, modifiedAt;
  // Product policy, not an iOS classification. Unknown-size videos are unclassified.
  bool get largeVideo => video && bytes != null && bytes! >= 100 * 1024 * 1024;
}

DateTime? _date(Object? value) => value == null
    ? null
    : DateTime.fromMillisecondsSinceEpoch((value as num).round());

class MatchGroup {
  MatchGroup(Iterable<String> ids, this.evidence) : ids = Set.unmodifiable(ids);
  final Set<String> ids;
  final String evidence;
}

class ScanState {
  const ScanState({
    this.phase = ScanPhase.idle,
    this.media = const [],
    this.similar = const [],
    this.contacts = const [],
    this.permissions = const {},
    this.capacity,
    this.free,
    this.used,
    this.completedAt,
    this.processed,
    this.total,
    this.stage,
    this.message,
    this.storageError,
    this.contactCount = 0,
    this.unavailableImages = 0,
  });
  final ScanPhase phase;
  final List<MediaRecord> media;
  final List<MatchGroup> similar, contacts;
  final Map<String, String> permissions;
  final int? capacity, free, used, processed, total;
  final int contactCount, unavailableImages;
  final DateTime? completedAt;
  final String? stage, message, storageError;
  bool get running => phase == ScanPhase.loading || phase == ScanPhase.scanning;
  bool get hasResults => phase == ScanPhase.success || phase == ScanPhase.empty;
  Set<String> get reviewableIds => {
    for (final group in similar) ...group.ids,
    for (final item in media)
      if (item.screenshot || item.largeVideo) item.id,
  };
  Iterable<MediaRecord> get reviewableMedia {
    final ids = reviewableIds;
    return media.where((item) => ids.contains(item.id));
  }

  int get knownReviewableBytes =>
      reviewableMedia.fold(0, (sum, item) => sum + (item.bytes ?? 0));
  int get unknownReviewableSizes =>
      reviewableMedia.where((item) => item.bytes == null).length;
  int get unavailableSizes => media.where((item) => item.bytes == null).length;
  bool get incomplete => unavailableSizes > 0 || unavailableImages > 0;
}
