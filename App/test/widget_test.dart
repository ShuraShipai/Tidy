import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/app.dart';

void main() {
  testWidgets('Tidy starts with its primary navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: TidyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text('Videos'), findsOneWidget);
    expect(find.text('Contacts'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
