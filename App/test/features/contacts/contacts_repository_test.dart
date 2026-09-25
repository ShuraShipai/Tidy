import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/features/contacts/models/contact_record.dart';
import 'package:tidy/features/contacts/repositories/contacts_repository.dart';
import 'package:tidy/features/contacts/services/contacts_service.dart';
import 'package:tidy/features/scan/models/scan_state.dart';

ContactRecord contact(
  String id,
  String name, {
  List<String> phones = const [],
  List<String> emails = const [],
}) => ContactRecord(
  id: id,
  givenName: name,
  familyName: '',
  organization: '',
  phones: phones,
  emails: emails,
  version: 'v1',
);

void main() {
  final repository = ContactsRepository(ContactsService());
  test(
    'discovers exact shared phone and email evidence without selecting records',
    () {
      final records = [
        contact('a', 'Rae Harper', phones: ['+1 (415) 555-0100']),
        contact(
          'b',
          'Rae Harper',
          phones: ['14155550100'],
          emails: ['rae@example.com'],
        ),
        contact('c', 'Other Person', emails: ['rae@example.com']),
      ];
      final matches = repository.detect(records);
      expect(
        matches.expand((g) => g.evidence).toSet(),
        containsAll(['Same phone number', 'Same email address']),
      );
      expect(records.map((c) => c.id), ['a', 'b', 'c']);
    },
  );
  test('surfaces close name matches as review evidence', () {
    final matches = repository.detect([
      contact('a', 'Amelia Robertson'),
      contact('b', 'Amelia Robertsson'),
    ]);
    expect(matches, hasLength(1));
    expect(matches.single.evidence, contains('Similar name'));
  });
  test('does not suggest contacts from generic one word names alone', () {
    expect(
      repository.detect([contact('a', 'Alex'), contact('b', 'Alex')]),
      isEmpty,
    );
  });
  test('review pairs stay within shared scan groups and direct evidence', () {
    final records = [
      contact('a', 'Same Name', phones: ['1234567890']),
      contact('b', 'Same Name', phones: ['1234567890'], emails: ['a@b.com']),
      contact('c', 'Another', emails: ['a@b.com']),
      contact('d', 'Same Name', phones: ['1234567890']),
    ];
    final pairs = repository.reviewPairs(records, [
      MatchGroup(['a', 'b', 'c'], 'Shared details'),
    ]);
    expect(pairs.map((pair) => pair.key), ['a|b', 'b|c']);
    expect(pairs.any((pair) => pair.key.contains('d')), isFalse);
  });
  test('one pair with two matching fields appears only once', () {
    final records = [
      contact(
        'a',
        'Rae Harper',
        phones: ['1234567890'],
        emails: ['rae@example.com'],
      ),
      contact(
        'b',
        'Rae H.',
        phones: ['1234567890'],
        emails: ['rae@example.com'],
      ),
    ];
    final pairs = repository.reviewPairs(records, [
      MatchGroup(['a', 'b'], 'Shared phone number'),
      MatchGroup(['a', 'b'], 'Shared email address'),
    ]);
    expect(pairs, hasLength(1));
    expect(pairs.single.evidence, ['Same email address', 'Same phone number']);
  });
}
