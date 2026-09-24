import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/onboarding_controller.dart';
import '../../models/access_status.dart';
import '../../models/permission_subject.dart';
import '../../widgets/onboarding_action_bar.dart';
import '../../widgets/onboarding_page_frame.dart';
import '../../widgets/permission_message.dart';

class PermissionPage extends ConsumerWidget {
  const PermissionPage({required this.subject, super.key});
  final PermissionSubject subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);
    final photos = subject == PermissionSubject.photos;
    final access = state.access(subject);
    final disabled = state.busy || !state.initialized;
    ref.listen(onboardingProvider.select((value) => value.error), (_, error) {
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    });

    Future<void> advance() async {
      if (photos) {
        context.push('/onboarding/contacts');
      } else if (await controller.complete() && context.mounted) {
        context.go('/scan?start=true');
      }
    }

    return PopScope(
      canPop: !state.busy,
      child: OnboardingPageFrame(
        backEnabled: !disabled,
        onBack: () => context.canPop()
            ? context.pop()
            : context.go('/onboarding/welcome'),
        body: PermissionMessage(subject: subject, access: access),
        actions: OnboardingActionBar(
          primaryLabel: switch (access) {
            AccessStatus.denied => 'Open Settings',
            AccessStatus.limited => photos ? 'Manage Photos' : 'Open Settings',
            AccessStatus.granted || AccessStatus.restricted => 'Continue',
            AccessStatus.unsupported => 'Unavailable on this platform',
            _ => photos ? 'Allow Photo Access' : 'Allow Contacts',
          },
          onPrimary: disabled || access == AccessStatus.unsupported
              ? null
              : () async {
                  final action = await controller.primary(subject);
                  if (!context.mounted) return;
                  switch (action) {
                    case PermissionAction.request:
                      context.push('/onboarding/${subject.name}/request');
                    case PermissionAction.advance:
                      await advance();
                    case PermissionAction.stay:
                      break;
                  }
                },
          secondaryLabel:
              access == AccessStatus.restricted ||
                  access == AccessStatus.granted
              ? null
              : access == AccessStatus.limited
              ? (photos
                    ? 'Continue with Selected Photos'
                    : 'Continue with Selected Contacts')
              : photos && access == AccessStatus.denied
              ? 'Continue Without Photos'
              : 'Not Now',
          onSecondary: disabled ? null : advance,
        ),
      ),
    );
  }
}
