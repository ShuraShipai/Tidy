import 'package:flutter/material.dart';

import '../../../core/widgets/tidy_glyph.dart';
import '../../../core/widgets/tidy_orb.dart';
import '../../../core/widgets/tidy_safety_note.dart';
import '../models/access_status.dart';
import '../models/permission_subject.dart';
import 'onboarding_info_note.dart';
import 'onboarding_message.dart';

class PermissionMessage extends StatelessWidget {
  const PermissionMessage({
    required this.subject,
    required this.access,
    super.key,
  });
  final PermissionSubject subject;
  final AccessStatus access;

  @override
  Widget build(BuildContext context) {
    final photos = subject == PermissionSubject.photos;
    if (access == AccessStatus.restricted ||
        access == AccessStatus.unsupported) {
      return OnboardingMessage(
        title: access == AccessStatus.restricted
            ? '${photos ? 'Photo' : 'Contacts'} Access Is Restricted'
            : '${photos ? 'Photo' : 'Contacts'} Access Is Unavailable',
        description: access == AccessStatus.restricted
            ? 'Access is restricted by iOS. Tidy cannot request or change it. Check Screen Time or device management restrictions.'
            : 'This permission is not supported on this platform. Tidy has not been granted access.',
        glyph: photos ? TidyGlyphName.lock : TidyGlyphName.contacts,
        tone: photos ? TidyOrbTone.pink : TidyOrbTone.green,
        child: const TidySafetyNote(text: 'Nothing is changed or deleted.'),
      );
    }
    if (!photos) {
      final denied = access == AccessStatus.denied;
      final limited = access == AccessStatus.limited;
      return OnboardingMessage(
        title: denied
            ? 'Contacts Access\nNeeded'
            : limited
            ? 'Limited Contacts Access'
            : 'Find duplicate\ncontacts',
        description: denied
            ? 'Allow access in Settings to find possible duplicate contacts.'
            : limited
            ? 'Tidy can access only the contacts you’ve chosen. You can manage access in Settings.'
            : 'Allow Contacts access to find entries that may belong to the same person.',
        glyph: TidyGlyphName.contacts,
        tone: TidyOrbTone.green,
        child: TidySafetyNote(
          text: denied
              ? 'You can still review photos and videos.'
              : 'You’ll review every merge or deletion.',
        ),
      );
    }
    return switch (access) {
      AccessStatus.limited => const OnboardingMessage(
        title: 'Limited Photo Access',
        description:
            'We can only scan the photos you’ve chosen. All cleanup tools work with the accessible items.',
        glyph: TidyGlyphName.photo,
        tone: TidyOrbTone.sky,
        child: OnboardingInfoNote(
          text:
              'Only the photos you choose are accessible. Manage Photos to update your selection.',
        ),
      ),
      AccessStatus.denied => const OnboardingMessage(
        title: 'Photo Access Is Off',
        description: 'Allow Photos access in Settings to scan your library.',
        glyph: TidyGlyphName.lock,
        tone: TidyOrbTone.pink,
        child: TidySafetyNote(text: 'Your library stays on this iPhone.'),
      ),
      _ => const OnboardingMessage(
        title: 'Find photos\ntaking up space',
        description:
            'Allow photo access to find similar photos, screenshots and large videos.',
        glyph: TidyGlyphName.photo,
        tone: TidyOrbTone.pink,
        child: TidySafetyNote(text: 'Your library stays on this iPhone.'),
      ),
    };
  }
}
