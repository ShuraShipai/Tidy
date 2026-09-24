import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tidy/features/onboarding/models/access_status.dart';
import 'package:tidy/features/onboarding/models/permission_subject.dart';
import 'package:tidy/features/onboarding/repositories/onboarding_repository.dart';
import 'package:tidy/features/onboarding/services/onboarding_service.dart';

import 'support/fake_onboarding_service.dart';

class ChannelTestService extends OnboardingService {
  @override
  bool get supported => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(
    () => messenger.setMockMethodCallHandler(OnboardingService.channel, null),
  );

  test(
    'native status values are mapped without treating unknown as granted',
    () async {
      final service = ChannelTestService();
      for (final value in AccessStatus.values) {
        messenger.setMockMethodCallHandler(OnboardingService.channel, (
          call,
        ) async {
          expect(call.method, 'status');
          expect(call.arguments, 'contacts');
          return value.name;
        });
        expect(await service.status(PermissionSubject.contacts), value);
      }
      messenger.setMockMethodCallHandler(
        OnboardingService.channel,
        (_) async => 'futureValue',
      );
      expect(
        await service.status(PermissionSubject.photos),
        AccessStatus.unsupported,
      );
    },
  );

  test('repository does not re-request any determined status', () async {
    final service = FakeOnboardingService();
    final repository = OnboardingRepository(service);
    for (final status in AccessStatus.values.where(
      (s) => s != AccessStatus.notDetermined,
    )) {
      service.photos = status;
      service.contacts = status;
      expect(await repository.request(PermissionSubject.photos), status);
      expect(await repository.request(PermissionSubject.contacts), status);
    }
    expect(service.requests, 0);
  });

  test(
    'limited picker is never opened for full, denied or restricted access',
    () async {
      final service = FakeOnboardingService();
      final repository = OnboardingRepository(service);
      for (final status in AccessStatus.values) {
        service.photos = status;
        await repository.managePhotos();
      }
      expect(service.managers, 1);
    },
  );

  test(
    'failed native Settings launch and storage writes propagate errors',
    () async {
      final service = ChannelTestService();
      messenger.setMockMethodCallHandler(OnboardingService.channel, (
        call,
      ) async {
        if (call.method == 'openSettings') return false;
        throw PlatformException(code: 'storage_write');
      });
      await expectLater(service.openSettings(), throwsStateError);
      await expectLater(
        service.saveCompleted(),
        throwsA(isA<PlatformException>()),
      );
    },
  );

  test(
    'unsupported platforms do not call native authorization or fake completion',
    () async {
      final service = OnboardingService();
      expect(
        await service.status(PermissionSubject.photos),
        AccessStatus.unsupported,
      );
      expect(
        await service.request(PermissionSubject.contacts),
        AccessStatus.unsupported,
      );
      expect(await service.readCompleted(), isFalse);
      await expectLater(service.saveCompleted(), throwsUnsupportedError);
    },
  );
}
