import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/app.dart';
import 'package:tidy/core/router/app_router.dart';
import 'package:tidy/features/onboarding/controllers/onboarding_preview_controller.dart';

Future<void> tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).hitTestable());
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<ProviderContainer> launch(WidgetTester tester) async {
  tester.view.physicalSize = const Size(393, 852);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
  addTearDown(tester.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const TidyApp()),
  );
  return container;
}

void main() {
  testWidgets(
    'full access preview completes onboarding without a native request',
    (tester) async {
      final container = await launch(tester);
      expect(find.text('tidy'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
      expect(find.text('Make space.\nKeep what matters.'), findsOneWidget);
      await tap(tester, 'Continue');
      expect(find.text('Nothing deleted automatically'), findsOneWidget);
      await tap(tester, 'Continue');
      await tap(tester, 'Allow Photo Access');
      expect(find.textContaining('UI preview only'), findsOneWidget);
      await tap(tester, 'Simulate Full Access');
      expect(
        container.read(onboardingPreviewProvider).photos,
        PhotoAccessPreview.full,
      );
      await tap(tester, 'Allow Contacts');
      await tap(tester, 'Simulate Allowed');
      expect(
        container.read(onboardingPreviewProvider).contacts,
        ContactAccessPreview.allowed,
      );
      expect(find.text('Storage'), findsOneWidget);
    },
  );

  testWidgets(
    'limited and denied previews support back, manage, retry and skip',
    (tester) async {
      final container = await launch(tester);
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
      await tap(tester, 'Continue');
      await tap(tester, 'Continue');
      await tap(tester, 'Allow Photo Access');
      await tap(tester, 'Simulate Limited Access');
      expect(find.text('Limited Photo Access'), findsOneWidget);
      await tap(tester, 'Manage Photos');
      await tap(tester, 'Back');
      expect(
        container.read(onboardingPreviewProvider).photos,
        PhotoAccessPreview.limited,
      );
      await tap(tester, 'Manage Photos');
      await tap(tester, 'Simulate Denied');
      expect(find.text('Photo Access Is Off'), findsOneWidget);
      await tap(tester, 'Open Settings');
      expect(
        find.textContaining('does not request permissions'),
        findsOneWidget,
      );
      await tap(tester, 'Back');
      await tap(tester, 'Continue Without Photos');
      await tap(tester, 'Allow Contacts');
      await tap(tester, 'Simulate Denied');
      expect(find.text('Contacts Access\nNeeded'), findsOneWidget);
      await tap(tester, 'Open Settings');
      await tap(tester, 'Back');
      await tap(tester, 'Not Now');
      expect(find.text('Storage'), findsOneWidget);
      expect(
        container.read(onboardingPreviewProvider).contacts,
        ContactAccessPreview.denied,
      );
    },
  );

  testWidgets('skipping Photos leaves the preview unchosen', (tester) async {
    final container = await launch(tester);
    container.read(appRouterProvider).go('/onboarding/photos');
    await tester.pumpAndSettle();
    await tap(tester, 'Not Now');
    expect(
      container.read(onboardingPreviewProvider).photos,
      PhotoAccessPreview.notChosen,
    );
    expect(find.text('Allow Contacts'), findsOneWidget);
  });

  testWidgets('all onboarding routes accommodate large text on a small phone', (
    tester,
  ) async {
    final container = await launch(tester);
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final router = container.read(appRouterProvider);
    for (final route in <String>[
      '/onboarding/welcome',
      '/onboarding/privacy',
      '/onboarding/photos/preview',
      '/onboarding/contacts',
      '/onboarding/contacts/preview',
    ]) {
      router.go(route);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: route);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    }
    container
        .read(onboardingPreviewProvider.notifier)
        .chooseContacts(ContactAccessPreview.denied);
    router.go('/onboarding/contacts');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Open Settings'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Open Settings').hitTestable(), findsOneWidget);
  });

  testWidgets(
    'permission states remain scrollable with larger text on a small phone',
    (tester) async {
      final container = await launch(tester);
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final router = container.read(appRouterProvider);
      for (final status in PhotoAccessPreview.values) {
        container.read(onboardingPreviewProvider.notifier).choosePhotos(status);
        router.go('/onboarding/photos');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        final action = status == PhotoAccessPreview.denied
            ? 'Open Settings'
            : status == PhotoAccessPreview.limited
            ? 'Manage Photos'
            : 'Allow Photo Access';
        await tester.ensureVisible(find.text(action));
        await tester.pumpAndSettle();
        expect(
          find
              .text(
                status == PhotoAccessPreview.denied
                    ? 'Open Settings'
                    : status == PhotoAccessPreview.limited
                    ? 'Manage Photos'
                    : 'Allow Photo Access',
              )
              .hitTestable(),
          findsOneWidget,
        );
      }
    },
  );
}
