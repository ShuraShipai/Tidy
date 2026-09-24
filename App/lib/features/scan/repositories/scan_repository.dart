import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_state.dart';
import '../services/library_scan_service.dart';

class ScanRepository {
  ScanRepository(this.service);
  final LibraryScanService service;
  Future<void> start() => service.start();
  Future<void> cancel() => service.cancel();
  int? _serial;
  ScanState? _latest;
  Future<ScanState> read() async {
    final map = await service.status(_serial);
    if (map['unchanged'] == true && _latest != null) return _latest!;
    final decoded = await compute(decode, map);
    _serial = map['serial'] as int?;
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
    final noFindings =
        similar.isEmpty &&
        contacts.isEmpty &&
        !media.any((x) => x.screenshot || x.largeVideo);
    // An incomplete analysis must never assert that the library is clean.
    final complete =
        !media.any((x) => x.bytes == null) &&
        (map['unavailableImages'] ?? 0) == 0;
    return ScanState(
      phase: phase == ScanPhase.success && noFindings && complete
          ? ScanPhase.empty
          : phase,
      media: List.unmodifiable(media),
      similar: List.unmodifiable(similar),
      contacts: List.unmodifiable(contacts),
      permissions: Map.unmodifiable(
        (map['permissions'] as Map? ?? {}).cast<String, String>(),
      ),
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
