import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/features/photos/models/photo_group.dart';
import 'package:tidy/features/photos/repositories/photo_group_repository.dart';
import 'package:tidy/features/scan/models/scan_state.dart';

MediaRecord _photo(
  String id, {
  required String hash,
  required int bytes,
  required int width,
  int? createdAt,
  bool screenshot = false,
}) => MediaRecord.fromMap({
  'id': id,
  'video': false,
  'screenshot': screenshot,
  'bytes': bytes,
  'contentHash': hash,
  'width': width,
  'height': width,
  'duration': 0,
  'favorite': false,
  'createdAt': createdAt ?? DateTime(2025, 2, 3).millisecondsSinceEpoch,
});

void main() {
  const repository = PhotoGroupRepository();

  test('discovery reports real duplicate and similar group membership', () {
    final first = _photo(
      'asset-a',
      hash: 'same-bytes',
      bytes: 1800,
      width: 2000,
    );
    final second = _photo(
      'asset-b',
      hash: 'same-bytes',
      bytes: 1800,
      width: 2000,
    );
    final third = _photo(
      'asset-c',
      hash: 'different-bytes',
      bytes: 2200,
      width: 2400,
    );
    final scan = ScanState(
      phase: ScanPhase.success,
      media: [first, second, third],
      similar: [
        MatchGroup(['asset-a', 'asset-b', 'asset-c'], 'visual match'),
      ],
    );

    final exact = repository.groupsForFilter(
      scan,
      SimilarPhotoFilter.duplicates,
    );
    final similar = repository.groupsForFilter(
      scan,
      SimilarPhotoFilter.similar,
    );
    final allPhotos = repository.uniqueSimilarPhotos(scan);

    expect(exact, hasLength(1));
    expect(exact.single.items.map((item) => item.id).toSet(), {
      'asset-a',
      'asset-b',
    });
    expect(similar, hasLength(1));
    expect(similar.single.items, hasLength(3));
    expect(allPhotos.map((item) => item.id).toSet(), {
      'asset-a',
      'asset-b',
      'asset-c',
    });
  });

  test('Swipe Clean photos are ordered newest capture date first', () {
    final older = _photo(
      'older',
      hash: 'older-hash',
      bytes: 100,
      width: 100,
      createdAt: 100,
    );
    final newer = _photo(
      'newer',
      hash: 'newer-hash',
      bytes: 100,
      width: 100,
      createdAt: 300,
    );
    final unknownDate = MediaRecord.fromMap({
      'id': 'unknown',
      'video': false,
      'screenshot': false,
      'bytes': 100,
      'width': 100,
      'height': 100,
      'duration': 0,
      'favorite': false,
    });
    final video = MediaRecord.fromMap({
      'id': 'video',
      'video': true,
      'screenshot': false,
      'bytes': 100,
      'width': 100,
      'height': 100,
      'duration': 1,
      'favorite': false,
      'createdAt': 500,
    });

    final scan = ScanState(
      phase: ScanPhase.success,
      media: [older, unknownDate, video, newer],
    );

    expect(
      repository.photos(scan).map((photo) => photo.id),
      ['newer', 'older', 'unknown'],
    );
  });

  test(
    'screenshots are measured separately and never included as similar photos',
    () {
      final screenshot = _photo(
        'asset-screen',
        hash: 'screen-hash',
        bytes: 500,
        width: 1000,
        screenshot: true,
      );
      final scan = ScanState(phase: ScanPhase.success, media: [screenshot]);

      expect(repository.screenshots(scan), [screenshot]);
      expect(repository.uniqueSimilarPhotos(scan), isEmpty);
    },
  );
}
