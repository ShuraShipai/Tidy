import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_state.dart';
import '../services/library_scan_service.dart';

class ScanRepository {
  ScanRepository(this.service);
  final LibraryScanService service;
  ScanState? _lastCompleted;

  ScanState? get lastCompleted => _lastCompleted;

  Future<void> start() async {
    _latest = null;
    _serial = null;
    await service.start();
  }

  Future<void> cancel() => service.cancel();
  Future<ScanState> applyDeleted(Set<String> ids) async {
    if (ids.isEmpty) return _latest ?? const ScanState();
    await service.applyDeleted(ids);
    _serial = null;
    return read();
  }

  int? _serial;
  ScanState? _latest;
  Future<ScanState> read() async {
    final map = await service.status(_serial);
    if (map['unchanged'] == true && _latest != null) return _latest!;
    final decoded = await compute(decode, map);
    _serial = map['serial'] as int?;
    if (decoded.phase == ScanPhase.stale) {
      _lastCompleted = null;
      return _latest = decoded;
    }
    if (decoded.phase == ScanPhase.success ||
        decoded.phase == ScanPhase.empty) {
      _lastCompleted = decoded;
      return _latest = decoded;
    }
    // A process killed during a rescan restores its previous successful
    // snapshot with an interrupted phase. Keep that snapshot authoritative.
    if (_lastCompleted == null && decoded.completedAt != null) {
      _lastCompleted = decode({...map, 'phase': 'success'});
    }
    if (_lastCompleted != null) {
      return _latest = decoded.withStatus(
        decoded.phase,
        previous: _lastCompleted,
      );
    }
    return _latest = decoded;
  }

  static ScanState decode(Map<Object?, Object?> map) {
    final phase = ScanPhase.values.byName(map['phase']! as String);
    final media = (map['media'] as List? ?? [])
        .map((x) => MediaRecord.fromMap(x as Map))
        .toList();
    final similar = _groups(
      (map['similarPairs'] as List? ?? []).map(
        (x) => MatchGroup(
          (x as List).cast<String>(),
          'Possible visual match within 60 seconds',
        ),
      ),
    );
    final contacts = _groups(
      (map['contactMatches'] as List? ?? []).map(
        (x) => MatchGroup(
          (x['ids'] as List).cast<String>(),
          x['evidence'] as String,
        ),
      ),
    );
    final storage = map['storage'] as Map?;
    final permissions = Map<String, String>.unmodifiable(
      (map['permissions'] as Map? ?? {}).cast<String, String>(),
    );
    final noFindings =
        similar.isEmpty &&
        contacts.isEmpty &&
        !media.any((x) => x.screenshot || x.largeVideo);
    // An incomplete analysis must never assert that the library is clean.
    final complete =
        !media.any((x) => x.bytes == null) &&
        (map['unavailableImages'] ?? 0) == 0 &&
        ['authorized', 'limited'].contains(permissions['photos']) &&
        ['authorized', 'limited'].contains(permissions['contacts']);
    return ScanState(
      phase: phase == ScanPhase.success && noFindings && complete
          ? ScanPhase.empty
          : phase,
      media: List.unmodifiable(media),
      similar: List.unmodifiable(similar),
      contacts: List.unmodifiable(contacts),
      permissions: permissions,
      capacity: storage?['capacity'] as int?,
      free: storage?['free'] as int?,
      used: storage?['used'] as int?,
      processed: map['processed'] as int?,
      total: map['total'] as int?,
      stage: map['stage'] as String?,
      message: map['message'] as String?,
      storageError: map['storageError'] as String?,
      completedAt: map['completedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (map['completedAt'] as num).round(),
            ),
      contactCount: map['contactCount'] as int? ?? 0,
      unavailableImages: map['unavailableImages'] as int? ?? 0,
    );
  }

  static List<MatchGroup> _groups(Iterable<MatchGroup> matches) {
    final edges = matches.toList();
    final parents = <String, String>{};
    String root(String id) {
      parents.putIfAbsent(id, () => id);
      var current = id;
      while (parents[current] != current) {
        parents[current] = parents[parents[current]]!;
        current = parents[current]!;
      }
      return current;
    }

    for (final match in edges) {
      if (match.ids.isEmpty) continue;
      final first = root(match.ids.first);
      for (final id in match.ids.skip(1)) {
        parents[root(id)] = root(first);
      }
    }
    final members = <String, Set<String>>{};
    final evidence = <String, Set<String>>{};
    for (final id in parents.keys.toList()) {
      members.putIfAbsent(root(id), () => {}).add(id);
    }
    for (final match in edges) {
      if (match.ids.isNotEmpty) {
        evidence
            .putIfAbsent(root(match.ids.first), () => {})
            .add(match.evidence);
      }
    }
    return [
      for (final entry in members.entries)
        if (entry.value.length > 1)
          MatchGroup(entry.value, evidence[entry.key]!.join('; ')),
    ];
  }
}

final scanRepositoryProvider = Provider(
  (ref) => ScanRepository(ref.watch(libraryScanServiceProvider)),
);
