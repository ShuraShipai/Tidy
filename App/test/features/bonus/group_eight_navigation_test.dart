import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/app.dart';
import 'package:tidy/core/router/app_router.dart';
import 'package:tidy/features/bonus/services/group_eight_service.dart';

void main() {
  testWidgets('Vault ignores inactive then locks when hidden', (tester) async {
    final service = _RecordingGroupEightService();
    final container = ProviderContainer(
      overrides: [groupEightServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    container.read(appRouterProvider).go('/bonus/vault');

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TidyApp()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set Up Vault'));
    await tester.pumpAndSettle();

    expect(find.text('Move to Vault'), findsOneWidget);
    expect(find.text('Lock Vault'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(find.text('Move to Vault'), findsOneWidget);
    expect(service.vaultLockCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pumpAndSettle();
    expect(service.vaultLockCount, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Set Up Vault'), findsNothing);
    expect(find.text('Unlock Vault'), findsOneWidget);
    expect(find.text('Move to Vault'), findsNothing);
  });

  testWidgets('an initialized Vault offers Unlock instead of Set Up', (
    tester,
  ) async {
    final service = _RecordingGroupEightService()..vaultConfigured = true;
    final container = ProviderContainer(
      overrides: [groupEightServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    container.read(appRouterProvider).go('/bonus/vault');

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TidyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unlock Vault'), findsOneWidget);
    expect(find.text('Set Up Vault'), findsNothing);
    await tester.tap(find.text('Unlock Vault'));
    await tester.pumpAndSettle();
    expect(find.text('Move to Vault'), findsOneWidget);
  });

  testWidgets(
    'Vault requests only visible thumbnails and reuses them on rebuild',
    (tester) async {
      final service = _RecordingGroupEightService()
        ..vaultConfigured = true
        ..vaultItemCount = 120;
      final container = ProviderContainer(
        overrides: [groupEightServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      container.read(appRouterProvider).go('/bonus/vault');

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const TidyApp()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unlock Vault'));
      await tester.pumpAndSettle();
      expect(service.vaultThumbnailRequestCount, greaterThan(0));
      expect(
        service.vaultThumbnailRequestCount,
        lessThan(service.vaultItemCount),
      );
      final requestsBeforeRebuild = service.vaultThumbnailRequestCount;
      final visibleItemId = service.vaultThumbnailRequests.first;
      final visibleItem = find.byKey(ValueKey(visibleItemId));
      expect(visibleItem, findsOneWidget);
      await tester.tap(visibleItem);
      await tester.pump();
      expect(service.vaultThumbnailRequestCount, requestsBeforeRebuild);
    },
  );

  testWidgets('Vault photos stay newest by capture date after reopening', (
    tester,
  ) async {
    final service = _RecordingGroupEightService()
      ..vaultConfigured = true
      ..vaultRows = [
        {
          'id': 'older',
          'name': 'Older photo',
          'created': 1_000,
          'addedAt': 200,
          'bytes': 100,
        },
        {
          'id': 'newer',
          'name': 'Newest photo',
          'created': 9_000,
          'addedAt': 100,
          'bytes': 100,
        },
      ];
    final container = ProviderContainer(
      overrides: [groupEightServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    router.go('/bonus/vault');

    Future<void> unlockAndExpectNewestFirst() async {
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const TidyApp()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unlock Vault'));
      await tester.pumpAndSettle();
      final older = tester.getRect(
        find.bySemanticsLabel('Older photo, not selected'),
      );
      final newer = tester.getRect(
        find.bySemanticsLabel('Newest photo, not selected'),
      );
      expect(
        newer.top < older.top ||
            (newer.top == older.top && newer.left < older.left),
        isTrue,
      );
    }

    await unlockAndExpectNewestFirst();
    router.go('/bonus/tools');
    await tester.pumpAndSettle();
    router.go('/bonus/vault');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock Vault'));
    await tester.pumpAndSettle();
    final olderAfterReopen = tester.getRect(
      find.bySemanticsLabel('Older photo, not selected'),
    );
    final newerAfterReopen = tester.getRect(
      find.bySemanticsLabel('Newest photo, not selected'),
    );
    expect(
      newerAfterReopen.top < olderAfterReopen.top ||
          (newerAfterReopen.top == olderAfterReopen.top &&
              newerAfterReopen.left < olderAfterReopen.left),
      isTrue,
    );
  });

  testWidgets(
    'Group 08 optional tools enter and return without starting scan',
    (tester) async {
      final service = _RecordingGroupEightService();
      final container = ProviderContainer(
        overrides: [groupEightServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      container.read(appRouterProvider).go('/bonus/tools');

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const TidyApp()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Optional Features'), findsOneWidget);
      await tester.tap(find.text('Private Vault'));
      await tester.pumpAndSettle();
      expect(find.text('Set Up Vault'), findsOneWidget);
      expect(service.vaultAuthenticationCount, 0);
      await tester.tap(find.text('Not Now'));
      await tester.pumpAndSettle();
      expect(find.text('Optional Features'), findsOneWidget);

      await tester.tap(find.text('Calendar Cleanup'));
      await tester.pumpAndSettle();
      expect(find.text('A lighter calendar.'), findsOneWidget);
      expect(service.calendarStatusCount, 1);
      expect(service.calendarRequestCount, 0);
      await tester.tap(find.text('Optional Features').first);
      await tester.pumpAndSettle();
      expect(find.text('Optional Features'), findsOneWidget);
      expect(service.calendarRequestCount, 0);
    },
  );
}

class _RecordingGroupEightService extends GroupEightService {
  int calendarStatusCount = 0;
  int calendarRequestCount = 0;
  int vaultAuthenticationCount = 0;
  int vaultLockCount = 0;
  int vaultThumbnailRequestCount = 0;
  final List<String> vaultThumbnailRequests = [];
  int vaultItemCount = 0;
  bool vaultConfigured = false;
  List<Map<String, Object?>> vaultRows = [];

  @override
  Future<String> calendarStatus() async {
    calendarStatusCount++;
    return 'notDetermined';
  }

  @override
  Future<Map<String, Object?>> requestCalendar() async {
    calendarRequestCount++;
    return {'status': 'denied'};
  }

  @override
  Future<Map<String, Object?>> authenticateVault() async {
    vaultAuthenticationCount++;
    vaultConfigured = true;
    return {'unlocked': true};
  }

  @override
  Future<bool> vaultIsConfigured() async => vaultConfigured;

  @override
  Future<List<Map<String, Object?>>> vaultItems() async => vaultRows.isNotEmpty
      ? vaultRows.map((row) => Map<String, Object?>.of(row)).toList()
      : List.generate(
          vaultItemCount,
          (index) => {
            'id': 'vault-$index',
            'name': 'Vault item $index',
            'created': 1,
            'addedAt': index,
            'bytes': 100,
          },
        );

  @override
  Future<Uint8List?> vaultThumbnail(String id) async {
    vaultThumbnailRequestCount++;
    vaultThumbnailRequests.add(id);
    return null;
  }

  @override
  Future<void> lockVault() async {
    vaultLockCount++;
  }
}
