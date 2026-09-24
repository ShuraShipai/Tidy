import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/access_status.dart';
import '../models/permission_subject.dart';
import '../services/onboarding_service.dart';

final onboardingServiceProvider = Provider((ref) => OnboardingService());
final onboardingRepositoryProvider = Provider(
  (ref) => OnboardingRepository(ref.watch(onboardingServiceProvider)),
);

class OnboardingRepository {
  OnboardingRepository(this._service);
  final OnboardingService _service;

  Future<AccessStatus> status(PermissionSubject subject) =>
      _service.status(subject);
  Future<AccessStatus> request(PermissionSubject subject) async {
    final current = await status(subject);
    // iOS must not be repeatedly prompted after a decision or restriction.
    if (current != AccessStatus.notDetermined) return current;
    await _service.request(subject);
    return status(subject);
  }

  Future<void> managePhotos() async {
    if (await status(PermissionSubject.photos) == AccessStatus.limited) {
      await _service.managePhotos();
    }
  }

  Future<void> openSettings() => _service.openSettings();
  Future<bool> readCompleted() => _service.readCompleted();
  Future<void> complete() => _service.saveCompleted();
}
