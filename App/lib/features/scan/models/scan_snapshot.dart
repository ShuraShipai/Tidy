enum ScanPhase { notScanned, scanning, complete, noAccess, failed }

enum CleanupCategory {
  similarPhotos,
  screenshots,
  largeVideos,
  duplicateContacts,
}

class CategoryFinding {
  const CategoryFinding({
    required this.count,
    this.estimatedBytes,
    this.unknownSizeCount = 0,
  });

  final int count;
  final int? estimatedBytes;
  final int unknownSizeCount;
}

class DeviceStorage {
  const DeviceStorage({
    required this.capacityBytes,
    required this.availableBytes,
  });

  final int capacityBytes;
  final int availableBytes;
}

class ScanSnapshot {
  const ScanSnapshot({
    this.phase = ScanPhase.notScanned,
    this.progress,
    this.currentCategory,
    this.currentStage,
    this.storage,
    this.findings = const {},
    this.lastScanned,
    this.reviewableBytes,
    this.unknownReviewableSizes = 0,
  });

  final ScanPhase phase;
  final double? progress;
  final CleanupCategory? currentCategory;
  final String? currentStage;
  final DeviceStorage? storage;
  final Map<CleanupCategory, CategoryFinding> findings;
  final DateTime? lastScanned;
  final int? reviewableBytes;
  final int unknownReviewableSizes;

  bool get hasFindings => findings.values.any((finding) => finding.count > 0);
}
