import '../../onboarding/models/access_status.dart';

String permissionStatusLabel(AccessStatus status, {bool photos = false}) =>
    switch (status) {
      AccessStatus.notDetermined => 'Not Requested',
      AccessStatus.granted => photos ? 'Full Access' : 'Allowed',
      AccessStatus.limited => 'Limited Access',
      AccessStatus.denied => 'Denied',
      AccessStatus.restricted => 'Restricted',
      AccessStatus.unsupported => 'Unavailable',
    };
