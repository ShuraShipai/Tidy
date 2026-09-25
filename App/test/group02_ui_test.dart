import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/app.dart';
import 'package:tidy/core/router/app_router.dart';
import 'package:tidy/features/scan/models/scan_state.dart';
import 'package:tidy/features/scan/controllers/scan_controller.dart';
import 'package:tidy/features/scan/repositories/scan_repository.dart';
import 'package:tidy/features/scan/services/library_scan_service.dart';
import 'package:tidy/features/home/widgets/home_category_card.dart';

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
  Future<ScanState> read() async => starts == 0
      ? const ScanState()
      : const ScanState(
          phase: ScanPhase.scanning,
          stage: 'media',
          processed: 0,
          total: 1,
        );
}

class _SavedScan {
  int starts = 0;
  ScanState? completed;
}

class _RestoredScanRepository extends ScanRepository {
  _RestoredScanRepository(this.saved) : super(const LibraryScanService());

  final _SavedScan saved;

  @override
  Future<void> start() async {
    saved.starts++;
    saved.completed = ScanState(
      phase: ScanPhase.success,
      completedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      permissions: const {'photos': 'authorized', 'contacts': 'authorized'},
    );
  }

  @override
  Future<ScanState> read() async => saved.completed ?? const ScanState();
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
    final homeLabelFade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.text('Home'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(homeLabelFade.opacity.value, 0);
    expect(homeLabelFade.alwaysIncludeSemantics, isTrue);
    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    expect(
      navigationBar.destinations.cast<NavigationDestination>().map(
        (destination) => destination.label,
      ),
      ['Home', 'Photos', 'Videos', 'Contacts', 'Settings'],
    );
    expect(
      navigationBar.labelBehavior,
      NavigationDestinationLabelBehavior.alwaysHide,
    );
    expect(
      tester.getSize(find.byType(NavigationBar)).height,
      greaterThanOrEqualTo(44),
    );
    await tester.tap(find.byIcon(Icons.photo_outlined).first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.byIcon(Icons.photo_rounded), findsOneWidget);
    router.go('/home');
    await tester.pumpAndSettle();
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

  testWidgets(
    'one completed result survives all tabs and a new provider scope',
    (tester) async {
      final saved = _SavedScan();
      final first = ProviderContainer(
        overrides: [
          scanRepositoryProvider.overrideWithValue(
            _RestoredScanRepository(saved),
          ),
        ],
      );
      final firstRouter = first.read(appRouterProvider)..go('/home');
      await tester.pumpWidget(
        UncontrolledProviderScope(container: first, child: const TidyApp()),
      );
      await tester.pump();
      await first.read(scanControllerProvider.notifier).start();
      await tester.pump();
      for (final path in ['/photos', '/videos', '/contacts', '/home']) {
        firstRouter.go(path);
        await tester.pump();
        expect(first.read(scanControllerProvider).hasResults, isTrue);
        expect(
          first
              .read(scanControllerProvider)
              .completedAt
              ?.millisecondsSinceEpoch,
          1000,
        );
        expect(saved.starts, 1);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      first.dispose();

      final reopened = ProviderContainer(
        overrides: [
          scanRepositoryProvider.overrideWithValue(
            _RestoredScanRepository(saved),
          ),
        ],
      );
      reopened.read(appRouterProvider).go('/home');
      await tester.pumpWidget(
        UncontrolledProviderScope(container: reopened, child: const TidyApp()),
      );
      await tester.pump();
      await tester.pump();
      expect(reopened.read(scanControllerProvider).hasResults, isTrue);
      expect(saved.starts, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      reopened.dispose();
    },
  );

  testWidgets('each Home category opens its approved review destination', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _ScanningRepository();
    final container = ProviderContainer(
      overrides: [scanRepositoryProvider.overrideWithValue(repository)],
    );
    final router = container.read(appRouterProvider)..go('/home');
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TidyApp()),
    );
    await tester.pump();
    const destinations = [
      '/photos/similar',
      '/photos/screenshots',
      '/videos',
      '/contacts',
    ];
    for (var index = 0; index < destinations.length; index++) {
      router.go('/home');
      await tester.pumpAndSettle();
      final card = find.byType(HomeCategoryCard).at(index);
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        destinations[index],
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
}
