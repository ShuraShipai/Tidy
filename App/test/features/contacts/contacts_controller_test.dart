import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tidy/features/contacts/controllers/contacts_controller.dart';
import 'package:tidy/features/contacts/models/contact_record.dart';
import 'package:tidy/features/contacts/presentation/pages/contacts_page.dart';
import 'package:tidy/features/contacts/repositories/contacts_repository.dart';
import 'package:tidy/features/contacts/services/contacts_service.dart';
import 'package:tidy/features/contacts/widgets/contact_merge_confirmation_sheet.dart';
import 'package:tidy/features/scan/controllers/scan_controller.dart';
import 'package:tidy/features/scan/models/scan_state.dart';
import 'package:tidy/core/widgets/tidy_action_button.dart';

class _ScanController extends ScanController {
  _ScanController(this.initial);
  final ScanState initial;

  @override
  ScanState build() => initial;

  void publish(ScanState next) => state = next;
}

class _ContactsService extends ContactsService {
  int reads = 0;
  int merges = 0;
  Completer<void>? blockedRead;
  final deletedIds = <String>[];
  final records = <ContactRecord>[
    const ContactRecord(
      id: 'a',
      givenName: 'Rae',
      familyName: 'Harper',
      organization: '',
      phones: ['1234567890'],
      emails: [],
      version: '1',
    ),
    const ContactRecord(
      id: 'b',
      givenName: 'Rae',
      familyName: 'H.',
      organization: '',
      phones: ['1234567890'],
      emails: [],
      version: '1',
    ),
  ];
  @override
  Future<Map<String, Object?>> read(Set<String> ids) async {
    reads++;
    await blockedRead?.future;
    return {
      'status': 'authorized',
      'contacts': records.where((record) => ids.contains(record.id)).toList(),
    };
  }

  @override
  Future<void> delete(List<ContactRecord> selected) async {
    deletedIds.addAll(selected.map((contact) => contact.id));
    records.removeWhere((contact) => deletedIds.contains(contact.id));
  }

  @override
  Future<ContactRecord> merge(
    ContactRecord keeper,
    ContactRecord other, {
    required String givenName,
    required String familyName,
    required String organization,
    required List<String> phones,
    required List<String> emails,
    required bool acknowledgeUnreadableNotes,
  }) async {
    if (!acknowledgeUnreadableNotes) {
      throw StateError('Notes acknowledgement required');
    }
    merges++;
    records.removeWhere((contact) => contact.id == other.id);
    final saved = ContactRecord(
      id: keeper.id,
      givenName: givenName,
      familyName: familyName,
      organization: organization,
      phones: phones,
      emails: emails,
      version: '2',
    );
    records[records.indexWhere((contact) => contact.id == keeper.id)] = saved;
    return saved;
  }
}

ScanState _result({
  required DateTime completedAt,
  List<MatchGroup>? contacts,
  String photosAccess = 'authorized',
  ScanPhase phase = ScanPhase.success,
}) => ScanState(
  phase: phase,
  completedAt: completedAt,
  permissions: {'photos': photosAccess, 'contacts': 'authorized'},
  contacts:
      contacts ??
      [
        MatchGroup(['a', 'b'], 'Shared phone number'),
      ],
  contactCount: 2,
);

