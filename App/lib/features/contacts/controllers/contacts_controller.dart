import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../bonus/services/group_eight_service.dart';
import '../../scan/controllers/scan_controller.dart';
import '../../scan/models/scan_state.dart';
import '../models/contact_record.dart';
import '../repositories/contacts_repository.dart';
import '../services/contacts_service.dart';

final contactsRepositoryProvider = Provider(
  (ref) => ContactsRepository(ContactsService()),
);
final contactsControllerProvider =
    AsyncNotifierProvider<ContactsController, ContactsState>(
      ContactsController.new,
    );

class ContactsState {
  const ContactsState({
    this.status = 'loading',
    this.contacts = const [],
    this.groups = const [],
    this.ignored = const {},
    this.selected = const {},
    this.message,
  });
  final String status;
  final List<ContactRecord> contacts;
  final List<ContactMatchGroup> groups;
  final Set<String> ignored, selected;
  final String? message;
  ContactsState copy({
    String? status,
    List<ContactRecord>? contacts,
    List<ContactMatchGroup>? groups,
    Set<String>? ignored,
    Set<String>? selected,
    String? message,
  }) => ContactsState(
    status: status ?? this.status,
    contacts: contacts ?? this.contacts,
    groups: groups ?? this.groups,
    ignored: ignored ?? this.ignored,
    selected: selected ?? this.selected,
    message: message,
  );
  ContactRecord? byId(String id) {
    for (final c in contacts) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<ContactMatchGroup> get visibleGroups =>
      groups.where((g) => !ignored.contains(g.key)).toList();
}

class ContactsController extends AsyncNotifier<ContactsState> {
  ContactsRepository get _repo => ref.read(contactsRepositoryProvider);
  int _refreshGeneration = 0;
  @override
  Future<ContactsState> build() async {
    ref.listen(scanControllerProvider, (previous, next) {
      if (previous == null ||
          previous.completedAt != next.completedAt ||
          previous.permissions['contacts'] != next.permissions['contacts'] ||
          previous.contactCount != next.contactCount ||
          _groupSignature(previous.contacts) !=
              _groupSignature(next.contacts)) {
        refresh();
      }
    });
    return _load();
  }

  String _groupSignature(Iterable<MatchGroup> groups) {
    final signatures = <String>[];
    for (final group in groups) {
      signatures.add(
        '${(group.ids.toList()..sort()).join(',')}:${group.evidence}',
      );
    }
    return (signatures..sort()).join('|');
  }

  Future<ContactsState> _load() async {
    final scan = ref.read(scanControllerProvider);
    if (scan.completedAt == null) {
      return ContactsState(status: scan.running ? 'scanning' : 'notScanned');
    }
    final access = scan.permissions['contacts'];
    if (access != 'authorized' && access != 'limited') {
      return ContactsState(status: access ?? 'notScanned');
    }
    final reviewedIds = {for (final group in scan.contacts) ...group.ids};
    final (status, records) = await _repo.read(reviewedIds);
    final current = ref.read(scanControllerProvider);
    if (current.completedAt != scan.completedAt) {
      return const ContactsState(status: 'notScanned');
    }
    final reviewGroups = _repo.reviewPairs(records, current.contacts);
    return ContactsState(
      status: status,
      contacts: records,
      groups: reviewGroups,
    );
  }

  Future<void> refresh() async {
    final generation = ++_refreshGeneration;
    final updated = await AsyncValue.guard(_load);
    if (!ref.mounted || generation != _refreshGeneration) return;
    final fresh = updated.asData?.value;
    final current = state.value;
    if (fresh == null || current == null) {
      state = updated;
      return;
    }
    final ids = fresh.contacts.map((contact) => contact.id).toSet();
    state = AsyncData(
      fresh.copy(
        ignored: current.ignored,
        selected: current.selected.intersection(ids),
      ),
    );
  }

  void ignore(ContactMatchGroup g) {
    final s = state.value;
    if (s != null) state = AsyncData(s.copy(ignored: {...s.ignored, g.key}));
  }

  void toggle(String id) {
    final s = state.value;
    if (s == null) return;
    final selected = {...s.selected};
    selected.contains(id) ? selected.remove(id) : selected.add(id);
    state = AsyncData(s.copy(selected: selected));
  }

  void clearSelection() {
    final s = state.value;
    if (s != null) state = AsyncData(s.copy(selected: {}));
  }

  void setSelection(Set<String> ids) {
    final s = state.value;
    if (s == null) return;
    final available = s.contacts.map((contact) => contact.id).toSet();
    state = AsyncData(s.copy(selected: ids.intersection(available)));
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
  }) async {
    final s = state.value;
    if (s == null) throw StateError('Contacts are not ready for merging.');
    state = AsyncData(s.copy(message: null));
    try {
      final merged = await _repo.merge(
        keeper,
        other,
        givenName: givenName,
        familyName: familyName,
        organization: organization,
        phones: phones,
        emails: emails,
        acknowledgeUnreadableNotes: acknowledgeUnreadableNotes,
      );
      unawaited(
        ref.read(groupEightServiceProvider).recordCleanupHistorySafely([
          {
            'category': 'Contacts',
            'count': 1,
            'bytes': 0,
            'description': '1 duplicate contact merged',
          },
        ]),
      );
      await refresh();
      return merged;
    } catch (e) {
      final now = state.value ?? s;
      state = AsyncData(now.copy(message: e.toString()));
      rethrow;
    }
  }

  Future<void> deleteSelected() async {
    final s = state.value;
    if (s == null || s.selected.isEmpty) return;
    final selected = s.contacts
        .where((c) => s.selected.contains(c.id))
        .toList();
    await deleteRecords(selected);
  }

  Future<void> deleteRecords(List<ContactRecord> records) async {
    if (records.isEmpty) return;
    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copy(message: null));
    try {
      await _repo.delete(records);
      unawaited(
        ref.read(groupEightServiceProvider).recordCleanupHistorySafely([
          {
            'category': 'Contacts',
            'count': records.length,
            'bytes': 0,
            'description': '${records.length} contacts removed',
          },
        ]),
      );
      await refresh();
    } catch (e) {
      final now = state.value ?? s;
      state = AsyncData(now.copy(selected: s.selected, message: e.toString()));
      rethrow;
    }
  }
}
