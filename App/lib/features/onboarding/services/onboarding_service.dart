import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/access_status.dart';
import '../models/permission_subject.dart';

/// Authorization and local onboarding storage only; never reads library data.
class OnboardingService {
  static const channel = MethodChannel('tidy/onboarding');

  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<AccessStatus> status(PermissionSubject subject) async {
    if (!supported) return AccessStatus.unsupported;
    return _decode(await channel.invokeMethod<String>('status', subject.name));
  }

  Future<AccessStatus> request(PermissionSubject subject) async {
    if (!supported) return AccessStatus.unsupported;
    return _decode(await channel.invokeMethod<String>('request', subject.name));
  }

  Future<void> managePhotos() => channel.invokeMethod<void>('managePhotos');

  Future<void> openSettings() async {
    if (await channel.invokeMethod<bool>('openSettings') != true) {
      throw StateError('Settings could not be opened');
    }
  }

  Future<bool> readCompleted() async => supported
      ? (await channel.invokeMethod<bool>('readCompleted') ?? false)
      : false;

  Future<void> saveCompleted() async {
    if (!supported) throw UnsupportedError('Onboarding storage requires iOS');
    await channel.invokeMethod<void>('saveCompleted');
  }

  AccessStatus _decode(String? value) => AccessStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => AccessStatus.unsupported,
  );
}
