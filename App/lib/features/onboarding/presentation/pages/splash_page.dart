import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/tidy_page_background.dart';
import '../../controllers/onboarding_controller.dart';
import '../../widgets/onboarding_action_bar.dart';
import '../../widgets/onboarding_page_frame.dart';
import '../../widgets/splash_identity.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  static const _minimumDisplayTime = Duration(milliseconds: 900);
  late final DateTime _shownAt = DateTime.now();
  bool _routing = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    ref.listen(onboardingProvider, (_, next) => _route(next));
    _route(state);
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

  void _route(OnboardingState state) {
    if (!state.initialized || _routing) return;
    _routing = true;
    final elapsed = DateTime.now().difference(_shownAt);
    final remaining = _minimumDisplayTime - elapsed;
    Future<void>.delayed(remaining.isNegative ? Duration.zero : remaining).then(
      (_) {
        if (mounted) {
          context.go(state.completed ? '/home' : '/onboarding/welcome');
        }
      },
    );
  }
}
