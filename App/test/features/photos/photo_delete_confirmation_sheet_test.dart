import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/core/design/tidy_theme.dart';
import 'package:tidy/features/photos/widgets/photo_delete_confirmation_sheet.dart';

void main() {
  testWidgets(
    'approved bottom sheet keeps deletion behind explicit confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Future<void> openSheet() async {
        await tester.tap(find.text('Open confirmation'));
        await tester.pumpAndSettle();
      }

      bool? answer;
      await tester.pumpWidget(
        MaterialApp(
          theme: TidyTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  answer = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        const PhotoDeleteConfirmationSheet(count: 1),
                  );
                },
                child: const Text('Open confirmation'),
              ),
            ),
          ),
        ),
      );

      await openSheet();
      expect(find.text('Clean selected items?'), findsOneWidget);
      expect(find.text('Clean 1 Item'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(answer, isNull);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(answer, isFalse);

      await openSheet();
      await tester.tap(find.text('Clean 1 Item'));
      await tester.pumpAndSettle();
      expect(answer, isTrue);
    },
  );

  testWidgets('confirmation remains usable with larger text on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: TidyTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.8),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const PhotoDeleteConfirmationSheet(count: 12),
              ),
              child: const Text('Open confirmation'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open confirmation'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
