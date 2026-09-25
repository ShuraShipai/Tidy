import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/app_version.dart';
import '../models/scan_preferences.dart';

class SettingsService {
  static const MethodChannel _channel = MethodChannel('tidy/settings');

  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<ScanPreferences> readPreferences() async {
    if (!supported) return const ScanPreferences();
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'readPreferences',
    );
    return ScanPreferences.fromMap(result ?? const {});
  }

  Future<ScanPreferences> savePreferences(ScanPreferences preferences) async {
    if (!supported) {
      throw UnsupportedError('Scan preferences require iOS.');
    }
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'savePreferences',
      preferences.toMap(),
    );
    if (result == null) throw StateError('Preferences were not saved.');
    return ScanPreferences.fromMap(result);
  }

  Future<AppVersion> appVersion() async {
    if (!supported) return const AppVersion(version: '', build: '');
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'appVersion',
    );
    return AppVersion(
      version: result?['version'] as String? ?? '',
      build: result?['build'] as String? ?? '',
    );
  }
}
