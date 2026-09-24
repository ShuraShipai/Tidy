import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/tidy_sizes.dart';
import '../../../../core/widgets/tidy_glyph.dart';
import '../../../../core/widgets/tidy_orb.dart';
import '../../widgets/onboarding_action_bar.dart';
import '../../widgets/onboarding_message.dart';
import '../../widgets/onboarding_page_frame.dart';
import '../../widgets/privacy_checklist.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) => OnboardingPageFrame(
    onBack: () =>
        context.canPop() ? context.pop() : context.go('/onboarding/welcome'),
    body: const OnboardingMessage(
      title: 'Your stuff stays yours.',
      description: 'Photos and contacts are analyzed on this iPhone.',
      glyph: TidyGlyphName.shield,
      tone: TidyOrbTone.green,
      titleSize: TidySizes.privacyText,
      child: PrivacyChecklist(),
    ),
    actions: OnboardingActionBar(
      primaryLabel: 'Continue',
      onPrimary: () => context.push('/onboarding/photos'),
    ),
  );
}
