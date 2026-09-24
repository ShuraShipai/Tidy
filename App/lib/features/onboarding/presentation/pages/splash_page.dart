import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/tidy_page_background.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/onboarding_action_bar.dart';
import '../../widgets/onboarding_page_frame.dart';
import '../../widgets/splash_identity.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    void route(OnboardingState value) {
      if (!value.initialized) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(value.completed ? '/home' : '/onboarding/welcome');
        }
      });
    }

    ref.listen(onboardingProvider, (_, next) => route(next));
    // Also handles an already initialized provider on a later visit.
    route(state);
    if (state.error != null && !state.initialized) {
      return OnboardingPageFrame(
        body: const SplashIdentity(),
        actions: OnboardingActionBar(
          primaryLabel: 'Retry',
          onPrimary: state.busy
              ? null
              : ref.read(onboardingProvider.notifier).initialize,
          secondaryLabel: state.error,
        ),
      );
    }
    return const Scaffold(
      body: TidyPageBackground(child: SafeArea(child: SplashIdentity())),
    );
  }
}
