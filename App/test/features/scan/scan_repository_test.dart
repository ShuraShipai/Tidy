import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/features/scan/models/scan_state.dart';
import 'package:tidy/features/scan/repositories/scan_repository.dart';
import 'package:tidy/features/scan/services/library_scan_service.dart';

class _StatusService extends LibraryScanService {
  Map<Object?, Object?> response = result();
  int serial = 0;
  bool fail = false;
  int starts = 0;

  @override
  Future<Map<Object?, Object?>> status([int? previousSerial]) async {
    if (fail) throw StateError('temporary status failure');
    return {...response, 'serial': ++serial};
  }

  @override
  Future<void> start() async {
    starts++;
  }

  @override
  Future<void> applyDeleted(Set<String> ids) async {
    response = {
      ...response,
      'media': (response['media'] as List? ?? [])
          .where((item) => !ids.contains((item as Map)['id']))
          .toList(),
      'similarPairs': (response['similarPairs'] as List? ?? [])
          .where((pair) => !(pair as List).any(ids.contains))
          .toList(),
    };
  }
}

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
  test('completed findings survive idle and transient status reads', () async {
    final service = _StatusService();
    final repository = ScanRepository(service);

    final completed = await repository.read();
    service.response = {'phase': 'idle'};
    final retained = await repository.read();
    expect(retained.phase, ScanPhase.idle);
    expect(retained.completedAt, completed.completedAt);
    expect(retained.hasResults, isTrue);

    service.fail = true;
    await expectLater(repository.read(), throwsStateError);
    expect(identical(repository.lastCompleted, completed), isTrue);
  });

  test('an interrupted rescan keeps the last successful findings', () async {
    final service = _StatusService();
    service.response = {
      ...result(),
      'media': [media('kept', bytes: 42, screenshot: true)],
    };
    final repository = ScanRepository(service);
    final completed = await repository.read();
    await repository.start();
    service.response = {'phase': 'scanning', 'processed': 2, 'total': 5};
    final running = await repository.read();
    expect(running.phase, ScanPhase.scanning);
    expect(running.media.single.id, 'kept');
    expect(running.completedAt, completed.completedAt);
    service.response = {'phase': 'cancelled'};
    final interrupted = await repository.read();
    expect(interrupted.phase, ScanPhase.cancelled);
    expect(interrupted.hasResults, isTrue);
    expect(repository.lastCompleted?.media.single.id, 'kept');
  });

  test(
    'confirmed media deletion updates shared findings without rescan',
    () async {
      final service = _StatusService();
      service.response = {
        ...result(),
        'media': [
          media('a', bytes: 10),
          media('b', bytes: 20),
          media('c', bytes: 30, video: true),
        ],
        'similarPairs': [
          ['a', 'b'],
        ],
        'contactMatches': [
          {
            'ids': ['one', 'two'],
            'evidence': 'Shared phone number',
          },
        ],
      };
      final repository = ScanRepository(service);
      await repository.read();

      final updated = await repository.applyDeleted({'a'});
      expect(updated.media.map((item) => item.id), ['b', 'c']);
      expect(updated.similar, isEmpty);
      expect(updated.contacts.single.ids, {'one', 'two'});
      expect(updated.completedAt, isNotNull);
      expect(service.starts, 0);
    },
  );

  test('Photos permission change does not discard Contacts findings', () async {
    final service = _StatusService();
    service.response = {
      ...result(),
      'media': [media('photo', bytes: 10)],
      'contactMatches': [
        {
          'ids': ['one', 'two'],
          'evidence': 'Shared email address',
        },
      ],
    };
    final repository = ScanRepository(service);
    await repository.read();
    service.response = {
      ...service.response,
      'permissions': {'photos': 'denied', 'contacts': 'authorized'},
      'media': <Object?>[],
      'similarPairs': <Object?>[],
    };
    final updated = await repository.read();
    expect(updated.media, isEmpty);
    expect(updated.contacts.single.ids, {'one', 'two'});
    expect(updated.hasResults, isTrue);
  });

  test('revoked access is hidden even during an interrupted rescan', () async {
    final service = _StatusService();
    service.response = {
      ...result(),
      'media': [media('photo', bytes: 10)],
      'contactMatches': [
        {
          'ids': ['one', 'two'],
          'evidence': 'Shared email address',
        },
      ],
    };
    final repository = ScanRepository(service);
    await repository.read();
    service.response = {
      'phase': 'cancelled',
      'permissions': {'photos': 'denied', 'contacts': 'authorized'},
    };
    final retained = await repository.read();
    expect(retained.media, isEmpty);
    expect(retained.similar, isEmpty);
    expect(retained.contacts.single.ids, {'one', 'two'});
  });

  test('only native stale state clears completed findings', () async {
    final service = _StatusService();
    final repository = ScanRepository(service);
    await repository.read();
    expect(repository.lastCompleted, isNotNull);

    service.response = {'phase': 'stale'};
    await repository.read();
    expect(repository.lastCompleted, isNull);

    service.response = result();
    await repository.read();
    expect(repository.lastCompleted, isNotNull);
    await repository.start();
    expect(repository.lastCompleted, isNotNull);
  });

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
  test('a denied library prevents a clean result claim', () {
    final partial = ScanRepository.decode({
      ...result(),
      'permissions': {'photos': 'authorized', 'contacts': 'denied'},
    });
    expect(partial.phase, ScanPhase.success);
    expect(partial.hasPermissionGaps, isTrue);
    expect(partial.incomplete, isTrue);
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
