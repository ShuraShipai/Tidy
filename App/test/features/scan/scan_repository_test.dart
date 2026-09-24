import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/features/scan/models/scan_state.dart';
import 'package:tidy/features/scan/repositories/scan_repository.dart';

// Synthetic records are test fixtures only; no fixture is bundled in the app.
Map<String, Object?> media(
  String id, {
  int? bytes,
  bool video = false,
  bool screenshot = false,
}) => {
  'id': id,
  'bytes': bytes,
  'video': video,
  'screenshot': screenshot,
  'width': 1200,
  'height': 800,
  'duration': 0.0,
  'favorite': false,
};
Map<String, Object?> result() => {
  'phase': 'success',
  'completedAt': 1000,
  'permissions': {'photos': 'authorized', 'contacts': 'authorized'},
  'media': <Object?>[],
  'similarPairs': <Object?>[],
  'contactMatches': <Object?>[],
};
void main() {
  test('only a completed check with no findings becomes empty', () {
    expect(ScanRepository.decode(result()).phase, ScanPhase.empty);
    for (final phase in [
      'loading',
      'scanning',
      'permissionDenied',
      'cancelled',
      'stale',
      'error',
    ]) {
      expect(ScanRepository.decode({'phase': phase}).phase.name, phase);
    }
  });
  test(
    'unknown bytes and unavailable comparisons never imply a clean library',
    () {
      final unknown = ScanRepository.decode({
        ...result(),
        'media': [media('cloud', video: true)],
      });
      expect(unknown.phase, ScanPhase.success);
      expect(unknown.incomplete, isTrue);
      expect(unknown.media.single.bytes, isNull);
      expect(unknown.media.single.largeVideo, isFalse);
      expect(
        ScanRepository.decode({...result(), 'unavailableImages': 1}).phase,
        ScanPhase.success,
      );
    },
  );
  test(
    'overlapping groups merge transitively; media totals count each ID once',
    () {
      final state = ScanRepository.decode({
        ...result(),
        'media': [
          media('a', bytes: 10, screenshot: true),
          media('b', bytes: 20),
          media('c'),
          media('d', bytes: 40),
        ],
        'similarPairs': [
          ['a', 'b'],
          ['c', 'd'],
          ['b', 'c'],
        ],
      });
      expect(state.similar.single.ids, {'a', 'b', 'c', 'd'});
      expect(state.reviewableIds.length, 4);
      expect(state.knownReviewableBytes, 70);
      expect(state.unknownReviewableSizes, 1);
      expect(
        () => state.similar.single.ids.add('selected'),
        throwsUnsupportedError,
      );
    },
  );
  test('contact components preserve distinct matching evidence', () {
    final state = ScanRepository.decode({
      ...result(),
      'contactMatches': [
        {
          'ids': ['a', 'b'],
          'evidence': 'Shared phone number',
        },
        {
          'ids': ['b', 'c'],
          'evidence': 'Shared email address',
        },
      ],
    });
    expect(state.contacts.single.ids, {'a', 'b', 'c'});
    expect(state.contacts.single.evidence, contains('Shared phone number'));
    expect(state.contacts.single.evidence, contains('Shared email address'));
    expect(state.reviewableIds, isEmpty);
  });
  test(
    'large video policy uses actual measured bytes and preserves metadata',
    () {
      final state = ScanRepository.decode({
        ...result(),
        'media': [
          {
            ...media('large', bytes: 100 * 1024 * 1024, video: true),
            'createdAt': 123000,
            'modifiedAt': 456000,
          },
          media('small', bytes: 100 * 1024 * 1024 - 1, video: true),
        ],
      });
      expect(state.reviewableIds, {'large'});
      expect(state.media.first.createdAt!.millisecondsSinceEpoch, 123000);
      expect(state.media.first.modifiedAt!.millisecondsSinceEpoch, 456000);
    },
  );
}
