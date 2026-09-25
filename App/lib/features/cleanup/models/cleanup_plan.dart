import '../../contacts/models/contact_record.dart';
import '../../scan/models/scan_state.dart';

enum CleanupCategory {
  similarPhotos,
  screenshots,
  possiblyBlurry,
  selectedPhotos,
  largeVideos,
  duplicateContacts,
}

extension CleanupCategoryLabel on CleanupCategory {
  String get label => switch (this) {
    CleanupCategory.similarPhotos => 'Similar Photos',
    CleanupCategory.screenshots => 'Screenshots',
    CleanupCategory.possiblyBlurry => 'Possibly Blurry',
    CleanupCategory.selectedPhotos => 'Selected Photos',
    CleanupCategory.largeVideos => 'Large Videos',
    CleanupCategory.duplicateContacts => 'Duplicate Contacts',
  };
}

class CleanupEntry {
  const CleanupEntry({
    required this.id,
    required this.category,
    required this.title,
    required this.detail,
    this.media,
    this.contact,
  });

  final String id;
  final CleanupCategory category;
  final String title;
  final String detail;
  final MediaRecord? media;
  final ContactRecord? contact;
}

class CleanupPlan {
  CleanupPlan({required Iterable<CleanupEntry> entries})
    : entries = List.unmodifiable(entries);

  final List<CleanupEntry> entries;

  List<CleanupEntry> forCategory(CleanupCategory category) => entries
      .where((entry) => entry.category == category)
      .toList(growable: false);

  Set<String> get mediaIds => {
    for (final entry in entries)
      if (entry.media != null) entry.id,
  };
  Set<String> get contactIds => {
    for (final entry in entries)
      if (entry.contact != null) entry.id,
  };
  int get itemCount => entries.length;
  int get knownBytes =>
      entries.fold<int>(0, (sum, entry) => sum + (entry.media?.bytes ?? 0));
  int get unknownMediaSizes => entries
      .where((entry) => entry.media != null && entry.media!.bytes == null)
      .length;
  bool get isEmpty => entries.isEmpty;
}
