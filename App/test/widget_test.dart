import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/app.dart';
import 'package:tidy/core/router/app_router.dart';

void main() {
  testWidgets('Tidy starts with its primary navigation', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(appRouterProvider).go('/home');
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TidyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
