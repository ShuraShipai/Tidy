import '../models/app_version.dart';
import '../models/scan_preferences.dart';
import '../services/settings_service.dart';

class SettingsRepository {
  const SettingsRepository(this.service);

  final SettingsService service;

  Future<ScanPreferences> readPreferences() => service.readPreferences();
  Future<ScanPreferences> savePreferences(ScanPreferences value) =>
      service.savePreferences(value);
  Future<AppVersion> appVersion() => service.appVersion();
}
