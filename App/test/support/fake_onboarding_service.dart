import 'dart:async';

import 'package:tidy/features/onboarding/models/access_status.dart';
import 'package:tidy/features/onboarding/models/permission_subject.dart';
import 'package:tidy/features/onboarding/services/onboarding_service.dart';

/// Test double only. Production always uses the native channel.
class FakeOnboardingService extends OnboardingService {
  AccessStatus photos = AccessStatus.notDetermined;
  AccessStatus contacts = AccessStatus.notDetermined;
  AccessStatus next = AccessStatus.granted;
  bool completed = false;
  bool failRead = false;
  bool failSave = false;
  bool failSettings = false;
  bool failRequest = false;
  int requests = 0;
  int settings = 0;
  int managers = 0;
  int saves = 0;
  Completer<void>? pending;

  @override
  Future<AccessStatus> status(PermissionSubject subject) async =>
      subject == PermissionSubject.photos ? photos : contacts;

  @override
  Future<AccessStatus> request(PermissionSubject subject) async {
    requests++;
    await pending?.future;
    if (failRequest) throw StateError('request');
    if (subject == PermissionSubject.photos) {
      photos = next;
    } else {
      contacts = next;
    }
    return next;
  }

  @override
  Future<void> openSettings() async {
    settings++;
    if (failSettings) throw StateError('settings');
  }

  @override
  Future<void> managePhotos() async {
    managers++;
  }

  @override
  Future<bool> readCompleted() async {
    if (failRead) throw StateError('read');
    return completed;
  }

  @override
  Future<void> saveCompleted() async {
    saves++;
    if (failSave) throw StateError('save');
    completed = true;
  }
}
