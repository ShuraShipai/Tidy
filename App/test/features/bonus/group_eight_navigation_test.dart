import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/app.dart';
import 'package:tidy/core/router/app_router.dart';
import 'package:tidy/features/bonus/services/group_eight_service.dart';

void main() {
  testWidgets('Private Vault returns to locked state when app backgrounds', (
    tester,
  ) async {
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

    expect(find.text('Add Items'), findsOneWidget);
    expect(find.text('Lock Vault'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    expect(find.text('Unlock Vault'), findsOneWidget);
    expect(find.text('Add Items'), findsNothing);
    expect(service.vaultLockCount, 1);
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
    expect(find.text('Add Items'), findsOneWidget);
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
  bool vaultConfigured = false;

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
    return {'unlocked': true};
  }

  @override
  Future<bool> vaultIsConfigured() async => vaultConfigured;

  @override
  Future<List<Map<String, Object?>>> vaultItems() async => const [];

  @override
  Future<void> lockVault() async {
    vaultLockCount++;
  }
}
