import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/app.dart';
import 'package:tidy/core/router/app_router.dart';

void main() {
  testWidgets('Photos overview uses unscanned state and opens similar review', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(appRouterProvider).go('/photos');

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TidyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('A place for the moments worth keeping.'), findsOneWidget);
    expect(find.text('Not scanned'), findsNWidgets(3));
    expect(find.text('286 photos'), findsNothing);
    expect(find.text('2.4 GB'), findsNothing);

    await tester.tap(find.text('Similar Photos'));
    await tester.pumpAndSettle();

    expect(find.text('Find similar photos'), findsOneWidget);
    expect(find.text('Scan Library'), findsOneWidget);
    expect(find.text('Select All Except Best'), findsNothing);
  });

  testWidgets('directly opened photo collection back returns to Photos', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(appRouterProvider).go('/photos/screenshots');

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TidyApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back to Photos'));
    await tester.pumpAndSettle();

    expect(find.text('A place for the moments worth keeping.'), findsOneWidget);
  });
}
