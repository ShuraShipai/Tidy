import '../../scan/models/scan_state.dart';
import '../models/contact_record.dart';
import '../services/contacts_service.dart';

class ContactsRepository {
  const ContactsRepository(this.service);
  final ContactsService service;
  Future<(String, List<ContactRecord>)> read(Set<String> ids) async {
    final result = await service.read(ids);
    return (
      result['status']! as String,
      result['contacts']! as List<ContactRecord>,
    );
  }

  // The completed main scan owns discovery. Fetching contact details for
  // review only resolves pairs inside those already discovered groups.
  List<ContactMatchGroup> reviewPairs(
    List<ContactRecord> contacts,
    Iterable<MatchGroup> scanGroups,
  ) {
    final byId = {for (final contact in contacts) contact.id: contact};
    final evidenceByPair = <String, Set<String>>{};
    for (final group in scanGroups) {
      final members = [for (final id in group.ids) ?byId[id]]
        ..sort((a, b) => a.id.compareTo(b.id));
      for (var i = 0; i < members.length; i++) {
        for (var j = i + 1; j < members.length; j++) {
          final left = members[i], right = members[j];
          final leftPhones = left.phones
              .map((value) => value.replaceAll(RegExp(r'\D'), ''))
              .where((value) => value.length >= 7)
              .toSet();
          final rightPhones = right.phones
              .map((value) => value.replaceAll(RegExp(r'\D'), ''))
              .where((value) => value.length >= 7)
              .toSet();
          final leftEmails = left.emails
              .map((value) => value.trim().toLowerCase())
              .where((value) => value.contains('@'))
              .toSet();
          final rightEmails = right.emails
              .map((value) => value.trim().toLowerCase())
              .where((value) => value.contains('@'))
              .toSet();
          final evidence = <String>[
            if (leftPhones.intersection(rightPhones).isNotEmpty)
              'Same phone number',
            if (leftEmails.intersection(rightEmails).isNotEmpty)
              'Same email address',
            if (_namesSimilar(left, right)) 'Similar name',
          ];
          if (evidence.isNotEmpty) {
            evidenceByPair
                .putIfAbsent('${left.id}|${right.id}', () => <String>{})
                .addAll(evidence);
          }
        }
      }
    }
    return List.unmodifiable([
      for (final pair in evidenceByPair.entries)
        ContactMatchGroup(
          pair.key.split('|').first,
          pair.key.split('|').last,
          pair.value.toList()..sort(),
        ),
    ]);
  }

  List<ContactMatchGroup> detect(List<ContactRecord> contacts) {
    final parent = List<int>.generate(contacts.length, (i) => i);
    int root(int i) {
      while (parent[i] != i) {
        parent[i] = parent[parent[i]];
        i = parent[i];
      }
      return i;
    }

    final edges = <String, Set<int>>{};
    for (var i = 0; i < contacts.length; i++) {
      final c = contacts[i];
      for (final p in c.phones) {
        final n = p.replaceAll(RegExp(r'\D'), '');
        if (n.length >= 7) edges.putIfAbsent('p:$n', () => {}).add(i);
      }
      for (final e in c.emails) {
        final n = e.trim().toLowerCase();
        if (n.contains('@')) edges.putIfAbsent('e:$n', () => {}).add(i);
      }
    }
    final reasons = <String, Set<String>>{};
    for (final entry in edges.entries) {
      final ids = entry.value.toList();
      for (var x = 0; x < ids.length; x++) {
        for (var y = x + 1; y < ids.length; y++) {
          final a = ids[x], b = ids[y];
          parent[root(a)] = root(b);
          final k = [contacts[a].id, contacts[b].id]..sort();
          reasons
              .putIfAbsent(k.join('|'), () => {})
              .add(
                entry.key.startsWith('p:')
                    ? 'Same phone number'
                    : 'Same email address',
              );
        }
      }
    }
    // A close name match is useful evidence, but remains advisory until the
    // person reviews both records. Require substantial names to avoid matching
    // generic initials or one-word entries.
    for (var a = 0; a < contacts.length; a++) {
      for (var b = a + 1; b < contacts.length; b++) {
        if (_namesSimilar(contacts[a], contacts[b])) {
          parent[root(a)] = root(b);
          final pair = [contacts[a].id, contacts[b].id]..sort();
          reasons.putIfAbsent(pair.join('|'), () => {}).add('Similar name');
        }
      }
    }
    final groups = <String, List<int>>{};
    for (var i = 0; i < contacts.length; i++) {
      final r = root(i);
      groups.putIfAbsent('$r', () => []).add(i);
    }
    final result = <ContactMatchGroup>[];
    for (final indices in groups.values.where((g) => g.length > 1)) {
      // Present pairs individually. Transitive groups are not merged wholesale.
      for (var x = 0; x < indices.length; x++) {
        for (var y = x + 1; y < indices.length; y++) {
          final a = contacts[indices[x]],
              b = contacts[indices[y]],
              k = [a.id, b.id]..sort();
          final ev = reasons[k.join('|')] ?? <String>{};
          if (ev.isNotEmpty) {
            result.add(ContactMatchGroup(a.id, b.id, ev.toList()));
          }
        }
      }
    }
    return result;
  }

  String _name(ContactRecord contact) =>
      contact.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  bool _namesSimilar(ContactRecord a, ContactRecord b) {
    final left = _name(a), right = _name(b);
    if (left.length < 7 || right.length < 7) return false;
    if (left.substring(0, 2) != right.substring(0, 2)) return false;
    final longest = left.length > right.length ? left.length : right.length;
    if ((left.length - right.length).abs() > longest * .18) return false;
    return _similarity(left, right) >= .82;
  }

  double _similarity(String a, String b) {
    final previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      var diagonal = previous[0];
      previous[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final above = previous[j];
        previous[j] = (a[i - 1] == b[j - 1])
            ? diagonal
            : 1 +
                  [
                    previous[j - 1],
                    above,
                    diagonal,
                  ].reduce((x, y) => x < y ? x : y);
        diagonal = above;
      }
    }
    return 1 - previous[b.length] / (a.length > b.length ? a.length : b.length);
  }

  Future<ContactRecord> merge(
    ContactRecord keeper,
    ContactRecord other, {
    required String givenName,
    required String familyName,
    required String organization,
    required List<String> phones,
    required List<String> emails,
    required bool acknowledgeUnreadableNotes,
  }) => service.merge(
    keeper,
    other,
    givenName: givenName,
    familyName: familyName,
    organization: organization,
    phones: phones,
    emails: emails,
    acknowledgeUnreadableNotes: acknowledgeUnreadableNotes,
  );
  Future<void> delete(List<ContactRecord> records) => service.delete(records);
}
