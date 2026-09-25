enum SimilarPhotoSensitivity { strict, balanced, broad }

extension SimilarPhotoSensitivityLabel on SimilarPhotoSensitivity {
  String get label => switch (this) {
    SimilarPhotoSensitivity.strict => 'Strict',
    SimilarPhotoSensitivity.balanced => 'Balanced',
    SimilarPhotoSensitivity.broad => 'Broad',
  };
}

class ScanPreferences {
  const ScanPreferences({
    this.includeScreenshots = true,
    this.includeLargeVideos = true,
    this.sensitivity = SimilarPhotoSensitivity.balanced,
  });

  final bool includeScreenshots;
  final bool includeLargeVideos;
  final SimilarPhotoSensitivity sensitivity;

  ScanPreferences copyWith({
    bool? includeScreenshots,
    bool? includeLargeVideos,
    SimilarPhotoSensitivity? sensitivity,
  }) => ScanPreferences(
    includeScreenshots: includeScreenshots ?? this.includeScreenshots,
    includeLargeVideos: includeLargeVideos ?? this.includeLargeVideos,
    sensitivity: sensitivity ?? this.sensitivity,
  );

  factory ScanPreferences.fromMap(Map<Object?, Object?> map) => ScanPreferences(
    includeScreenshots: map['includeScreenshots'] as bool? ?? true,
    includeLargeVideos: map['includeLargeVideos'] as bool? ?? true,
    sensitivity: SimilarPhotoSensitivity.values.firstWhere(
      (value) => value.name == map['sensitivity'],
      orElse: () => SimilarPhotoSensitivity.balanced,
    ),
  );

  Map<String, Object> toMap() => {
    'includeScreenshots': includeScreenshots,
    'includeLargeVideos': includeLargeVideos,
    'sensitivity': sensitivity.name,
  };
}
