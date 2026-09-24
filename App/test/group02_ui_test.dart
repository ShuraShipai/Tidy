import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/app.dart';
import 'package:tidy/core/router/app_router.dart';
import 'package:tidy/features/scan/models/scan_state.dart';
import 'package:tidy/features/scan/controllers/scan_controller.dart';
import 'package:tidy/features/scan/repositories/scan_repository.dart';
import 'package:tidy/features/scan/services/library_scan_service.dart';

class _ScanningRepository extends ScanRepository {
  _ScanningRepository() : super(const LibraryScanService());
  int starts = 0;
  int cancels = 0;
  @override
  Future<void> start() async {
    starts++;
  }

  @override
  Future<void> cancel() async {
    cancels++;
  }

  @override
  Future<ScanState> read() async => const ScanState(
    phase: ScanPhase.scanning,
    stage: 'media',
    processed: 0,
    total: 1,
  );
}

void main() {
  testWidgets('Home and scan show truthful not-scanned UI and navigate', (
    tester,
  ) async {
    final repository = _ScanningRepository();
    final container = ProviderContainer(
      overrides: [scanRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go('/home');
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TidyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ready when you are'), findsOneWidget);
    expect(find.text('Not scanned'), findsNWidgets(4));
    expect(find.textContaining('GB used'), findsNothing);

    await container.read(scanControllerProvider.notifier).start();
    await tester.pump();
    unawaited(router.push<void>('/scan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Scanning your iPhone'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(repository.starts, 1);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Storage'), findsOneWidget);
    expect(repository.cancels, 1);
  });
}
