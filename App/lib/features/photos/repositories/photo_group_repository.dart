import '../../scan/models/scan_state.dart';
import '../models/photo_group.dart';

class PhotoGroupRepository {
  const PhotoGroupRepository();

  List<MediaRecord> photos(ScanState scan) =>
      List.unmodifiable(_ordered(scan.media.where((item) => !item.video)));

  List<MediaRecord> screenshots(ScanState scan) => scan.media
      .where((item) => !item.video && item.screenshot)
      .toList(growable: false);

  List<MediaRecord> blurryPhotos(ScanState scan) => scan.media
      .where(
        (item) =>
            !item.video && !item.screenshot && item.possiblyBlurry == true,
      )
      .toList(growable: false);

  bool getBlurryAnalysisIncomplete(ScanState scan) => scan.media.any(
    (item) => !item.video && !item.screenshot && item.possiblyBlurry == null,
  );

  List<PhotoGroup> exactDuplicateGroups(ScanState scan) {
    final byHash = <String, List<MediaRecord>>{};
    for (final photo in photos(scan)) {
      final hash = photo.contentHash;
      if (hash != null && hash.isNotEmpty) {
        byHash.putIfAbsent(hash, () => []).add(photo);
      }
    }
    return [
      for (final items in byHash.values)
        if (items.length > 1)
          PhotoGroup(
            items: _ordered(items),
            kind: PhotoGroupKind.exactDuplicate,
          ),
    ]..sort(_newestFirst);
  }

  List<PhotoGroup> similarGroups(ScanState scan) {
    final byId = {for (final item in photos(scan)) item.id: item};
    final exact = exactDuplicateGroups(scan);
    final groups = <PhotoGroup>[];
    final signatures = <String>{};
    for (final match in scan.similar) {
      final items = _ordered([for (final id in match.ids) ?byId[id]]);
      if (items.length < 2) continue;
      final ids = items.map((item) => item.id).toSet();
      PhotoGroup? exactGroup;
      for (final candidate in exact) {
        if (_sameIds(candidate.items, ids)) {
          exactGroup = candidate;
          break;
        }
      }
      final group = PhotoGroup(
        items: items,
        kind: exactGroup == null
            ? PhotoGroupKind.similar
            : PhotoGroupKind.exactDuplicate,
      );
      if (signatures.add(group.selectionKey)) groups.add(group);
    }
    for (final group in exact) {
      final isContainedInVisualGroup = groups.any(
        (candidate) => candidate.items
            .map((item) => item.id)
            .toSet()
            .containsAll(group.items.map((item) => item.id)),
      );
      if (!isContainedInVisualGroup && signatures.add(group.selectionKey)) {
        groups.add(group);
      }
    }
    groups.sort(_newestFirst);
    return List.unmodifiable(groups);
  }

  List<PhotoGroup> groupsForFilter(ScanState scan, SimilarPhotoFilter filter) {
    final groups = similarGroups(scan);
    return switch (filter) {
      SimilarPhotoFilter.all => groups,
      SimilarPhotoFilter.duplicates => exactDuplicateGroups(scan),
      SimilarPhotoFilter.similar =>
        groups
            .where((group) => group.kind == PhotoGroupKind.similar)
            .toList(growable: false),
    };
  }

  List<MediaRecord> uniqueSimilarPhotos(ScanState scan) {
    final ids = <String>{};
    for (final group in similarGroups(scan)) {
      ids.addAll(group.items.map((item) => item.id));
    }
    final byId = {for (final item in photos(scan)) item.id: item};
    return _ordered([for (final id in ids) ?byId[id]]);
  }

  PhotoGroup? groupContaining(
    ScanState scan,
    String assetId, {
    bool exactDuplicateOnly = false,
  }) {
    final groups = exactDuplicateOnly
        ? exactDuplicateGroups(scan)
        : similarGroups(scan);
    for (final group in groups) {
      if (group.items.any((item) => item.id == assetId)) return group;
    }
    return null;
  }

  List<MediaRecord> collection(ScanState scan, PhotoCollectionKind kind) =>
      switch (kind) {
        PhotoCollectionKind.similar => uniqueSimilarPhotos(scan),
        PhotoCollectionKind.screenshots => screenshots(scan),
        PhotoCollectionKind.blurry => blurryPhotos(scan),
      };

  static List<MediaRecord> _ordered(Iterable<MediaRecord> items) {
    final result = items.toList();
    result.sort((left, right) {
      final leftDate = left.createdAt;
      final rightDate = right.createdAt;
      if (leftDate == null && rightDate != null) return 1;
      if (leftDate != null && rightDate == null) return -1;
      final dateOrder = rightDate == null
          ? 0
          : leftDate == null
          ? -1
          : rightDate.compareTo(leftDate);
      return dateOrder == 0 ? left.id.compareTo(right.id) : dateOrder;
    });
    return result;
  }

  static int _newestFirst(PhotoGroup left, PhotoGroup right) {
    final leftDate = left.items.first.createdAt;
    final rightDate = right.items.first.createdAt;
    if (leftDate == null && rightDate == null) {
      return left.anchorId.compareTo(right.anchorId);
    }
    if (leftDate == null) return 1;
    if (rightDate == null) return -1;
    return rightDate.compareTo(leftDate);
  }

  static bool _sameIds(Iterable<MediaRecord> items, Set<String> ids) {
    final itemIds = items.map((item) => item.id).toSet();
    return itemIds.length == ids.length && itemIds.containsAll(ids);
  }
}
