import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  @override
  Future<ContactsState> build() async => _load();
  Future<ContactsState> _load() async {
    final (status, records) = await _repo.read();
    return ContactsState(
      status: status,
      contacts: records,
      groups: _repo.detect(records),
    );
  }

  Future<void> refresh() async {
    final old = state.value;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final fresh = await _load();
      if (old == null) return fresh;
      final ids = fresh.contacts.map((c) => c.id).toSet();
      return fresh.copy(
        ignored: old.ignored,
        selected: old.selected.intersection(ids),
      );
    });
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

  Future<void> merge(
    ContactRecord keeper,
    ContactRecord other, {
    required String givenName,
    required String familyName,
    required String organization,
    required List<String> phones,
    required List<String> emails,
  }) async {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(s.copy(message: null));
    try {
      await _repo.merge(
        keeper,
        other,
        givenName: givenName,
        familyName: familyName,
        organization: organization,
        phones: phones,
        emails: emails,
      );
      await refresh();
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
    state = AsyncData(s.copy(message: null));
    try {
      await _repo.delete(selected);
      await refresh();
    } catch (e) {
      final now = state.value ?? s;
      state = AsyncData(now.copy(selected: s.selected, message: e.toString()));
      rethrow;
    }
  }
}
