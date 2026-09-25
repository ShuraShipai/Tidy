class CalendarEventRecord {
  const CalendarEventRecord({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.calendar,
    required this.calendarId,
    required this.recurring,
    required this.kind,
  });

  factory CalendarEventRecord.fromMap(Map<String, Object?> map) =>
      CalendarEventRecord(
        id: map['id']! as String,
        title: map['title']! as String,
        start: DateTime.fromMillisecondsSinceEpoch(
          (map['start']! as num).round(),
        ),
        end: DateTime.fromMillisecondsSinceEpoch((map['end']! as num).round()),
        calendar: map['calendar']! as String,
        calendarId: map['calendarId']! as String,
        recurring: map['recurring']! as bool,
        kind: map['kind']! as String,
      );

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String calendar;
  final String calendarId;
  final bool recurring;
  final String kind;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'start': start.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
    'calendar': calendar,
    'calendarId': calendarId,
    'recurring': recurring,
    'kind': kind,
  };
}

class VaultItemRecord {
  const VaultItemRecord({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.addedAt,
    required this.bytes,
  });

  factory VaultItemRecord.fromMap(Map<String, Object?> map) => VaultItemRecord(
    id: map['id']! as String,
    name: map['name']! as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (map['created']! as num).round(),
    ),
    addedAt: DateTime.fromMillisecondsSinceEpoch(
      (map['addedAt'] as num?)?.round() ?? 0,
    ),
    bytes: (map['bytes']! as num).toInt(),
  );

  static List<VaultItemRecord> newestFirst(Iterable<VaultItemRecord> items) {
    final indexed = items.toList(growable: false).asMap().entries.toList();
    indexed.sort((left, right) {
      final byTimestamp = right.value.createdAt.compareTo(left.value.createdAt);
      return byTimestamp != 0 ? byTimestamp : left.key.compareTo(right.key);
    });
    return indexed.map((entry) => entry.value).toList(growable: false);
  }

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime addedAt;
  final int bytes;
}
