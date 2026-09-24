import 'package:flutter/material.dart';

import '../../../core/widgets/tidy_glyph.dart';
import '../../../core/widgets/tidy_orb.dart';
import '../../../core/widgets/tidy_safety_note.dart';
import '../controllers/onboarding_preview_controller.dart';
import '../models/permission_subject.dart';
import 'onboarding_info_note.dart';
import 'onboarding_message.dart';

class PermissionMessage extends StatelessWidget {
  const PermissionMessage({
    required this.subject,
    required this.preview,
    super.key,
  });

  final PermissionSubject subject;
  final OnboardingPreviewState preview;

  @override
  Widget build(BuildContext context) {
    if (subject == PermissionSubject.contacts) {
      final denied = preview.contacts == ContactAccessPreview.denied;
      return OnboardingMessage(
        title: denied ? 'Contacts Access\nNeeded' : 'Find duplicate\ncontacts',
        description: denied
            ? 'Allow access in Settings to find possible duplicate contacts.'
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

    return switch (preview.photos) {
      PhotoAccessPreview.limited => const OnboardingMessage(
        title: 'Limited Photo Access',
        description:
            'We can only scan the photos you’ve chosen. All cleanup tools work with the accessible items.',
        glyph: TidyGlyphName.photo,
        tone: TidyOrbTone.sky,
        child: OnboardingInfoNote(
          text:
              'Limited access preview · only the photos you choose would be accessible. No library is connected.',
        ),
      ),
      PhotoAccessPreview.denied => const OnboardingMessage(
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
