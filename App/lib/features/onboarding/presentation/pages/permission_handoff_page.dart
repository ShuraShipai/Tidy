import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/tidy_glyph.dart';
import '../../../../core/widgets/tidy_orb.dart';
import '../../controllers/onboarding_controller.dart';
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
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    final disabled = state.busy || !state.initialized;
    ref.listen(onboardingProvider.select((value) => value.error), (_, error) {
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    });

    void back() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/onboarding/${subject.name}');
      }
    }

    return PopScope(
      canPop: !state.busy,
      child: OnboardingPageFrame(
        backEnabled: !disabled,
        onBack: back,
        body: OnboardingMessage(
          title: photos ? 'Photo access' : 'Contacts access',
          description: photos
              ? 'Continue with the iOS permission request.'
              : '',
          glyph: photos ? TidyGlyphName.photo : TidyGlyphName.contacts,
          tone: photos ? TidyOrbTone.pink : TidyOrbTone.green,
          alignment: TextAlign.left,
          child: OnboardingInfoNote(
            text: photos
                ? 'iOS will ask which photos Tidy can access. You can change access later in Settings.'
                : 'iOS will ask for Contacts access. You can change access later in Settings.',
          ),
        ),
        actions: OnboardingActionBar(
          primaryLabel: state.busy ? 'Please wait…' : 'Continue',
          onPrimary: disabled
              ? null
              : () async {
                  final granted = await controller.request(subject);
                  if (!context.mounted) return;
                  if (ref.read(onboardingProvider).error != null) return;
                  if (granted && photos) {
                    context.replace('/onboarding/contacts');
                  } else if (granted) {
                    if (await controller.complete() && context.mounted) {
                      context.go('/home/scan?start=true');
                    }
                  } else {
                    back();
                  }
                },
          secondaryLabel: 'Not Now',
          onSecondary: disabled
              ? null
              : () async {
                  if (photos) {
                    context.replace('/onboarding/contacts');
                  } else if (await controller.complete() && context.mounted) {
                    context.go('/home/scan?start=true');
                  }
                },
        ),
      ),
    );
  }
}
