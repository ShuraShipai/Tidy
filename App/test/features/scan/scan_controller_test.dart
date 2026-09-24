import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/features/scan/controllers/scan_controller.dart';
import 'package:tidy/features/scan/models/scan_state.dart';
import 'package:tidy/features/scan/repositories/scan_repository.dart';
import 'package:tidy/features/scan/services/library_scan_service.dart';

class TestRepository extends ScanRepository {
  TestRepository() : super(const LibraryScanService());
  int starts = 0, cancels = 0;
  bool fail = false;
  Completer<ScanState>? pending;
  ScanState next = const ScanState(phase: ScanPhase.scanning);
  @override
  Future<void> start() async {
    starts++;
    if (fail) throw StateError('native failure');
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }

  @override
  Future<ScanState> read() async =>
      pending == null ? next : await pending!.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestRepository repository;
  late ProviderContainer container;
  setUp(() {
    repository = TestRepository();
    container = ProviderContainer(
      overrides: [scanRepositoryProvider.overrideWithValue(repository)],
    );
  });
  tearDown(() => container.dispose());
  test('duplicate submission starts only one scan', () async {
    final controller = container.read(scanControllerProvider.notifier);
    final first = controller.start();
    await controller.start();
    await first;
    expect(repository.starts, 1);
    expect(container.read(scanControllerProvider).phase, ScanPhase.scanning);
  });
  test('cancel discards a late successful native result', () async {
    repository.pending = Completer<ScanState>();
    final controller = container.read(scanControllerProvider.notifier);
    final first = controller.start();
    await Future<void>.delayed(Duration.zero);
    await controller.cancel();
    repository.pending!.complete(const ScanState(phase: ScanPhase.success));
    await first;
    expect(repository.cancels, 1);
    expect(container.read(scanControllerProvider).phase, ScanPhase.cancelled);
  });
  test('native failures expose errors without fabricated data', () async {
    repository.fail = true;
    await container.read(scanControllerProvider.notifier).start();
    final state = container.read(scanControllerProvider);
    expect(state.phase, ScanPhase.error);
    expect(state.media, isEmpty);
    expect(state.capacity, isNull);
  });
  test('changed access invalidates previously completed results', () async {
    repository.next = const ScanState(phase: ScanPhase.empty);
    final controller = container.read(scanControllerProvider.notifier);
    await controller.start();
    repository.next = const ScanState(phase: ScanPhase.stale);
    await controller.refresh();
    expect(container.read(scanControllerProvider).phase, ScanPhase.stale);
    expect(container.read(scanControllerProvider).hasResults, isFalse);
  });
}
