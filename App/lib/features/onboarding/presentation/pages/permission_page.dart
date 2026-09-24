import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/onboarding_preview_controller.dart';
import '../../models/permission_subject.dart';
import '../../widgets/onboarding_action_bar.dart';
import '../../widgets/onboarding_page_frame.dart';
import '../../widgets/permission_message.dart';

class PermissionPage extends ConsumerWidget {
  const PermissionPage({required this.subject, super.key});

  final PermissionSubject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(onboardingPreviewProvider);
    final photos = subject == PermissionSubject.photos;
    final denied = photos
        ? preview.photos == PhotoAccessPreview.denied
        : preview.contacts == ContactAccessPreview.denied;
    final limited = photos && preview.photos == PhotoAccessPreview.limited;

    return OnboardingPageFrame(
      onBack: () =>
          context.canPop() ? context.pop() : context.go('/onboarding/welcome'),
      body: PermissionMessage(subject: subject, preview: preview),
      actions: OnboardingActionBar(
        primaryLabel: denied
            ? 'Open Settings'
            : limited
            ? 'Manage Photos'
            : photos
            ? 'Allow Photo Access'
            : 'Allow Contacts',
        onPrimary: () => context.push('/onboarding/${subject.name}/preview'),
        secondaryLabel: limited
            ? 'Continue with Selected Photos'
            : photos && denied
            ? 'Continue Without Photos'
            : 'Not Now',
        onSecondary: () =>
            photos ? context.push('/onboarding/contacts') : context.go('/home'),
      ),
    );
  }
}