void main() {
  test('Contacts reads real details without starting the main scan', () async {
    final service = _ContactsService();
    final completedAt = DateTime(2026, 9, 25);
    final container = ProviderContainer(
      overrides: [
        scanControllerProvider.overrideWith(
          () => _ScanController(_result(completedAt: completedAt)),
        ),
        contactsRepositoryProvider.overrideWithValue(
          ContactsRepository(service),
        ),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(contactsControllerProvider.future);
    expect(state.visibleGroups, hasLength(1));
    expect(state.selected, isEmpty);
    expect(container.read(scanControllerProvider).running, isFalse);
    expect(service.reads, 1);

    (container.read(scanControllerProvider.notifier) as _ScanController)
        .publish(
          _result(
            completedAt: completedAt,
            photosAccess: 'denied',
            phase: ScanPhase.stale,
          ),
        );
    await container.pump();
    expect(
      service.reads,
      1,
      reason: 'Photos-only changes must not reload Contacts',
    );
    expect(
      container.read(contactsControllerProvider).value?.visibleGroups,
      hasLength(1),
    );

    (container.read(scanControllerProvider.notifier) as _ScanController)
        .publish(_result(completedAt: completedAt, contacts: const []));
    await container.pump();
    expect(
      service.reads,
      2,
      reason: 'Contact findings changes refresh Contacts only',
    );
    expect(
      container.read(contactsControllerProvider).value?.visibleGroups,
      isEmpty,
    );
  });

  test('late Contacts refresh preserves an explicit newer selection', () async {
    final service = _ContactsService();
    final container = ProviderContainer(
      overrides: [
        scanControllerProvider.overrideWith(
          () => _ScanController(_result(completedAt: DateTime(2026, 9, 25))),
        ),
        contactsRepositoryProvider.overrideWithValue(
          ContactsRepository(service),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(contactsControllerProvider.future);
    final controller = container.read(contactsControllerProvider.notifier);

    service.blockedRead = Completer<void>();
    final pending = controller.refresh();
    controller.setSelection({'b'});
    service.blockedRead!.complete();
    await pending;

    expect(container.read(contactsControllerProvider).value?.selected, {'b'});
  });

  testWidgets('review-to-delete requires selection before Group 06 handoff', (
    tester,
  ) async {
    final service = _ContactsService();
    final container = ProviderContainer(
      overrides: [
        scanControllerProvider.overrideWith(
          () => _ScanController(_result(completedAt: DateTime(2026, 9, 25))),
        ),
        contactsRepositoryProvider.overrideWithValue(
          ContactsRepository(service),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/contacts',
      routes: [
        GoRoute(path: '/contacts', builder: (_, _) => const ContactsPage()),
        GoRoute(
          path: '/cleanup/review',
          builder: (_, _) =>
              const Scaffold(body: Text('Approved Review Cleanup destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    expect(find.text('Review Contacts'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Delete Contact…'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Delete Contact…'));
    await tester.pumpAndSettle();

    expect(find.text('0 selected'), findsOneWidget);
    expect(
      tester
          .widget<TidyActionButton>(
            find.widgetWithText(TidyActionButton, 'Review Cleanup'),
          )
          .onPressed,
      isNull,
    );
    expect(service.deletedIds, isEmpty);

    await tester.tap(find.text('Select This Contact'));
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.text('Review Cleanup'));
    await tester.pumpAndSettle();
    expect(service.deletedIds, isEmpty);
    expect(find.text('Approved Review Cleanup destination'), findsOneWidget);
    expect(container.read(contactsControllerProvider).value?.selected, {'b'});
  });

  testWidgets('merge needs Notes acknowledgement and a separate confirmation', (
    tester,
  ) async {
    final service = _ContactsService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scanControllerProvider.overrideWith(
            () => _ScanController(_result(completedAt: DateTime(2026, 9, 25))),
          ),
          contactsRepositoryProvider.overrideWithValue(
            ContactsRepository(service),
          ),
        ],
        child: const MaterialApp(home: ContactsPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Preview Merged Contact'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview Merged Contact'));
    await tester.pumpAndSettle();

    expect(service.merges, 0);
    expect(
      tester
          .widget<TidyActionButton>(
            find.widgetWithText(TidyActionButton, 'Merge Contacts'),
          )
          .onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.text('I understand source Notes may not be preserved'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(
      find.text('I understand source Notes may not be preserved'),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Merge Contacts'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Merge Contacts'));
    await tester.pumpAndSettle();
    expect(find.text('Merge these contacts?'), findsOneWidget);
    expect(service.merges, 0);
    await tester.tap(
      find.descendant(
        of: find.byType(ContactMergeConfirmationSheet),
        matching: find.text('Cancel'),
      ),
    );
    await tester.pumpAndSettle();
    expect(service.merges, 0);
    await tester.tap(find.text('Merge Contacts').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(ContactMergeConfirmationSheet),
        matching: find.text('Merge Contacts'),
      ),
    );
    await tester.pumpAndSettle();
    expect(service.merges, 1);
    expect(find.text('All together now.'), findsOneWidget);
  });
}
