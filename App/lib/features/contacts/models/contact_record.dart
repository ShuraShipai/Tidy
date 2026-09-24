class ContactRecord {
  const ContactRecord({
    required this.id,
    required this.givenName,
    required this.familyName,
    required this.organization,
    required this.phones,
    required this.emails,
    required this.version,
  });
  final String id, givenName, familyName, organization, version;
  final List<String> phones, emails;
  String get name => ('$givenName $familyName').trim().isEmpty
      ? 'Unnamed contact'
      : ('$givenName $familyName').trim();
  String get initials {
    final parts = name.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).take(2);
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  factory ContactRecord.fromMap(Map<Object?, Object?> m) => ContactRecord(
    id: m['id']! as String,
    givenName: m['givenName'] as String? ?? '',
    familyName: m['familyName'] as String? ?? '',
    organization: m['organization'] as String? ?? '',
    phones: List<String>.from(m['phones'] as List? ?? const []),
    emails: List<String>.from(m['emails'] as List? ?? const []),
    version: m['version'] as String? ?? '',
  );
}

class ContactMatchGroup {
  const ContactMatchGroup(this.first, this.second, this.evidence);
  final String first, second;
  final List<String> evidence;
  String get key {
    final ids = [first, second]..sort();
    return ids.join('|');
  }
}
