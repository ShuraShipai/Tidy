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
  int _generation = 0;
  @override
  ScanState build() {
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
    return const ScanState();
  }

  Future<void> start() async {
    if (state.running || _stopping) return;
    final generation = ++_generation;
    _timer?.cancel();
    state = const ScanState(phase: ScanPhase.loading);
    try {
      await ref.read(scanRepositoryProvider).start();
      if (!ref.mounted || generation != _generation) return;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => refresh());
      await refresh();
    } catch (_) {
      if (ref.mounted && generation == _generation) {
        state = ScanState(
          phase: ScanPhase.error,
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
        // Continue observing completed results so library changes invalidate them.
        if (!next.running && !next.hasResults) {
          _timer?.cancel();
          _timer = null;
        }
      }
    } catch (_) {
      if (ref.mounted && generation == _generation) {
        _timer?.cancel();
        state = const ScanState(
          phase: ScanPhase.error,
          message: 'Could not read scan status. Try scanning again.',
        );
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
    state = const ScanState(phase: ScanPhase.cancelled);
    try {
      await ref.read(scanRepositoryProvider).cancel();
    } catch (_) {
      if (ref.mounted) {
        state = const ScanState(
          phase: ScanPhase.error,
          message: 'Could not confirm scan cancellation.',
        );
      }
    } finally {
      _stopping = false;
    }
  }
}

final scanControllerProvider = NotifierProvider<ScanController, ScanState>(
  ScanController.new,
);
