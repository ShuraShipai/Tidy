import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_version.dart';
import '../models/scan_preferences.dart';
import '../repositories/settings_repository.dart';
import '../services/settings_service.dart';

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(SettingsService()),
);

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsState>(
      SettingsController.new,
    );

class SettingsState {
  const SettingsState({
    required this.preferences,
    required this.version,
    this.saving = false,
    this.error,
  });

  final ScanPreferences preferences;
  final AppVersion version;
  final bool saving;
  final String? error;

  SettingsState copyWith({
    ScanPreferences? preferences,
    AppVersion? version,
    bool? saving,
    String? error,
  }) => SettingsState(
    preferences: preferences ?? this.preferences,
    version: version ?? this.version,
    saving: saving ?? this.saving,
    error: error,
  );
}

class SettingsController extends AsyncNotifier<SettingsState> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  Future<SettingsState> build() async {
    final values = await Future.wait<Object>([
      _repository.readPreferences(),
      _repository.appVersion(),
    ]);
    return SettingsState(
      preferences: values[0] as ScanPreferences,
      version: values[1] as AppVersion,
    );
  }

  Future<void> setIncludeScreenshots(bool value) =>
      _save(state.requireValue.preferences.copyWith(includeScreenshots: value));

  Future<void> setIncludeLargeVideos(bool value) =>
      _save(state.requireValue.preferences.copyWith(includeLargeVideos: value));

  Future<void> setSensitivity(SimilarPhotoSensitivity value) =>
      _save(state.requireValue.preferences.copyWith(sensitivity: value));

  Future<void> _save(ScanPreferences next) async {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(saving: true, error: null));
    try {
      final saved = await _repository.savePreferences(next);
      if (ref.mounted) {
        state = AsyncData(current.copyWith(preferences: saved));
      }
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncData(current.copyWith(error: error.toString()));
      } else {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }
  }
}
