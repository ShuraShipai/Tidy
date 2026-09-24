import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/app.dart';
import 'package:tidy/core/router/app_router.dart';
import 'package:tidy/features/onboarding/controllers/onboarding_controller.dart';
import 'package:tidy/features/onboarding/models/access_status.dart';
import 'package:tidy/features/onboarding/models/permission_subject.dart';
import 'package:tidy/features/onboarding/repositories/onboarding_repository.dart';

import 'support/fake_onboarding_service.dart';

Future<ProviderContainer> launch(
  WidgetTester tester,
  FakeOnboardingService service,
) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [onboardingServiceProvider.overrideWithValue(service)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const TidyApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).hitTestable());
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

String location(ProviderContainer container) => container
    .read(appRouterProvider)
    .routerDelegate
    .currentConfiguration
    .last
    .matchedLocation;

void main() {
  testWidgets(
    'first launch does not request access; both grants finish onboarding',
    (tester) async {
      final service = FakeOnboardingService();
      final container = await launch(tester, service);
      expect(location(container), '/onboarding/welcome');
      expect(service.requests, 0);
      await tap(tester, 'Continue');
      await tap(tester, 'Continue');
      await tap(tester, 'Allow Photo Access');
      expect(service.requests, 0);
      await tap(tester, 'Continue');
      expect(service.requests, 1);
      expect(location(container), '/onboarding/contacts');
      await tap(tester, 'Allow Contacts');
      await tap(tester, 'Continue');
      expect(service.requests, 2);
      expect(service.completed, isTrue);
      expect(location(container), '/scan');
    },
  );

  testWidgets(
    'skipping does not grant access and completion survives a new container',
    (tester) async {
      final service = FakeOnboardingService();
      final container = await launch(tester, service);
      container.read(appRouterProvider).go('/onboarding/photos');
      await tester.pumpAndSettle();
      await tap(tester, 'Not Now');
      await tap(tester, 'Not Now');
      expect(service.requests, 0);
      expect(service.photos, AccessStatus.notDetermined);
      expect(service.contacts, AccessStatus.notDetermined);
      expect(service.completed, isTrue);
      await tester.pumpWidget(const SizedBox());
      final next = await launch(tester, service);
      expect(location(next), '/home');
    },
  );

  testWidgets('limited Photos manages native selection and can continue', (
    tester,
  ) async {
    final service = FakeOnboardingService()..next = AccessStatus.limited;
    final container = await launch(tester, service);
    container.read(appRouterProvider).go('/onboarding/photos');
    await tester.pumpAndSettle();
    await tap(tester, 'Allow Photo Access');
    await tap(tester, 'Continue');
    expect(find.text('Limited Photo Access'), findsOneWidget);
    await tap(tester, 'Manage Photos');
    expect(service.managers, 1);
    expect(service.requests, 1);
    await tap(tester, 'Continue with Selected Photos');
    expect(location(container), '/onboarding/contacts');
  });

  testWidgets(
    'denial opens Settings; resume reconciles a later grant or revocation',
    (tester) async {
      final service = FakeOnboardingService()..next = AccessStatus.denied;
      final container = await launch(tester, service);
      container.read(appRouterProvider).go('/onboarding/photos');
      await tester.pumpAndSettle();
      await tap(tester, 'Allow Photo Access');
      await tap(tester, 'Continue');
      expect(find.text('Photo Access Is Off'), findsOneWidget);
      await tap(tester, 'Open Settings');
      expect(service.requests, 1);
      expect(service.settings, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      service.photos = AccessStatus.granted;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
      service.photos = AccessStatus.denied;
      await container.read(onboardingProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Open Settings'), findsOneWidget);
    },
  );

  testWidgets('previously granted access never re-requests', (tester) async {
    final service = FakeOnboardingService()
      ..photos = AccessStatus.granted
      ..contacts = AccessStatus.granted;
    final container = await launch(tester, service);
    container.read(appRouterProvider).go('/onboarding/photos');
    await tester.pumpAndSettle();
    await tap(tester, 'Continue');
    await tap(tester, 'Continue');
    expect(service.requests, 0);
    expect(service.completed, isTrue);
  });

  testWidgets(
    'restricted access explains restrictions without requesting or opening Settings',
    (tester) async {
      final service = FakeOnboardingService()
        ..photos = AccessStatus.restricted
        ..contacts = AccessStatus.restricted;
      final container = await launch(tester, service);
      container.read(appRouterProvider).go('/onboarding/photos');
      await tester.pumpAndSettle();
      expect(find.textContaining('restricted by iOS'), findsOneWidget);
      expect(find.text('Open Settings'), findsNothing);
      await tap(tester, 'Continue');
      await tap(tester, 'Continue');
      expect(service.requests, 0);
      expect(service.settings, 0);
      expect(service.completed, isTrue);
    },
  );

  testWidgets(
    'limited Contacts stays limited and offers Settings or continuing',
    (tester) async {
      final service = FakeOnboardingService()..contacts = AccessStatus.limited;
      final container = await launch(tester, service);
      container.read(appRouterProvider).go('/onboarding/contacts');
      await tester.pumpAndSettle();
      expect(find.text('Limited Contacts Access'), findsOneWidget);
      await tap(tester, 'Open Settings');
      expect(service.settings, 1);
      await tap(tester, 'Continue with Selected Contacts');
      expect(service.contacts, AccessStatus.limited);
      expect(service.completed, isTrue);
    },
  );

  testWidgets('failed save stays on onboarding and can retry', (tester) async {
    final service = FakeOnboardingService()..failSave = true;
    final container = await launch(tester, service);
    container.read(appRouterProvider).go('/onboarding/contacts');
    await tester.pumpAndSettle();
    await tap(tester, 'Not Now');
    expect(location(container), '/onboarding/contacts');
    expect(service.completed, isFalse);
    expect(find.textContaining('Unable to save'), findsOneWidget);
    service.failSave = false;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tap(tester, 'Not Now');
    expect(location(container), '/scan');
  });

  testWidgets(
    'startup read failure is retryable and does not skip onboarding',
    (tester) async {
      final service = FakeOnboardingService()..failRead = true;
      final container = await launch(tester, service);
      expect(location(container), '/onboarding');
      expect(find.text('Retry'), findsOneWidget);
      service.failRead = false;
      await tap(tester, 'Retry');
      expect(location(container), '/onboarding/welcome');
    },
  );

  testWidgets(
    'request failures are retryable; overlapping requests are ignored',
    (tester) async {
      final service = FakeOnboardingService()..failRequest = true;
      final container = await launch(tester, service);
      final controller = container.read(onboardingProvider.notifier);
      expect(await controller.request(PermissionSubject.photos), isFalse);
      expect(container.read(onboardingProvider).error, isNotNull);
      service.failRequest = false;
      service.pending = Completer<void>();
      final request = controller.request(PermissionSubject.photos);
      await tester.pump();
      expect(await controller.request(PermissionSubject.photos), isFalse);
      expect(await controller.complete(), isFalse);
      expect(service.requests, 2);
      service.pending!.complete();
      expect(await request, isTrue);
      expect(service.saves, 0);
    },
  );

  testWidgets(
    'Settings launch failure is reported without changing authorization',
    (tester) async {
      final service = FakeOnboardingService()
        ..photos = AccessStatus.denied
        ..failSettings = true;
      final container = await launch(tester, service);
      await container
          .read(onboardingProvider.notifier)
          .primary(PermissionSubject.photos);
      expect(container.read(onboardingProvider).error, isNotNull);
      expect(container.read(onboardingProvider).photos, AccessStatus.denied);
    },
  );

  testWidgets(
    'all access states and handoffs fit large text on a small phone',
    (tester) async {
      final service = FakeOnboardingService();
      final container = await launch(tester, service);
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final subject in PermissionSubject.values) {
        for (final status in AccessStatus.values) {
          service.photos = status;
          service.contacts = status;
          await container.read(onboardingProvider.notifier).refresh();
          container.read(appRouterProvider).go('/onboarding/${subject.name}');
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$subject $status');
          expect(find.byType(SingleChildScrollView), findsOneWidget);
        }
        container
            .read(appRouterProvider)
            .go('/onboarding/${subject.name}/request');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
}
