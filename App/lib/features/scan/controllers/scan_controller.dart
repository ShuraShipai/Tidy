import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_state.dart';
import '../repositories/scan_repository.dart';
import '../services/library_scan_service.dart';

class ScanController extends Notifier<ScanState> {
  Timer? _timer;
  bool _reading = false;
  bool _stopping = false;
  bool _starting = false;
  Future<void>? _initialRefresh;
  int _generation = 0;
  @override
  ScanState build() {
    final repository = ref.read(scanRepositoryProvider);
    final lifecycle = AppLifecycleListener(
      onResume: () {
        if (state.phase != ScanPhase.idle) unawaited(refresh());
      },
      onPause: () {
        if (state.running) unawaited(cancel());
      },
    );
    ref.onDispose(() {
      _generation++;
      _timer?.cancel();
      lifecycle.dispose();
    });
    final cached = repository.lastCompleted;
    // Native storage restores and validates the last completed snapshot.
    // Reading status never starts a new scan or requests authorization.
    _initialRefresh = Future<void>.microtask(() async {
      if (ref.mounted) await refresh();
    });
    return cached ?? const ScanState();
  }

  Future<void> start() async {
    if (state.running || _stopping || _starting) return;
    _starting = true;
    final requestGeneration = _generation;
    try {
      await _initialRefresh;
      if (!ref.mounted ||
          state.running ||
          _stopping ||
          requestGeneration != _generation) {
        return;
      }
      await _startReady();
    } finally {
      _starting = false;
    }
  }

  Future<void> _startReady() async {
    final generation = ++_generation;
    _timer?.cancel();
    final previous = state;
    state = previous.withStatus(ScanPhase.loading);
    try {
      await ref.read(scanRepositoryProvider).start();
      if (!ref.mounted || generation != _generation) return;
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(refresh()),
      );
      await refresh();
    } catch (_) {
      if (ref.mounted && generation == _generation) {
        state = previous.withStatus(
          ScanPhase.error,
          message: ref.read(libraryScanServiceProvider).supported
              ? 'Device scanning is unavailable or still stopping. Check access and try again.'
              : 'Scanning is available on iPhone with iOS Photos and Contacts access.',
        );
      }
    }
  }

  Future<void> refresh() async {
    if (_reading) return;
    _reading = true;
    final generation = _generation;
    try {
      final next = await ref.read(scanRepositoryProvider).read();
      if (ref.mounted && generation == _generation) {
        state = next;
        _timer?.cancel();
        _timer = next.running || next.hasResults
            ? Timer.periodic(
                Duration(seconds: next.running ? 1 : 10),
                (_) => unawaited(refresh()),
              )
            : null;
      }
    } catch (_) {
      if (ref.mounted && generation == _generation) {
        // A transient status read must not make completed findings disappear.
        if (!state.hasResults) {
          _timer?.cancel();
          _timer = null;
          state = const ScanState(
            phase: ScanPhase.error,
            message: 'Could not read scan status. Try scanning again.',
          );
        }
      }
    } finally {
      _reading = false;
    }
  }

  Future<void> cancel() async {
    if (_stopping) return;
    _stopping = true;
    _generation++;
    _timer?.cancel();
    state = state.withStatus(
      ScanPhase.cancelled,
      message:
          'The scan was stopped. Last completed findings remain available.',
    );
    try {
      await ref.read(scanRepositoryProvider).cancel();
    } catch (_) {
      if (ref.mounted) {
        state = state.withStatus(
          ScanPhase.error,
          message: 'Could not confirm scan cancellation.',
        );
      }
    } finally {
      _stopping = false;
    }
  }

  Future<void> applyDeleted(Set<String> ids) async {
    if (ids.isEmpty) return;
    final generation = ++_generation;
    final updated = await ref.read(scanRepositoryProvider).applyDeleted(ids);
    if (ref.mounted && generation == _generation) {
      state = updated;
      _timer?.cancel();
      _timer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => unawaited(refresh()),
      );
    }
  }
}

final scanControllerProvider = NotifierProvider<ScanController, ScanState>(
  ScanController.new,
);
