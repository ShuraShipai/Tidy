import '../../scan/models/scan_state.dart';

enum PhotoGroupKind { similar, exactDuplicate }

enum PhotoCollectionKind { similar, screenshots, blurry }

enum SimilarPhotoFilter { all, duplicates, similar }

class PhotoGroup {
  PhotoGroup({required List<MediaRecord> items, required this.kind})
    : items = List.unmodifiable(items);

  final List<MediaRecord> items;
  final PhotoGroupKind kind;

  String get anchorId => items.first.id;
  String get selectionKey =>
      (items.map((item) => item.id).toList()..sort()).join('|');
  int get knownBytes => items.fold(0, (sum, item) => sum + (item.bytes ?? 0));
  int get unknownSizeCount => items.where((item) => item.bytes == null).length;

  MediaRecord get suggestedKeeper {
    return items.reduce((current, next) {
      final currentPixels = current.width * current.height;
      final nextPixels = next.width * next.height;
      if (nextPixels > currentPixels) return next;
      if (nextPixels == currentPixels) {
        if (current.createdAt == null && next.createdAt != null) return next;
        if (current.createdAt != null &&
            next.createdAt != null &&
            next.createdAt!.isBefore(current.createdAt!)) {
          return next;
        }
      }
      return current;
    });
  }
}
