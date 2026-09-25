import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/features/bonus/presentation/pages/calendar_cleanup_page.dart';
import 'package:tidy/features/bonus/services/group_eight_service.dart';

class _CalendarService extends GroupEightService {
  int permissionRequests = 0;
  int deleteRequests = 0;

  @override
  Future<String> calendarStatus() async => 'authorized';

  @override
  Future<Map<String, Object?>> requestCalendar() async {
    permissionRequests++;
    return {'status': 'authorized'};
  }

  @override
  Future<List<Map<String, Object?>>> calendarEvents() async {
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1, 10);
    final start = yesterday.millisecondsSinceEpoch;
    final end = yesterday.add(const Duration(hours: 1)).millisecondsSinceEpoch;
    return [
      {
        'id': 'old-event',
        'title': 'Old test event',
        'start': start,
        'end': end,
        'calendar': 'Test Calendar',
        'calendarId': 'test-calendar',
        'recurring': false,
        'kind': 'old',
      },
      {
        'id': 'recurring-event',
        'title': 'Repeated test event',
        'start': start,
        'end': end,
        'calendar': 'Test Calendar',
        'calendarId': 'test-calendar',
        'recurring': true,
        'kind': 'repeated',
      },
    ];
  }

  @override
  Future<Map<String, Object?>> deleteCalendarEvents(
    List<Map<String, Object?>> events,
  ) async {
    deleteRequests++;
    return {'deleted': events.length, 'failed': <Map<String, Object?>>[]};
  }
}

void main() {
  testWidgets(
    'past events can be filtered and reviewed without a permission prompt or deletion',
    (tester) async {
      final service = _CalendarService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [groupEightServiceProvider.overrideWithValue(service)],
          child: const MaterialApp(home: CalendarCleanupPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Old test event'), findsOneWidget);
      expect(find.text('Repeated test event'), findsNothing);
      expect(service.permissionRequests, 0);
      await tester.tap(find.text('Repeated Events'));
      await tester.pumpAndSettle();
      expect(find.text('Repeated test event'), findsOneWidget);

      await tester.tap(find.text('Old Events'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Old test event'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review Events'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Only this occurrence'), findsOneWidget);
      expect(service.deleteRequests, 0);
      await tester.tap(find.text('Continue to Confirmation'));
      await tester.pumpAndSettle();
      expect(find.text('Delete selected events?'), findsOneWidget);
      expect(service.deleteRequests, 0);
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
      expect(service.deleteRequests, 0);
    },
  );
}
