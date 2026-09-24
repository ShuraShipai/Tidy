import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/tidy_action_button.dart';
import '../../../../core/widgets/tidy_glyph.dart';
import '../../../../core/widgets/tidy_orb.dart';
import '../../controllers/onboarding_preview_controller.dart';
import '../../models/permission_subject.dart';
import '../../widgets/onboarding_action_bar.dart';
import '../../widgets/onboarding_info_note.dart';
import '../../widgets/onboarding_message.dart';
import '../../widgets/onboarding_page_frame.dart';

class PermissionHandoffPage extends ConsumerWidget {
  const PermissionHandoffPage({required this.subject, super.key});

  final PermissionSubject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = subject == PermissionSubject.photos;
    final controller = ref.read(onboardingPreviewProvider.notifier);

    void showPermissionState() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/onboarding/${subject.name}');
      }
    }

    return OnboardingPageFrame(
      onBack: showPermissionState,
      body: OnboardingMessage(
        title: photos ? 'Photo access' : 'Contacts access',
        description: photos ? 'Continue with the iOS permission request.' : '',
        glyph: photos ? TidyGlyphName.photo : TidyGlyphName.contacts,
        tone: photos ? TidyOrbTone.pink : TidyOrbTone.green,
        alignment: TextAlign.left,
        child: const OnboardingInfoNote(
          text:
              'UI preview only · choose an access outcome below. This does not request permissions, open Settings or access device data.',
        ),
      ),
      actions: OnboardingActionBar(
        primaryLabel: photos ? 'Simulate Full Access' : 'Simulate Allowed',
        onPrimary: () {
          if (photos) {
            controller.choosePhotos(PhotoAccessPreview.full);
            context.replace('/onboarding/contacts');
          } else {
            controller.chooseContacts(ContactAccessPreview.allowed);
            context.go('/home');
          }
        },
        secondaryLabel: photos ? 'Simulate Limited Access' : 'Simulate Denied',
        secondaryStyle: TidyActionStyle.secondary,
        onSecondary: () {
          if (photos) {
            controller.choosePhotos(PhotoAccessPreview.limited);
          } else {
            controller.chooseContacts(ContactAccessPreview.denied);
          }
          showPermissionState();
        },
        tertiaryLabel: photos ? 'Simulate Denied' : null,
        onTertiary: photos
            ? () {
                controller.choosePhotos(PhotoAccessPreview.denied);
                showPermissionState();
              }
            : null,
      ),
    );
  }
}
