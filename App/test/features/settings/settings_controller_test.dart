import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/features/settings/controllers/settings_controller.dart';
import 'package:tidy/features/settings/models/app_version.dart';
import 'package:tidy/features/settings/models/scan_preferences.dart';
import 'package:tidy/features/settings/repositories/settings_repository.dart';
import 'package:tidy/features/settings/services/settings_service.dart';

class _SettingsService extends SettingsService {
  ScanPreferences saved = const ScanPreferences();

  @override
  Future<ScanPreferences> readPreferences() async => saved;

  @override
  Future<ScanPreferences> savePreferences(ScanPreferences value) async {
    saved = value;
    return saved;
  }

  @override
  Future<AppVersion> appVersion() async =>
      const AppVersion(version: '1.0', build: '1');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('settings reads and persists native-backed scan preferences', () async {
    final service = _SettingsService();
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          SettingsRepository(service),
        ),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(settingsControllerProvider.future);
    expect(initial.preferences.includeScreenshots, isTrue);
    expect(initial.version.label, 'Version 1.0 (1)');

    await container
        .read(settingsControllerProvider.notifier)
        .setSensitivity(SimilarPhotoSensitivity.strict);

    expect(
      container
          .read(settingsControllerProvider)
          .requireValue
          .preferences
          .sensitivity,
      SimilarPhotoSensitivity.strict,
    );
    expect(service.saved.sensitivity, SimilarPhotoSensitivity.strict);
  });
}
